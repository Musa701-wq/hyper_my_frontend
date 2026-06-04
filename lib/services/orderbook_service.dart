import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/orderbook_model.dart';

/// Live order book for any symbol.
///
/// Worker main WS (`ws://4001`) mostly broadcasts BTC `orderbook_update`.
/// For other coins we poll REST (works for ETH, SOL, …) + optional per-symbol WS.
class OrderBookService {
  final String symbol;
  final String? dex;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _pollTimer;
  bool _disposed = false;

  static const _pollInterval = Duration(milliseconds: 1500);

  OrderBookService({required this.symbol, this.dex});

  String get _baseUrl => dotenv.env['BASE_URL'] ?? 'https://coingecko.renderonnodes.com';
  String get _wsBase => dotenv.env['WS_URL'] ?? 'wss://coingecko.renderonnodes.com/ws/';

  /// Starts live updates: REST poll + symbol-scoped WebSocket.
  Future<void> startLive({
    required void Function(OrderBookSnapshot snapshot) onUpdate,
    void Function(Object error)? onError,
  }) async {
    final initial = await fetchSnapshot(symbol, dex: dex, maxAttempts: 3);
    if (_disposed) return;
    if (initial != null) onUpdate(initial);

    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      if (_disposed) return;
      try {
        final snap = await fetchSnapshot(symbol, dex: dex, maxAttempts: 1);
        if (!_disposed && snap != null) onUpdate(snap);
      } catch (e) {
        debugPrint('OrderBook poll error $symbol: $e');
      }
    });

    // Connect WS for both hyperliquid and DEX coins
    unawaited(_connectSymbolWebSocket(onUpdate, onError));
  }

  Future<void> _connectSymbolWebSocket(
    void Function(OrderBookSnapshot snapshot) onUpdate,
    void Function(Object error)? onError,
  ) async {
    final effectiveDex = (dex != null && dex!.isNotEmpty && dex!.toLowerCase() != 'hyperliquid')
        ? dex
        : null;

    final query = effectiveDex != null ? '?dex=${Uri.encodeComponent(effectiveDex)}' : '';
    final String cleanBase = _wsBase.trim().replaceAll(RegExp(r'/+$'), '');
    
    // For symbols like "xyz:XYZ100", the backend usually expects "XYZ100"
    final bareSymbol = symbol.contains(':') ? symbol.split(':').last : symbol;
    
    final wsUrl = '$cleanBase/orderbook/${Uri.encodeComponent(bareSymbol.toUpperCase())}$query';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      await _channel!.ready;

      _subscription = _channel!.stream.listen(
        (message) => _handleMessage(message, onUpdate),
        onError: (e) => onError?.call(e),
      );
      debugPrint('OrderBook WS connected: $wsUrl');
    } catch (e) {
      debugPrint('OrderBook WS failed ($symbol): $e');
    }
  }

  /// Fresh snapshot from REST.
  static Future<OrderBookSnapshot?> fetchSnapshot(
    String symbol, {
    String? dex,
    int levels = 8,
    int maxAttempts = 2,
  }) async {
    final query = <String, String>{'levels': levels.toString()};
    if (dex != null && dex.isNotEmpty) query['dex'] = dex;

    final String baseUrl = dotenv.env['BASE_URL'] ?? 'https://coingecko.renderonnodes.com';
    final String cleanBase = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final bareSymbol = symbol.contains(':') ? symbol.split(':').last : symbol;

    final uri = Uri.parse('$cleanBase/api/orderbook/$bareSymbol').replace(queryParameters: query);

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final response = await http.get(uri);

        if (response.statusCode == 202) {
          if (maxAttempts > 1) {
            await Future<void>.delayed(const Duration(milliseconds: 800));
            continue;
          }
          return null;
        }

        if (response.statusCode != 200) return null;

        final decoded = json.decode(response.body);
        final data = _extractData(decoded);
        if (data == null) return null;

        final snapshot = OrderBookSnapshot.fromJson(data);
        if (snapshot.bids.isEmpty && snapshot.asks.isEmpty) return null;
        return snapshot;
      } catch (e) {
        debugPrint('OrderBook REST $symbol: $e');
        return null;
      }
    }
    return null;
  }

  static Map<String, dynamic>? _extractData(dynamic decoded) {
    if (decoded is! Map<String, dynamic>) return null;
    if (decoded['success'] == true && decoded['data'] is Map) {
      return Map<String, dynamic>.from(decoded['data'] as Map);
    }
    if (decoded.containsKey('bids') || decoded.containsKey('asks')) {
      return decoded;
    }
    return null;
  }

  void _handleMessage(dynamic message, void Function(OrderBookSnapshot) onUpdate) {
    try {
      final decoded = json.decode(message as String);
      if (decoded is! Map<String, dynamic>) return;

      Map<String, dynamic>? payload;
      if (decoded['type'] == 'orderbook_update' && decoded['data'] is Map) {
        payload = Map<String, dynamic>.from(decoded['data'] as Map);
      } else if (decoded.containsKey('bids')) {
        payload = decoded;
      }
      if (payload == null) return;

      final snapshot = OrderBookSnapshot.fromJson(payload);
      if (!_matchesSymbol(symbol, snapshot.symbol)) return;
      if (snapshot.bids.isEmpty && snapshot.asks.isEmpty) return;

      onUpdate(snapshot);
    } catch (e) {
      debugPrint('OrderBook WS parse: $e');
    }
  }

  static bool _matchesSymbol(String subscribed, String incoming) {
    String coin(String s) {
      final upper = s.toUpperCase();
      if (upper.contains(':')) return upper.split(':').last;
      if (upper.contains('-')) return upper.split('-').first;
      return upper;
    }

    return subscribed.toUpperCase() == incoming.toUpperCase() ||
        coin(subscribed) == coin(incoming);
  }

  Future<void> dispose() async {
    _disposed = true;
    _pollTimer?.cancel();
    _pollTimer = null;
    await _subscription?.cancel();
    await _channel?.sink.close();
    _subscription = null;
    _channel = null;
  }
}

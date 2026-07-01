import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../utils/app_config.dart';
import '../models/orderbook_model.dart';

/// Live order book for any symbol.
///
/// Worker main WS (`ws://4001`) mostly broadcasts BTC `orderbook_update`.
/// For other coins we poll REST (works for ETH, SOL, …) + optional per-symbol WS.
class OrderBookService {
  final String symbol;
  final String? dex;
  final bool isHip4;
  final String? hip4MarketId;
  final int? hip4Side;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _pollTimer;
  bool _disposed = false;

  static const _pollInterval = Duration(milliseconds: 1500);

  OrderBookService({
    required this.symbol,
    this.dex,
    this.isHip4 = false,
    this.hip4MarketId,
    this.hip4Side,
  });

  String get _wsBase {
    if (isHip4) {
      final detailBase = AppConfig.hip4DetailBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
      if (detailBase.startsWith('https://')) {
        return detailBase.replaceFirst('https://', 'wss://');
      } else if (detailBase.startsWith('http://')) {
        return detailBase.replaceFirst('http://', 'ws://');
      }
      return detailBase;
    }
    return AppConfig.wsUrl;
  }

  /// Starts live updates: REST poll + symbol-scoped WebSocket.
  Future<void> startLive({
    required void Function(OrderBookSnapshot snapshot) onUpdate,
    void Function(Object error)? onError,
  }) async {
    final initial = await fetchSnapshot(
      symbol,
      dex: dex,
      maxAttempts: 3,
      isHip4: isHip4,
      hip4MarketId: hip4MarketId,
      hip4Side: hip4Side,
    );
    if (_disposed) return;
    if (initial != null) onUpdate(initial);

    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      if (_disposed) return;
      try {
        final snap = await fetchSnapshot(
          symbol,
          dex: dex,
          maxAttempts: 1,
          isHip4: isHip4,
          hip4MarketId: hip4MarketId,
          hip4Side: hip4Side,
        );
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
        (message) {
          debugPrint('[OB-WS] RAW >> ${message.toString().length > 300 ? message.toString().substring(0, 300) + "..." : message}');
          _handleMessage(message, onUpdate);
        },
        onError: (e) {
          debugPrint('[OB-WS] ERROR >> $e');
          onError?.call(e);
        },
        onDone: () => debugPrint('[OB-WS] CLOSED for $symbol'),
      );
      debugPrint('[OB-WS] Connected: $wsUrl');
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
    bool isHip4 = false,
    String? hip4MarketId,
    int? hip4Side,
  }) async {
    final query = <String, String>{'levels': levels.toString()};
    if (dex != null && dex.isNotEmpty) query['dex'] = dex;

    final String baseUrl = isHip4 ? AppConfig.hip4DetailBaseUrl : AppConfig.baseUrl;
    final String cleanBase = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final bareSymbol = symbol.contains(':') ? symbol.split(':').last : symbol;

    Uri uri;
    if (isHip4 && hip4MarketId != null) {
      if (hip4Side != null) {
        query['side'] = hip4Side.toString();
      }
      query['coin'] = symbol;
      uri = Uri.parse('$cleanBase/api/hip4/orderbook/$hip4MarketId').replace(queryParameters: query);
    } else {
      uri = Uri.parse('$cleanBase/api/orderbook/$bareSymbol').replace(queryParameters: query);
    }

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
    if (decoded is String) {
      try {
        decoded = json.decode(decoded);
      } catch (_) {}
    }
    if (decoded is! Map) return null;
    final map = Map<String, dynamic>.from(decoded);
    if (map['success'] == true) {
      final rawData = map['data'];
      if (rawData is Map) {
        return Map<String, dynamic>.from(rawData);
      } else if (rawData is String) {
        try {
          final parsed = json.decode(rawData);
          if (parsed is Map) {
            return Map<String, dynamic>.from(parsed);
          }
        } catch (_) {}
      }
    }
    if (map.containsKey('bids') || map.containsKey('asks')) {
      return map;
    }
    return null;
  }

  void _handleMessage(dynamic message, void Function(OrderBookSnapshot) onUpdate) {
    try {
      var decoded = json.decode(message as String);
      if (decoded is String) {
        try { decoded = json.decode(decoded); } catch (_) {}
      }
      if (decoded is! Map) {
        debugPrint('[OB-WS] Non-map message, skipping');
        return;
      }

      final map = Map<String, dynamic>.from(decoded);
      final msgType = map['type'] ?? map['channel'] ?? '(no type)';
      debugPrint('[OB-WS] MSG type=$msgType keys=${map.keys.toList()}');

      Map<String, dynamic>? payload;
      if (map['type'] == 'orderbook_update' || map['type'] == 'orderbook_snapshot') {
        final rawData = map['data'];
        debugPrint('[OB-WS] data runtimeType=${rawData.runtimeType}');
        if (rawData is Map) {
          payload = Map<String, dynamic>.from(rawData);
        } else if (rawData is String) {
          try {
            final parsed = json.decode(rawData);
            if (parsed is Map) payload = Map<String, dynamic>.from(parsed);
          } catch (_) {}
        }
      } else if (map.containsKey('bids')) {
        payload = map;
      }
      if (payload == null) {
        debugPrint('[OB-WS] No payload extracted for type=$msgType, dropping');
        return;
      }
      debugPrint('[OB-WS] Parsed payload bids=${payload["bids"]?.length ?? 0} asks=${payload["asks"]?.length ?? 0}');

      final snapshot = OrderBookSnapshot.fromJson(payload);
      if (!_matchesSymbol(symbol, snapshot.symbol, isHip4: isHip4)) return;
      if (snapshot.bids.isEmpty && snapshot.asks.isEmpty) return;

      onUpdate(snapshot);
    } catch (e) {
      debugPrint('[OB-WS] PARSE ERROR: $e');
    }
  }

  static bool _matchesSymbol(String subscribed, String incoming, {bool isHip4 = false}) {
    if (isHip4) {
      return subscribed.trim().toUpperCase() == incoming.trim().toUpperCase();
    }
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

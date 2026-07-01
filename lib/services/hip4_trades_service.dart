import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/trade_model.dart';
import '../utils/app_config.dart';

/// Handles recent trades for a HIP-4 prediction market outcome coin.
///
/// Strategy:
///  1. REST poll `/api/hip4/trades/:id?side=:side&limit=50` every [pollInterval].
///  2. WebSocket `ws://.../trades/:coin` for real-time pushes.
class Hip4TradesService {
  final String marketId;
  final int side; // 0 = YES, 1 = NO
  final String coinSymbol; // e.g. "#6730"

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pollTimer;
  bool _disposed = false;

  static const _pollInterval = Duration(seconds: 8);

  Hip4TradesService({
    required this.marketId,
    required this.side,
    required this.coinSymbol,
  });

  String get _httpBase =>
      AppConfig.hip4DetailBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');

  String get _wsBase {
    final base = _httpBase;
    if (base.startsWith('https://')) return base.replaceFirst('https://', 'wss://');
    if (base.startsWith('http://')) return base.replaceFirst('http://', 'ws://');
    return base;
  }

  Future<void> start({
    required void Function(List<Trade> trades) onUpdate,
    void Function(Object error)? onError,
  }) async {
    // Initial REST fetch
    final initial = await _fetchRest();
    if (!_disposed && initial.isNotEmpty) onUpdate(initial);

    // Poll REST periodically
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      if (_disposed) return;
      final trades = await _fetchRest();
      if (!_disposed && trades.isNotEmpty) onUpdate(trades);
    });

    // Connect WebSocket for live pushes
    _connectWs(onUpdate, onError);
  }

  Future<List<Trade>> _fetchRest() async {
    try {
      final uri = Uri.parse('$_httpBase/api/hip4/trades/$marketId')
          .replace(queryParameters: {
        'side': side.toString(),
        'coin': coinSymbol,
        'limit': '50',
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return [];
      final decoded = json.decode(res.body);
      if (decoded is Map && decoded['success'] == true) {
        final List<dynamic> rawList = decoded['data'] as List? ?? [];
        return rawList
            .whereType<Map>()
            .map((j) => Trade.fromJson(Map<String, dynamic>.from(j)))
            .toList();
      }
    } catch (e) {
      debugPrint('Hip4TradesService REST error: $e');
    }
    return [];
  }

  void _connectWs(
    void Function(List<Trade>) onUpdate,
    void Function(Object)? onError,
  ) {
    try {
      final encoded = Uri.encodeComponent(coinSymbol);
      final wsUrl = '$_wsBase/trades/$encoded';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _subscription = _channel!.stream.listen(
        (message) {
          if (_disposed) return;
          try {
            var decoded = json.decode(message as String);
            if (decoded is String) decoded = json.decode(decoded);
            if (decoded is! Map) return;
            final map = Map<String, dynamic>.from(decoded);
            final type = map['type'] ?? map['channel'];
            final dynamic rawData = map['data'];
            if (rawData == null) return;

            final List<Trade> trades = [];
            if (rawData is List) {
              trades.addAll(rawData
                  .whereType<Map>()
                  .map((j) => Trade.fromJson(Map<String, dynamic>.from(j))));
            } else if (rawData is Map) {
              trades.add(Trade.fromJson(Map<String, dynamic>.from(rawData)));
            }
            if (trades.isEmpty) return;

            if (type == 'trades_snapshot' || type == 'trades_update' || type == 'trades') {
              onUpdate(trades);
            }
          } catch (e) {
            debugPrint('Hip4TradesService WS parse error: $e');
          }
        },
        onError: (e) => onError?.call(e),
      );
      debugPrint('Hip4TradesService WS connected: $wsUrl');
    } catch (e) {
      debugPrint('Hip4TradesService WS failed: $e');
    }
  }

  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
  }
}

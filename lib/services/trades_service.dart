import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/trade_model.dart';

/// Service to handle real-time trades via WebSockets + REST Snapshots
class TradesService {
  final String symbol;
  final String? dex;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _disposed = false;

  TradesService({required this.symbol, this.dex});

  static String get _baseUrl => dotenv.env['BASE_URL'] ?? 'https://coingecko.renderonnodes.com';
  static String get _wsBase => dotenv.env['WS_URL'] ?? 'wss://coingecko.renderonnodes.com/ws/';

  /// Starts the trade stream (Pure WebSocket Flow).
  /// The backend pushes 'trades_snapshot' immediately on connection.
  Future<void> start({
    required void Function(List<Trade> snapshot) onSnapshot,
    required void Function(List<Trade> updates) onUpdates,
    void Function(Object error)? onError,
  }) async {
    await _connectWebSocket(onSnapshot, onUpdates, onError);
  }

  Future<void> _connectWebSocket(
    void Function(List<Trade> snapshot) onSnapshot,
    void Function(List<Trade> updates) onUpdates,
    void Function(Object error)? onError,
  ) async {
    // Correct DEX logic: one of (xyz, flx, vntl, hyna, km, cash, para)
    // If dex is "hyperliquid", treat it as null (perp/spot).
    final effectiveDex = (dex != null && 
                          dex!.isNotEmpty && 
                          dex!.toLowerCase() != 'hyperliquid' && 
                          dex!.toLowerCase() != 'null')
        ? dex
        : null;

    final query = effectiveDex != null ? '?dex=${Uri.encodeComponent(effectiveDex)}' : '';
    final String normalizedBase = _wsBase.endsWith('/') 
        ? _wsBase.substring(0, _wsBase.length - 1) 
        : _wsBase;
    
    final wsUrl = '$normalizedBase/trades/${Uri.encodeComponent(symbol.toUpperCase())}$query';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      await _channel!.ready;

      _subscription = _channel!.stream.listen(
        (message) {
          if (_disposed) return;
          try {
            final messageStr = message as String;
            debugPrint('IAP DEBUG: WS Message Received: ${messageStr.length > 200 ? messageStr.substring(0, 200) + "..." : messageStr}');
            
            final decoded = json.decode(messageStr);
            if (decoded is! Map<String, dynamic>) {
               debugPrint('IAP DEBUG: WS Message is not a Map: $decoded');
               return;
            }

            final type = decoded['type'] ?? decoded['channel'];
            final dynamic rawData = decoded['data'];
            
            debugPrint('IAP DEBUG: WS Message Type: $type, Data Raw Type: ${rawData.runtimeType}');

            if (type == 'trades_error') {
              onError?.call(decoded['error'] ?? 'Unknown WebSocket Error');
              return;
            }

            if (rawData == null) return;

            final List<Trade> trades = [];
            if (rawData is List) {
              trades.addAll(rawData
                  .whereType<Map>()
                  .map((j) => Trade.fromJson(Map<String, dynamic>.from(j))));
            } else if (rawData is Map) {
              trades.add(Trade.fromJson(Map<String, dynamic>.from(rawData)));
            }

            debugPrint('IAP DEBUG: Successfully parsed ${trades.length} trades for type: $type');

            if (type == 'trades_snapshot' || type == 'tradesSnapshot') {
              onSnapshot(trades);
            } else if (type == 'trades_update' || type == 'tradesUpdate' || type == 'trades') {
              onUpdates(trades);
            } else {
              debugPrint('IAP DEBUG: Message type "$type" is not a trade update, ignoring.');
            }
          } catch (e, stack) {
            debugPrint('IAP DEBUG: TradesService WS Parse Error: $e');
            debugPrint('IAP DEBUG: Stack Trace: $stack');
          }
        },
        onError: (e) {
          debugPrint('TradesService WS Error: $e');
          onError?.call(e);
        },
        onDone: () {
          debugPrint('TradesService WS Closed');
        },
      );
      debugPrint('TradesService connected: $wsUrl');
    } catch (e) {
      debugPrint('TradesService connection failed: $e');
      onError?.call(e);
    }
  }

  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _channel?.sink.close();
  }
}

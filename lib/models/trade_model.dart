import 'package:flutter/foundation.dart';

class Trade {
  final String symbol;
  final int time;
  final String timeFormatted;
  final String direction;    // "BUY" or "SELL"
  final String directionRaw; // "B" or "A"
  final double price;
  final double size;
  final double value;
  final String? hash;

  Trade({
    required this.symbol,
    required this.time,
    required this.timeFormatted,
    required this.direction,
    required this.directionRaw,
    required this.price,
    required this.size,
    required this.value,
    this.hash,
  });

  factory Trade.fromJson(Map<String, dynamic> j) {
    try {
      // Support both epoch-ms int and ISO timestamp string (HIP4 REST format)
      int timeMs;
      final rawTs = j['time'] ?? j['t'] ?? j['timestamp'];
      if (rawTs is num) {
        timeMs = rawTs.toInt();
      } else if (rawTs is String) {
        try {
          timeMs = DateTime.parse(rawTs).millisecondsSinceEpoch;
        } catch (_) {
          timeMs = 0;
        }
      } else {
        timeMs = 0;
      }

      String formatted = (j['timeFormatted'] ?? '').toString();
      if (formatted.isEmpty && timeMs != 0) {
        final dt = DateTime.fromMillisecondsSinceEpoch(timeMs).toLocal();
        final hour = dt.hour.toString().padLeft(2, '0');
        final minute = dt.minute.toString().padLeft(2, '0');
        final second = dt.second.toString().padLeft(2, '0');
        formatted = '$hour:$minute:$second';
      }

      // HIP4 REST uses "direction": "Buy"/"Sell"; WS uses "side": "B"/"A"
      final rawDir = (j['direction'] ?? j['side'] ?? 'BUY').toString();
      final String side;
      if (rawDir.toLowerCase() == 'buy' || rawDir == 'B') {
        side = 'BUY';
      } else if (rawDir.toLowerCase() == 'sell' || rawDir == 'A') {
        side = 'SELL';
      } else {
        side = rawDir.toUpperCase();
      }

      final double price = _toDouble(j['price'] ?? j['px'] ?? j['p']);
      final double size = _toDouble(j['size'] ?? j['sz'] ?? j['q']);
      final double value = _toDouble(
          j['value'] ?? j['v'] ?? j['w'] ??
          (price > 0 && size > 0 ? price * size : 0));

      return Trade(
        symbol: (j['coin'] ?? j['symbol'] ?? j['s'] ?? '').toString(),
        time: timeMs,
        timeFormatted: formatted,
        direction: side,
        directionRaw: (j['directionRaw'] ?? (side == 'SELL' ? 'A' : 'B')).toString(),
        price: price,
        size: size,
        value: value,
        hash: (j['hash'] ?? j['h'] ?? j['trade_id']?.toString())?.toString(),
      );
    } catch (e) {
      debugPrint('Trade.fromJson Error: $j => $e');
      rethrow;
    }
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  bool get isBuy => direction == 'BUY';
}

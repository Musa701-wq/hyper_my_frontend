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
      final int timeMs = _toDouble(j['time'] ?? j['t'] ?? j['timestamp']).toInt();
      String formatted = (j['timeFormatted'] ?? '').toString();

      if (formatted.isEmpty && timeMs != 0) {
        final dt = DateTime.fromMillisecondsSinceEpoch(timeMs);
        final hour = dt.hour.toString().padLeft(2, '0');
        final minute = dt.minute.toString().padLeft(2, '0');
        final second = dt.second.toString().padLeft(2, '0');
        formatted = '$hour:$minute:$second';
      }

      final String side = (j['side'] ?? j['direction'] ?? 'BUY').toString().toUpperCase();

      return Trade(
        symbol: (j['symbol'] ?? j['s'] ?? '').toString(),
        time: timeMs,
        timeFormatted: formatted,
        direction: side,
        directionRaw: (j['directionRaw'] ?? (side == 'SELL' || side == 'ASK' ? 'A' : 'B')).toString(),
        price: _toDouble(j['price'] ?? j['px'] ?? j['p']),
        size: _toDouble(j['size'] ?? j['sz'] ?? j['q']),
        value: _toDouble(j['value'] ?? j['v'] ?? j['w']),
        hash: (j['hash'] ?? j['h'])?.toString(),
      );
    } catch (e) {
      debugPrint('IAP DEBUG: Error parsing Trade from JSON: $j');
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

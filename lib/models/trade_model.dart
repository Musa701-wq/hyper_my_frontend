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
    final int timeMs = (j['time'] as num?)?.toInt() ?? 0;
    String formatted = j['timeFormatted'] ?? '';

    if (formatted.isEmpty && timeMs != 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(timeMs);
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      final second = dt.second.toString().padLeft(2, '0');
      formatted = '$hour:$minute:$second';
    }

    return Trade(
      symbol: j['symbol'] ?? '',
      time: timeMs,
      timeFormatted: formatted,
      direction: j['direction'] ?? 'BUY',
      directionRaw: j['directionRaw'] ?? (j['direction'] == 'SELL' ? 'A' : 'B'),
      price: _toDouble(j['price']),
      size: _toDouble(j['size']),
      value: _toDouble(j['value']),
      hash: j['hash'],
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  bool get isBuy => direction == 'BUY';
}

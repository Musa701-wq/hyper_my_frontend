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
    return Trade(
      symbol: j['symbol'] ?? '',
      time: (j['time'] as num?)?.toInt() ?? 0,
      timeFormatted: j['timeFormatted'] ?? '',
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

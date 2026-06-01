class OrderBookLevel {
  final double price;
  final double size;
  final int orders;
  final double cumulative;

  const OrderBookLevel({
    required this.price,
    required this.size,
    required this.orders,
    required this.cumulative,
  });

  factory OrderBookLevel.fromJson(Map<String, dynamic> json) {
    return OrderBookLevel(
      price: _toDouble(json['price']),
      size: _toDouble(json['size']),
      orders: (json['orders'] as num?)?.toInt() ?? 0,
      cumulative: _toDouble(json['cumulative']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class OrderBookSpread {
  final double absolute;
  final double percentage;

  const OrderBookSpread({required this.absolute, required this.percentage});

  factory OrderBookSpread.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const OrderBookSpread(absolute: 0, percentage: 0);
    return OrderBookSpread(
      absolute: OrderBookLevel._toDouble(json['absolute']),
      percentage: OrderBookLevel._toDouble(json['percentage']),
    );
  }
}

class OrderBookSnapshot {
  final String symbol;
  final List<OrderBookLevel> bids;
  final List<OrderBookLevel> asks;
  final OrderBookSpread spread;
  final int lastUpdate;

  const OrderBookSnapshot({
    required this.symbol,
    required this.bids,
    required this.asks,
    required this.spread,
    required this.lastUpdate,
  });

  static const int displayLevels = 6;

  /// Best asks first in API — show 5 nearest to spread, highest price at top.
  List<OrderBookLevel> get displayAsks {
    final levels = asks.take(displayLevels).toList();
    return levels.reversed.toList();
  }

  /// Best bids first in API — show 5 nearest to spread, best bid at top.
  List<OrderBookLevel> get displayBids => bids.take(displayLevels).toList();

  factory OrderBookSnapshot.fromJson(Map<String, dynamic> json) {
    return OrderBookSnapshot(
      symbol: json['symbol']?.toString() ?? '',
      bids: _parseLevels(json['bids']),
      asks: _parseLevels(json['asks']),
      spread: OrderBookSpread.fromJson(json['spread'] as Map<String, dynamic>?),
      lastUpdate: (json['lastUpdate'] as num?)?.toInt() ?? 0,
    );
  }

  static List<OrderBookLevel> _parseLevels(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => OrderBookLevel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

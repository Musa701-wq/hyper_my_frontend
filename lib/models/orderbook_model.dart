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
      price: _toDouble(json['price'] ?? json['px']),
      size: _toDouble(json['size'] ?? json['sz']),
      orders: (json['orders'] as num? ?? json['n'] as num?)?.toInt() ?? 0,
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
    final bidsList = _parseLevels(json['bids']);
    final asksList = _parseLevels(json['asks']);

    OrderBookSpread parsedSpread;
    if (json['spread'] is Map) {
      parsedSpread = OrderBookSpread.fromJson(Map<String, dynamic>.from(json['spread'] as Map));
    } else if (bidsList.isNotEmpty && asksList.isNotEmpty) {
      final absolute = (asksList.first.price - bidsList.first.price).abs();
      final mid = (asksList.first.price + bidsList.first.price) / 2.0;
      final percentage = mid > 0 ? (absolute / mid) : 0.0;
      parsedSpread = OrderBookSpread(absolute: absolute, percentage: percentage);
    } else {
      parsedSpread = const OrderBookSpread(absolute: 0, percentage: 0);
    }

    int lastUp = 0;
    if (json['lastUpdate'] != null) {
      lastUp = (json['lastUpdate'] as num).toInt();
    } else if (json['timestamp'] != null) {
      final t = json['timestamp'];
      if (t is num) {
        lastUp = t.toInt();
      } else if (t is String) {
        final parsedDate = DateTime.tryParse(t);
        if (parsedDate != null) {
          lastUp = parsedDate.millisecondsSinceEpoch;
        }
      }
    }

    return OrderBookSnapshot(
      symbol: json['symbol']?.toString() ?? json['coin']?.toString() ?? '',
      bids: bidsList,
      asks: asksList,
      spread: parsedSpread,
      lastUpdate: lastUp,
    );
  }

  static List<OrderBookLevel> _parseLevels(dynamic raw) {
    if (raw is! List) return [];
    double cum = 0.0;
    return raw
        .whereType<Map>()
        .map((e) {
          final level = OrderBookLevel.fromJson(Map<String, dynamic>.from(e));
          final computedCumulative = level.cumulative > 0 ? level.cumulative : (cum += level.size);
          if (level.cumulative == 0 && level.size > 0) {
            return OrderBookLevel(
              price: level.price,
              size: level.size,
              orders: level.orders,
              cumulative: computedCumulative,
            );
          }
          cum = level.cumulative;
          return level;
        })
        .toList();
  }
}

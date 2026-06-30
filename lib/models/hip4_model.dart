class Hip4Market {
  final int id;
  final String name;
  final String description;
  final String marketClass; // priceBinary, priceBucket, question, custom
  final String category;    // crypto, sports, custom
  final String? underlying;
  final double? targetPrice;
  final String? period;
  final DateTime? expiry;
  final List<Hip4Outcome> outcomes;

  Hip4Market({
    required this.id,
    required this.name,
    required this.description,
    required this.marketClass,
    required this.category,
    this.underlying,
    this.targetPrice,
    this.period,
    this.expiry,
    required this.outcomes,
  });

  factory Hip4Market.fromJson(Map<String, dynamic> json) {
    var outcomesList = json['coins'] as List? ?? json['outcomes'] as List? ?? [];
    return Hip4Market(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      marketClass: json['marketClass'] ?? json['class'] ?? 'custom',
      category: json['category'] ?? 'custom',
      underlying: json['underlying'],
      targetPrice: json['target'] != null ? double.tryParse(json['target'].toString()) : null,
      period: json['period'],
      expiry: json['expiry'] != null ? DateTime.tryParse(json['expiry'].toString()) : null,
      outcomes: outcomesList.map((o) => Hip4Outcome.fromJson(o)).toList(),
    );
  }

  // Helper to get total probability sum for internal checks
  double get totalProbability => outcomes.fold(0.0, (sum, o) => sum + o.probability);
}

class Hip4Outcome {
  final int id;
  final String coinName; // e.g. #2510
  final String label;    // Yes, No, or Team
  final double price;    // Mid price 0-1
  final double probability; // 0-100%

  Hip4Outcome({
    required this.id,
    required this.coinName,
    required this.label,
    required this.price,
    required this.probability,
  });

  factory Hip4Outcome.fromJson(Map<String, dynamic> json) {
    return Hip4Outcome(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      coinName: (json['coinName'] ?? json['coin'] ?? json['token'] ?? json['symbol'] ?? '').toString(),
      label: (json['label'] ?? json['name'] ?? json['side'] ?? '').toString(),
      price: json['price'] != null ? double.tryParse(json['price'].toString()) ?? 0.0 : 0.0,
      probability: json['probability'] != null ? double.tryParse(json['probability'].toString()) ?? 0.0 : 0.0,
    );
  }
}

class Hip4AggregatedOi {
  final int side0OpenInterestContracts;
  final int side1OpenInterestContracts;
  final int outcomeDisplayOpenInterestContracts;
  final int pairedSetSupplyContracts;
  final bool sideSupplyParity;
  final String currency;
  final DateTime asOf;
  final DateTime side0AsOf;
  final DateTime side1AsOf;

  Hip4AggregatedOi({
    required this.side0OpenInterestContracts,
    required this.side1OpenInterestContracts,
    required this.outcomeDisplayOpenInterestContracts,
    required this.pairedSetSupplyContracts,
    required this.sideSupplyParity,
    required this.currency,
    required this.asOf,
    required this.side0AsOf,
    required this.side1AsOf,
  });

  factory Hip4AggregatedOi.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    return Hip4AggregatedOi(
      side0OpenInterestContracts: json['side0_open_interest_contracts'] is int
          ? json['side0_open_interest_contracts']
          : int.tryParse(json['side0_open_interest_contracts']?.toString() ?? '') ?? 0,
      side1OpenInterestContracts: json['side1_open_interest_contracts'] is int
          ? json['side1_open_interest_contracts']
          : int.tryParse(json['side1_open_interest_contracts']?.toString() ?? '') ?? 0,
      outcomeDisplayOpenInterestContracts: json['outcome_display_open_interest_contracts'] is int
          ? json['outcome_display_open_interest_contracts']
          : int.tryParse(json['outcome_display_open_interest_contracts']?.toString() ?? '') ?? 0,
      pairedSetSupplyContracts: json['paired_set_supply_contracts'] is int
          ? json['paired_set_supply_contracts']
          : int.tryParse(json['paired_set_supply_contracts']?.toString() ?? '') ?? 0,
      sideSupplyParity: json['side_supply_parity'] ?? false,
      currency: json['currency'] ?? '',
      asOf: parseDate(json['as_of']),
      side0AsOf: parseDate(json['side0_as_of']),
      side1AsOf: parseDate(json['side1_as_of']),
    );
  }
}

class Hip4Candle {
  final DateTime timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final double quoteVolume;
  final int tradeCount;

  Hip4Candle({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.quoteVolume,
    required this.tradeCount,
  });

  factory Hip4Candle.fromJson(Map<String, dynamic> json) {
    DateTime parsedTime;
    try {
      final rawTs = json['timestamp'] ?? json['time'] ?? json['t'] ?? '';
      if (rawTs is int) {
        parsedTime = DateTime.fromMillisecondsSinceEpoch(rawTs);
      } else {
        parsedTime = DateTime.tryParse(rawTs.toString()) ?? DateTime.now();
      }
    } catch (_) {
      parsedTime = DateTime.now();
    }

    return Hip4Candle(
      timestamp: parsedTime,
      open: double.tryParse(json['open']?.toString() ?? '') ?? 0.0,
      high: double.tryParse(json['high']?.toString() ?? '') ?? 0.0,
      low: double.tryParse(json['low']?.toString() ?? '') ?? 0.0,
      close: double.tryParse(json['close']?.toString() ?? '') ?? 0.0,
      volume: double.tryParse(json['volume']?.toString() ?? '') ?? 0.0,
      quoteVolume: double.tryParse(json['quote_volume']?.toString() ?? '') ?? 0.0,
      tradeCount: json['trade_count'] is int
          ? json['trade_count']
          : int.tryParse(json['trade_count']?.toString() ?? '') ?? 0,
    );
  }
}

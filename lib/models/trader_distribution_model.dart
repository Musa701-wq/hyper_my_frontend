class TraderDistributionModel {
  final int totalTraders;
  final double totalValue; // totalAccountValue or totalVolume
  final Map<String, DistributionSegment> distribution;
  final String period;

  TraderDistributionModel({
    required this.totalTraders,
    required this.totalValue,
    required this.distribution,
    this.period = 'allTime',
  });

  factory TraderDistributionModel.fromJson(Map<String, dynamic> json) {
    // API returns { success: true, data: { ... } }
    final d = json['data'] ?? json;
    
    final Map<String, dynamic> distRaw = d['distribution'] ?? {};
    final Map<String, DistributionSegment> segments = {};
    
    distRaw.forEach((key, value) {
      segments[key] = DistributionSegment.fromJson(value, key);
    });

    return TraderDistributionModel(
      totalTraders: d['totalTraders'] ?? 0,
      totalValue: (d['totalAccountValue'] ?? d['totalVolume'] ?? 0.0).toDouble(),
      distribution: segments,
      period: d['period'] ?? 'allTime',
    );
  }
}

class DistributionSegment {
  final String label;
  final String key;
  final double traderPct;
  final double valuePct; // account value or volume
  final double rawValue;
  final int traderCount;

  DistributionSegment({
    required this.label,
    required this.key,
    required this.traderPct,
    required this.valuePct,
    required this.rawValue,
    required this.traderCount,
  });

  factory DistributionSegment.fromJson(Map<String, dynamic> json, String key) {
    return DistributionSegment(
      key: key,
      label: json['label'] ?? key.toUpperCase(),
      // Chart 1 uses traderPct/valuePct, Chart 2 uses volumePct/traderCount
      traderPct: (json['traderPct'] ?? 0.0).toDouble(),
      valuePct: (json['valuePct'] ?? json['volumePct'] ?? 0.0).toDouble(),
      rawValue: (json['totalValue'] ?? json['volume'] ?? 0.0).toDouble(),
      traderCount: json['traderCount'] ?? 0,
    );
  }
}

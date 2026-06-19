import 'package:intl/intl.dart';

class DexVolumeMetrics {
  final double total24h;
  final double total48hto24h;
  final double total7d;
  final double total30d;
  final double total1y;
  final double totalAllTime;
  final double change1d;
  final double? total14dto7d;
  final double? total60dto30d;
  final double? change7d;
  final double? change1m;
  final double? change7dover7d;
  final double? change30dover30d;

  DexVolumeMetrics({
    required this.total24h,
    required this.total48hto24h,
    required this.total7d,
    required this.total30d,
    required this.total1y,
    required this.totalAllTime,
    required this.change1d,
    this.total14dto7d,
    this.total60dto30d,
    this.change7d,
    this.change1m,
    this.change7dover7d,
    this.change30dover30d,
  });

  factory DexVolumeMetrics.fromJson(Map<String, dynamic> json) {
    return DexVolumeMetrics(
      total24h: _toDouble(json['total24h']),
      total48hto24h: _toDouble(json['total48hto24h']),
      total7d: _toDouble(json['total7d']),
      total30d: _toDouble(json['total30d']),
      total1y: _toDouble(json['total1y']),
      totalAllTime: _toDouble(json['totalAllTime']),
      change1d: _toDouble(json['change_1d']),
      total14dto7d: _toDoubleOrNull(json['total14dto7d']),
      total60dto30d: _toDoubleOrNull(json['total60dto30d']),
      change7d: _toDoubleOrNull(json['change_7d']),
      change1m: _toDoubleOrNull(json['change_1m']),
      change7dover7d: _toDoubleOrNull(json['change_7dover7d']),
      change30dover30d: _toDoubleOrNull(json['change_30dover30d']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class DexVolumeChartPoint {
  final DateTime timestamp;
  final double volume;

  DexVolumeChartPoint({
    required this.timestamp,
    required this.volume,
  });

  factory DexVolumeChartPoint.fromList(List<dynamic> list) {
    // Documentation says arrays are [timestamp, volume] - timestamp is usually unix seconds in DefiLlama
    final tsValue = list[0] is num ? (list[0] as num).toInt() : 0;
    // Check if seconds or milliseconds (DefiLlama uses seconds)
    final ts = tsValue > 2000000000 ? tsValue : tsValue * 1000;
    
    return DexVolumeChartPoint(
      timestamp: DateTime.fromMillisecondsSinceEpoch(ts, isUtc: true),
      volume: (list[1] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AdoptionMetrics {
  final double currentMonthVolume;
  final double previousMonthVolume;
  final double? monthOverMonthGrowth;
  final double? quarterOverQuarterGrowth;
  final double? twelveMonthGrowth;
  final int consecutiveMonthsOfGrowth;
  final bool isNewMonthlyATH;
  final double allTimeHighMonthlyVolume;
  final double? sixMonthAverageVolume;
  final List<TrendItem> monthlyTrend;
  final List<TrendItem> quarterlyTrend;

  AdoptionMetrics({
    required this.currentMonthVolume,
    required this.previousMonthVolume,
    this.monthOverMonthGrowth,
    this.quarterOverQuarterGrowth,
    this.twelveMonthGrowth,
    required this.consecutiveMonthsOfGrowth,
    required this.isNewMonthlyATH,
    required this.allTimeHighMonthlyVolume,
    this.sixMonthAverageVolume,
    required this.monthlyTrend,
    required this.quarterlyTrend,
  });

  factory AdoptionMetrics.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json; // Handle wrapped vs unwrapped
    return AdoptionMetrics(
      currentMonthVolume: _toDouble(data['currentMonthVolume']),
      previousMonthVolume: _toDouble(data['previousMonthVolume']),
      monthOverMonthGrowth: _toDoubleOrNull(data['monthOverMonthGrowth']),
      quarterOverQuarterGrowth: _toDoubleOrNull(data['quarterOverQuarterGrowth']),
      twelveMonthGrowth: _toDoubleOrNull(data['twelveMonthGrowth']),
      consecutiveMonthsOfGrowth: (data['consecutiveMonthsOfGrowth'] as num?)?.toInt() ?? 0,
      isNewMonthlyATH: data['isNewMonthlyATH'] ?? false,
      allTimeHighMonthlyVolume: _toDouble(data['allTimeHighMonthlyVolume']),
      sixMonthAverageVolume: _toDoubleOrNull(data['sixMonthAverageVolume']),
      monthlyTrend: (data['monthlyTrend'] as List?)
              ?.map((e) => TrendItem.fromJson(e))
              .toList() ??
          [],
      quarterlyTrend: (data['quarterlyTrend'] as List?)
              ?.map((e) => TrendItem.fromJson(e))
              .toList() ??
          [],
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class TrendItem {
  final String label; // "2024-01" or "Q1 2024"
  final double volume;

  TrendItem({
    required this.label,
    required this.volume,
  });

  factory TrendItem.fromJson(Map<String, dynamic> json) {
    return TrendItem(
      label: json['month'] ?? json['quarter'] ?? '',
      volume: (json['volume'] as num?)?.toDouble() ?? 0.0,
    );
  }

  DateTime toDateTime() {
    if (label.contains('-')) {
      // YYYY-MM
      final parts = label.split('-');
      return DateTime.utc(int.parse(parts[0]), int.parse(parts[1]), 1);
    } else if (label.startsWith('Q')) {
      // Q# YYYY
      final parts = label.split(' ');
      final q = int.parse(parts[0].replaceAll('Q', ''));
      final month = (q - 1) * 3 + 1;
      return DateTime.utc(int.parse(parts[1]), month, 1);
    }
    return DateTime.now();
  }
}

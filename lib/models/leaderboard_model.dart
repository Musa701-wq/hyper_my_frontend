import 'package:flutter/foundation.dart';

class LeaderboardStats {
  final String period;
  final int totalTraders;
  final int profitableTraders;
  final double profitablePercentage;
  final double totalAccountValue;
  final double totalVolume;
  final double totalPnl;
  final double averageRoi;
  final double averagePnl;
  final double averageVolume;
  final DateTime timestamp;

  LeaderboardStats({
    required this.period,
    required this.totalTraders,
    required this.profitableTraders,
    required this.profitablePercentage,
    required this.totalAccountValue,
    required this.totalVolume,
    required this.totalPnl,
    required this.averageRoi,
    required this.averagePnl,
    required this.averageVolume,
    required this.timestamp,
  });

  factory LeaderboardStats.fromJson(Map<String, dynamic> json) {
    try {
      final data = json['data'] ?? json;
      debugPrint('Parsing LeaderboardStats: $data');
      return LeaderboardStats(
        period: data['period']?.toString() ?? 'allTime',
        totalTraders: int.tryParse(data['totalTraders']?.toString() ?? '0') ?? 0,
        profitableTraders: int.tryParse(data['profitableTraders']?.toString() ?? '0') ?? 0,
        profitablePercentage: double.tryParse(data['profitablePercentage']?.toString() ?? '0') ?? 0.0,
        totalAccountValue: double.tryParse(data['totalAccountValue']?.toString() ?? '0') ?? 0.0,
        totalVolume: double.tryParse(data['totalVolume']?.toString() ?? '0') ?? 0.0,
        totalPnl: double.tryParse(data['totalPnl']?.toString() ?? '0') ?? 0.0,
        averageRoi: double.tryParse(data['averageRoi']?.toString() ?? '0') ?? 0.0,
        averagePnl: double.tryParse(data['averagePnl']?.toString() ?? '0') ?? 0.0,
        averageVolume: double.tryParse(data['averageVolume']?.toString() ?? '0') ?? 0.0,
        timestamp: data['timestamp'] != null 
            ? DateTime.tryParse(data['timestamp'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error parsing LeaderboardStats: $e');
      rethrow;
    }
  }
}

class Trader {
  final String ethAddress;
  final String displayName;
  final double accountValue;
  final double pnl;
  final double roi;
  final double volume;
  final double prize;
  final DateTime updatedAt;

  Trader({
    required this.ethAddress,
    required this.displayName,
    required this.accountValue,
    required this.pnl,
    required this.roi,
    required this.volume,
    required this.prize,
    required this.updatedAt,
  });

  factory Trader.fromJson(Map<String, dynamic> json) {
    try {
      return Trader(
        ethAddress: json['ethAddress']?.toString() ?? '',
        displayName: json['displayName']?.toString() ?? 'Anonymous',
        accountValue: (json['accountValue'] ?? 0).toDouble(),
        pnl: (json['pnl'] ?? 0).toDouble(),
        roi: (json['roi'] ?? 0).toDouble(),
        volume: (json['volume'] ?? 0).toDouble(),
        prize: (json['prize'] ?? 0).toDouble(),
        updatedAt: json['updatedAt'] != null 
            ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
            : DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error parsing trader: $json, error: $e');
      rethrow;
    }
  }
}

class TraderPerformance {
  final double pnl;
  final double roi;
  final double volume;

  TraderPerformance({required this.pnl, required this.roi, required this.volume});

  factory TraderPerformance.fromJson(Map<String, dynamic> json) {
    return TraderPerformance(
      pnl: (json['pnl'] ?? 0).toDouble(),
      roi: (json['roi'] ?? 0).toDouble(),
      volume: (json['volume'] ?? 0).toDouble(),
    );
  }
}

class LeaderboardResponse {
  final List<Trader> traders;
  final int totalCount;
  final int totalPages;
  final int currentPage;

  LeaderboardResponse({
    required this.traders,
    required this.totalCount,
    required this.totalPages,
    required this.currentPage,
  });

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final pagination = data['pagination'] ?? {};
    final tradersList = (data['traders'] as List?) ?? [];
    
    return LeaderboardResponse(
      traders: tradersList.map((t) => Trader.fromJson(t)).toList(),
      totalCount: pagination['totalCount'] ?? tradersList.length,
      totalPages: pagination['totalPages'] ?? 1,
      currentPage: pagination['page'] ?? 1,
    );
  }
}

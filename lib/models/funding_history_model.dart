class FundingHistoryEntry {
  final String coin;
  final double fundingRate;
  final double premium;
  final int time;

  FundingHistoryEntry({
    required this.coin,
    required this.fundingRate,
    required this.premium,
    required this.time,
  });

  factory FundingHistoryEntry.fromJson(Map<String, dynamic> json) {
    return FundingHistoryEntry(
      coin: json['coin'] ?? '',
      fundingRate: (json['fundingRate'] ?? 0.0).toDouble(),
      premium: (json['premium'] ?? 0.0).toDouble(),
      time: json['time'] ?? 0,
    );
  }
}

class FundingHistoryResponse {
  final bool success;
  final String coin;
  final int count;
  final List<FundingHistoryEntry> data;

  FundingHistoryResponse({
    required this.success,
    required this.coin,
    required this.count,
    required this.data,
  });

  factory FundingHistoryResponse.fromJson(Map<String, dynamic> json) {
    var rawList = json['data'] as List? ?? [];
    return FundingHistoryResponse(
      success: json['success'] ?? false,
      coin: json['coin'] ?? '',
      count: json['count'] ?? 0,
      data: rawList.map((e) => FundingHistoryEntry.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

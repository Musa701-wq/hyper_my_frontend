class BorrowLendModel {
  final int tokenIndex;
  final String tokenName;
  final double borrowYearlyRate;
  final double supplyYearlyRate;
  final double balance;
  final double utilization;
  final double oraclePx;
  final double? ltv;
  final double totalSupplied;
  final double totalBorrowed;

  BorrowLendModel({
    required this.tokenIndex,
    required this.tokenName,
    required this.borrowYearlyRate,
    required this.supplyYearlyRate,
    required this.balance,
    required this.utilization,
    required this.oraclePx,
    this.ltv,
    required this.totalSupplied,
    required this.totalBorrowed,
  });

  factory BorrowLendModel.fromJson(Map<String, dynamic> json) {
    // Helper to parse double from either dynamic String or Number
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) {
        if (val.toUpperCase() == 'N/A' || val.trim().isEmpty) return 0.0;
        return double.tryParse(val) ?? 0.0;
      }
      return 0.0;
    }

    double? parseLtv(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) {
        if (val.toUpperCase() == 'N/A' || val.trim().isEmpty) return null;
        return double.tryParse(val);
      }
      return null;
    }

    return BorrowLendModel(
      tokenIndex: json['tokenIndex'] as int? ?? 0,
      tokenName: json['tokenName'] as String? ?? 'UNKNOWN',
      borrowYearlyRate: parseDouble(json['borrowYearlyRate']),
      supplyYearlyRate: parseDouble(json['supplyYearlyRate']),
      balance: parseDouble(json['balance']),
      utilization: parseDouble(json['utilization']),
      oraclePx: parseDouble(json['oraclePx']),
      ltv: parseLtv(json['ltv']),
      totalSupplied: parseDouble(json['totalSupplied']),
      totalBorrowed: parseDouble(json['totalBorrowed']),
    );
  }
}

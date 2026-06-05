class PortfolioHistoryModel {
  final String walletAddress;
  final List<TradeFill> fills;
  final int totalFills;
  final String fetchedAt;
  final bool isStale;

  PortfolioHistoryModel({
    required this.walletAddress,
    required this.fills,
    required this.totalFills,
    required this.fetchedAt,
    required this.isStale,
  });

  factory PortfolioHistoryModel.fromJson(Map<String, dynamic> json) {
    return PortfolioHistoryModel(
      walletAddress: json['walletAddress'] ?? '',
      fills: (json['fills'] as List? ?? [])
          .map((e) => TradeFill.fromJson(e))
          .toList(),
      totalFills: json['totalFills'] ?? 0,
      fetchedAt: json['fetchedAt'] ?? '',
      isStale: json['isStale'] ?? false,
    );
  }
}

class TradeFill {
  final int time;
  final String coin;
  final String side;
  final double px;
  final double sz;
  final double fee;
  final double closedPnl;
  final String dir;
  final String hash;

  TradeFill({
    required this.time,
    required this.coin,
    required this.side,
    required this.px,
    required this.sz,
    required this.fee,
    required this.closedPnl,
    required this.dir,
    required this.hash,
  });

  factory TradeFill.fromJson(Map<String, dynamic> json) {
    return TradeFill(
      time: json['time'] ?? 0,
      coin: json['coin'] ?? '',
      side: json['side'] ?? '',
      px: (json['px'] ?? 0).toDouble(),
      sz: (json['sz'] ?? 0).toDouble(),
      fee: (json['fee'] ?? 0).toDouble(),
      closedPnl: (json['closedPnl'] ?? 0).toDouble(),
      dir: json['dir'] ?? '',
      hash: json['hash'] ?? '',
    );
  }
}

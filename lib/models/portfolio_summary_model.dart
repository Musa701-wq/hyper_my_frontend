class PortfolioSummaryModel {
  final String walletAddress;
  final double totalBalance;
  final double perpAccountValue;
  final double spotUSDValue;
  final double unrealizedPnl;
  final double unrealizedPnlPct;
  final double buyingPower;
  final double withdrawable;
  final double marginUsed;
  final double totalMarginUsed;
  final List<PerpPosition> positions;
  final List<SpotBalance> spotBalances;
  final List<OpenOrder> openOrders;
  final String fetchedAt;
  final bool isStale;

  PortfolioSummaryModel({
    required this.walletAddress,
    required this.totalBalance,
    required this.perpAccountValue,
    required this.spotUSDValue,
    required this.unrealizedPnl,
    required this.unrealizedPnlPct,
    required this.buyingPower,
    required this.withdrawable,
    required this.marginUsed,
    required this.totalMarginUsed,
    required this.positions,
    required this.spotBalances,
    required this.openOrders,
    required this.fetchedAt,
    required this.isStale,
  });

  factory PortfolioSummaryModel.fromJson(Map<String, dynamic> json) {
    return PortfolioSummaryModel(
      walletAddress: json['walletAddress'] ?? '',
      totalBalance: (json['totalBalance'] ?? 0).toDouble(),
      perpAccountValue: (json['perpAccountValue'] ?? 0).toDouble(),
      spotUSDValue: (json['spotUSDValue'] ?? 0).toDouble(),
      unrealizedPnl: (json['unrealizedPnl'] ?? 0).toDouble(),
      unrealizedPnlPct: (json['unrealizedPnlPct'] ?? 0).toDouble(),
      buyingPower: (json['buyingPower'] ?? 0).toDouble(),
      withdrawable: (json['withdrawable'] ?? 0).toDouble(),
      marginUsed: (json['marginUsed'] ?? 0).toDouble(),
      totalMarginUsed: (json['totalMarginUsed'] ?? 0).toDouble(),
      positions: (json['positions'] as List? ?? [])
          .map((e) => PerpPosition.fromJson(e))
          .toList(),
      spotBalances: (json['spotBalances'] as List? ?? [])
          .map((e) => SpotBalance.fromJson(e))
          .toList(),
      openOrders: (json['openOrders'] as List? ?? [])
          .map((e) => OpenOrder.fromJson(e))
          .toList(),
      fetchedAt: json['fetchedAt'] ?? '',
      isStale: json['isStale'] ?? false,
    );
  }
}

class PerpPosition {
  final String coin;
  final String side;
  final double size;
  final double entryPx;
  final double markPx;
  final double liqPx;
  final double liqDistancePct;
  final String liqRisk;
  final double unrealizedPnl;
  final double unrealizedPnlPct;
  final double leverage;
  final double marginUsed;
  final double maxLeverage;

  PerpPosition({
    required this.coin,
    required this.side,
    required this.size,
    required this.entryPx,
    required this.markPx,
    required this.liqPx,
    required this.liqDistancePct,
    required this.liqRisk,
    required this.unrealizedPnl,
    required this.unrealizedPnlPct,
    required this.leverage,
    required this.marginUsed,
    required this.maxLeverage,
  });

  factory PerpPosition.fromJson(Map<String, dynamic> json) {
    return PerpPosition(
      coin: json['coin'] ?? '',
      side: json['side'] ?? '',
      size: (json['size'] ?? 0).toDouble(),
      entryPx: (json['entryPx'] ?? 0).toDouble(),
      markPx: (json['markPx'] ?? 0).toDouble(),
      liqPx: (json['liqPx'] ?? 0).toDouble(),
      liqDistancePct: (json['liqDistancePct'] ?? 0).toDouble(),
      liqRisk: json['liqRisk'] ?? 'safe',
      unrealizedPnl: (json['unrealizedPnl'] ?? 0).toDouble(),
      unrealizedPnlPct: (json['unrealizedPnlPct'] ?? 0).toDouble(),
      leverage: (json['leverage'] ?? 0).toDouble(),
      marginUsed: (json['marginUsed'] ?? 0).toDouble(),
      maxLeverage: (json['maxLeverage'] ?? 0).toDouble(),
    );
  }
}

class SpotBalance {
  final String coin;
  final String iconUrl;
  final double total;
  final double hold;
  final double available;
  final double markPx;
  final double usdValue;
  final double allocationPct;

  SpotBalance({
    required this.coin,
    required this.iconUrl,
    required this.total,
    required this.hold,
    required this.available,
    required this.markPx,
    required this.usdValue,
    required this.allocationPct,
  });

  factory SpotBalance.fromJson(Map<String, dynamic> json) {
    return SpotBalance(
      coin: json['coin'] ?? '',
      iconUrl: json['iconUrl'] ?? '',
      total: (json['total'] ?? 0).toDouble(),
      hold: (json['hold'] ?? 0).toDouble(),
      available: (json['available'] ?? 0).toDouble(),
      markPx: (json['markPx'] ?? 0).toDouble(),
      usdValue: (json['usdValue'] ?? 0).toDouble(),
      allocationPct: (json['allocationPct'] ?? 0).toDouble(),
    );
  }
}

class OpenOrder {
  final String coin;
  final String side;
  final double size;
  final double limitPx;
  final String orderType;
  final int oid;
  final int timestamp;

  OpenOrder({
    required this.coin,
    required this.side,
    required this.size,
    required this.limitPx,
    required this.orderType,
    required this.oid,
    required this.timestamp,
  });

  factory OpenOrder.fromJson(Map<String, dynamic> json) {
    return OpenOrder(
      coin: json['coin'] ?? '',
      side: json['side'] ?? '',
      size: (json['size'] ?? 0).toDouble(),
      limitPx: (json['limitPx'] ?? 0).toDouble(),
      orderType: json['orderType'] ?? '',
      oid: json['oid'] ?? 0,
      timestamp: json['timestamp'] ?? 0,
    );
  }
}

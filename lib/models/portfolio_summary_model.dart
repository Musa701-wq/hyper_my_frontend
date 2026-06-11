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

  static double _parse(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  factory PortfolioSummaryModel.fromJson(Map<String, dynamic> json) {
    return PortfolioSummaryModel(
      walletAddress: json['walletAddress'] ?? '',
      totalBalance: _parse(json['totalBalance']),
      perpAccountValue: _parse(json['perpAccountValue']),
      spotUSDValue: _parse(json['spotUSDValue']),
      unrealizedPnl: _parse(json['unrealizedPnl']),
      unrealizedPnlPct: _parse(json['unrealizedPnlPct']),
      buyingPower: _parse(json['buyingPower']),
      withdrawable: _parse(json['withdrawable']),
      marginUsed: _parse(json['marginUsed']),
      totalMarginUsed: _parse(json['totalMarginUsed']),
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
      size: PortfolioSummaryModel._parse(json['size']),
      entryPx: PortfolioSummaryModel._parse(json['entryPx']),
      markPx: PortfolioSummaryModel._parse(json['markPx']),
      liqPx: PortfolioSummaryModel._parse(json['liqPx']),
      liqDistancePct: PortfolioSummaryModel._parse(json['liqDistancePct']),
      liqRisk: json['liqRisk'] ?? 'safe',
      unrealizedPnl: PortfolioSummaryModel._parse(json['unrealizedPnl']),
      unrealizedPnlPct: PortfolioSummaryModel._parse(json['unrealizedPnlPct']),
      leverage: PortfolioSummaryModel._parse(json['leverage']),
      marginUsed: PortfolioSummaryModel._parse(json['marginUsed']),
      maxLeverage: PortfolioSummaryModel._parse(json['maxLeverage']),
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
      total: PortfolioSummaryModel._parse(json['total']),
      hold: PortfolioSummaryModel._parse(json['hold']),
      available: PortfolioSummaryModel._parse(json['available']),
      markPx: PortfolioSummaryModel._parse(json['markPx']),
      usdValue: PortfolioSummaryModel._parse(json['usdValue']),
      allocationPct: PortfolioSummaryModel._parse(json['allocationPct']),
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
      size: PortfolioSummaryModel._parse(json['size']),
      limitPx: PortfolioSummaryModel._parse(json['limitPx']),
      orderType: json['orderType'] ?? '',
      oid: json['oid'] ?? 0,
      timestamp: json['timestamp'] ?? 0,
    );
  }
}

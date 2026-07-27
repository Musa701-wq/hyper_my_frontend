class LiquidatablePosition {
  final String coin;
  final double size;         // negative = short
  final double entryPx;
  final double positionValue;
  final double unrealizedPnl;
  final double returnOnEquity;
  final double liquidationPx;
  final double marginUsed;
  final String leverageType; // "cross" | "isolated"
  final int leverageValue;

  LiquidatablePosition({
    required this.coin,
    required this.size,
    required this.entryPx,
    required this.positionValue,
    required this.unrealizedPnl,
    required this.returnOnEquity,
    required this.liquidationPx,
    required this.marginUsed,
    required this.leverageType,
    required this.leverageValue,
  });

  bool get isShort => size < 0;
  bool get isLong  => size > 0;

  factory LiquidatablePosition.fromJson(Map<String, dynamic> json) {
    final leverage = json['leverage'] as Map? ?? {};
    return LiquidatablePosition(
      coin:           json['coin'] as String? ?? '',
      size:           double.tryParse(json['szi']?.toString() ?? '0') ?? 0,
      entryPx:        double.tryParse(json['entryPx']?.toString() ?? '0') ?? 0,
      positionValue:  double.tryParse(json['positionValue']?.toString() ?? '0') ?? 0,
      unrealizedPnl:  double.tryParse(json['unrealizedPnl']?.toString() ?? '0') ?? 0,
      returnOnEquity: double.tryParse(json['returnOnEquity']?.toString() ?? '0') ?? 0,
      liquidationPx:  double.tryParse(json['liquidationPx']?.toString() ?? '0') ?? 0,
      marginUsed:     double.tryParse(json['marginUsed']?.toString() ?? '0') ?? 0,
      leverageType:   leverage['type']?.toString() ?? 'cross',
      leverageValue:  (leverage['value'] as num?)?.toInt() ?? 1,
    );
  }
}

class LiquidatableAccount {
  final String user;
  final List<LiquidatablePosition> positions;
  final double accountValue;

  LiquidatableAccount({
    required this.user,
    required this.positions,
    required this.accountValue,
  });

  factory LiquidatableAccount.fromJson(Map<String, dynamic> json) {
    return LiquidatableAccount(
      user:         json['user'] as String? ?? '',
      accountValue: double.tryParse(json['accountValue']?.toString() ?? '0') ?? 0,
      positions:    (json['positions'] as List? ?? [])
          .map((p) => LiquidatablePosition.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList(),
    );
  }
}

class LiquidatableResponse {
  final bool success;
  final int count;
  final String fetchedAt;
  final List<LiquidatableAccount> data;

  LiquidatableResponse({
    required this.success,
    required this.count,
    required this.fetchedAt,
    required this.data,
  });

  factory LiquidatableResponse.fromJson(Map<String, dynamic> json) {
    return LiquidatableResponse(
      success:   json['success'] as bool? ?? false,
      count:     json['count'] as int? ?? 0,
      fetchedAt: json['fetchedAt'] as String? ?? '',
      data:      (json['data'] as List? ?? [])
          .map((e) => LiquidatableAccount.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

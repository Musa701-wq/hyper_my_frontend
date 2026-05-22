class TickerModel {
  final String id;
  final String dex;
  final String symbol;
  final double change24hPct;
  final String displayName;
  final String fullSymbol;
  final double funding8hPct;
  final String iconUrl;
  final bool isDelisted;
  final double lastPrice;
  final double openInterestUSD;
  final String updatedAt;
  final double volume24hUSD;
  final String cryptoCategory;

  TickerModel({
    required this.id,
    required this.dex,
    required this.symbol,
    required this.change24hPct,
    required this.displayName,
    required this.fullSymbol,
    required this.funding8hPct,
    required this.iconUrl,
    required this.isDelisted,
    required this.lastPrice,
    required this.openInterestUSD,
    required this.updatedAt,
    required this.volume24hUSD,
    required this.cryptoCategory,
  });

  factory TickerModel.fromJson(Map<String, dynamic> json) {
    return TickerModel(
      id: json['_id'] ?? '',
      dex: json['dex'] ?? '',
      symbol: json['symbol'] ?? '',
      change24hPct: (json['change24hPct'] ?? 0.0).toDouble(),
      displayName: json['displayName'] ?? '',
      fullSymbol: json['fullSymbol'] ?? '',
      funding8hPct: (json['funding8hPct'] ?? 0.0).toDouble(),
      iconUrl: json['iconUrl'] ?? '',
      isDelisted: json['isDelisted'] ?? false,
      lastPrice: (json['lastPrice'] ?? 0.0).toDouble(),
      openInterestUSD: (json['openInterestUSD'] ?? 0.0).toDouble(),
      updatedAt: json['updatedAt'] ?? '',
      volume24hUSD: (json['volume24hUSD'] ?? 0.0).toDouble(),
      cryptoCategory: json['cryptoCategory'] ?? '',
    );
  }

  // Method to patch an existing ticker with incoming websocket data
  TickerModel copyWithPartial(Map<String, dynamic> partialData) {
    return TickerModel(
      id: this.id,
      dex: partialData['dex'] ?? this.dex,
      symbol: partialData['symbol'] ?? this.symbol,
      change24hPct: partialData['change24hPct'] != null ? partialData['change24hPct'].toDouble() : this.change24hPct,
      displayName: partialData['displayName'] ?? this.displayName,
      fullSymbol: partialData['fullSymbol'] ?? this.fullSymbol,
      funding8hPct: partialData['funding8hPct'] != null ? partialData['funding8hPct'].toDouble() : this.funding8hPct,
      iconUrl: partialData['iconUrl'] ?? this.iconUrl,
      isDelisted: partialData['isDelisted'] ?? this.isDelisted,
      lastPrice: partialData['lastPrice'] != null ? partialData['lastPrice'].toDouble() : this.lastPrice,
      openInterestUSD: partialData['openInterestUSD'] != null ? partialData['openInterestUSD'].toDouble() : this.openInterestUSD,
      updatedAt: partialData['updatedAt'] ?? this.updatedAt,
      volume24hUSD: partialData['volume24hUSD'] != null ? partialData['volume24hUSD'].toDouble() : this.volume24hUSD,
      cryptoCategory: partialData['cryptoCategory'] ?? this.cryptoCategory,
    );
  }
}

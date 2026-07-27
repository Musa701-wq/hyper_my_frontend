class TickerModel {
  // ── Core identity ────────────────────────────────────────────────
  final String id;
  final String dex;
  final String symbol;
  final String fullSymbol;
  final String displayName;
  final String marketType;
  final String source;
  final bool isDelisted;
  final String iconUrl;
  final String cryptoCategory;
  final String updatedAt;
  final String createdAt;
  final int? tokenIndex;

  // ── Prices ───────────────────────────────────────────────────────
  final double lastPrice;
  final double markPx;
  final double midPx;
  final double oraclePx;
  final double prevDayPx;
  final double premium;

  // ── Change / Funding ─────────────────────────────────────────────
  final double change24hPct;
  final double funding8hPct;

  // ── Order book ───────────────────────────────────────────────────
  final double impactBidPx;
  final double impactAskPx;

  // ── Market stats ─────────────────────────────────────────────────
  final double openInterest;
  final double openInterestUSD;
  final double volume24hUSD;
  final double dayBaseVlm;
  final double marketCapUSD;

  // ── Supply (spot only) ──────────────────────────────────────────
  final double circulatingSupply;
  final double totalSupply;
  final double maxSupply;

  // ── Contract / token info ────────────────────────────────────────
  final String tokenId;
  final bool? isCanonical;
  final int? szDecimals;
  final int? weiDecimals;
  final EvmContract? evmContract;
  final String? deployerTradingFeeShare;

  // ── Perp specifics ───────────────────────────────────────────────
  final int maxLeverage;
  final int? marginTableId;
  final String growthMode;

  TickerModel({
    required this.id,
    required this.dex,
    required this.symbol,
    required this.fullSymbol,
    required this.displayName,
    this.marketType = '',
    this.source = '',
    required this.isDelisted,
    required this.iconUrl,
    this.cryptoCategory = '',
    this.updatedAt = '',
    this.createdAt = '',
    // prices
    required this.lastPrice,
    this.markPx = 0.0,
    this.midPx = 0.0,
    this.oraclePx = 0.0,
    this.prevDayPx = 0.0,
    this.premium = 0.0,
    // change / funding
    required this.change24hPct,
    this.funding8hPct = 0.0,
    // order book
    this.impactBidPx = 0.0,
    this.impactAskPx = 0.0,
    // market stats
    this.openInterest = 0.0,
    required this.openInterestUSD,
    required this.volume24hUSD,
    this.dayBaseVlm = 0.0,
    this.marketCapUSD = 0.0,
    // supply
    this.circulatingSupply = 0.0,
    this.totalSupply = 0.0,
    this.maxSupply = 0.0,
    // contract
    this.tokenId = '',
    this.isCanonical,
    this.szDecimals,
    this.weiDecimals,
    this.evmContract,
    this.deployerTradingFeeShare,
    // perp
    this.maxLeverage = 0,
    this.marginTableId,
    this.growthMode = '',
    this.tokenIndex,
  });

  factory TickerModel.fromJson(Map<String, dynamic> json) {
    return TickerModel(
      id: json['_id']?.toString() ?? '',
      dex: json['dex']?.toString() ?? '',
      symbol: json['symbol']?.toString() ?? '',
      fullSymbol: json['fullSymbol']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      marketType: json['marketType']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      isDelisted: json['isDelisted'] is bool ? json['isDelisted'] : false,
      iconUrl: json['iconUrl']?.toString() ?? '',
      cryptoCategory: json['cryptoCategory']?.toString() ?? json['category']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      tokenIndex: json['tokenIndex'] != null ? (json['tokenIndex'] as num).toInt() : null,
      // prices
      lastPrice: _toDouble(json['lastPrice']),
      markPx: _toDouble(json['markPx']),
      midPx: _toDouble(json['midPx']),
      oraclePx: _toDouble(json['oraclePx']),
      prevDayPx: _toDouble(json['prevDayPx']),
      premium: _toDouble(json['premium']),
      // change / funding
      change24hPct: _toDouble(json['change24hPct']),
      funding8hPct: _toDouble(json['funding8hPct']),
      // order book
      impactBidPx: _toDouble(json['impactBidPx']),
      impactAskPx: _toDouble(json['impactAskPx']),
      // market stats
      openInterest: _toDouble(json['openInterest']),
      openInterestUSD: _toDouble(json['openInterestUSD']),
      volume24hUSD: _toDouble(json['volume24hUSD']),
      dayBaseVlm: _toDouble(json['dayBaseVlm']),
      marketCapUSD: _toDouble(json['marketCapUSD']),
      // supply
      circulatingSupply: _toDouble(json['circulatingSupply']),
      totalSupply: _toDouble(json['totalSupply']),
      maxSupply: _toDouble(json['maxSupply']),
      // contract
      tokenId: json['tokenId']?.toString() ?? '',
      isCanonical: json['isCanonical'] is bool ? json['isCanonical'] : null,
      szDecimals: json['szDecimals'] is int ? json['szDecimals'] : null,
      weiDecimals: json['weiDecimals'] is int ? json['weiDecimals'] : null,
      evmContract: json['evmContract'] != null
          ? EvmContract.fromJson(json['evmContract'] as Map<String, dynamic>)
          : null,
      deployerTradingFeeShare: json['deployerTradingFeeShare']?.toString(),
      // perp
      maxLeverage: (json['maxLeverage'] ?? 0) is int
          ? (json['maxLeverage'] ?? 0)
          : (json['maxLeverage'] as num?)?.toInt() ?? 0,
      marginTableId: json['marginTableId'] != null ? (json['marginTableId'] as num).toInt() : null,
      growthMode: json['growthMode']?.toString() ?? '',
    );
  }

  factory TickerModel.fromVariational(Map<String, dynamic> json) {
    final openInterestObj = json['open_interest'];
    double totalOI = 0.0;
    if (openInterestObj is Map<String, dynamic>) {
      final longOI = _toDouble(openInterestObj['long_open_interest']);
      final shortOI = _toDouble(openInterestObj['short_open_interest']);
      totalOI = longOI + shortOI;
    }

    final tickerSym = json['ticker']?.toString() ?? json['symbol']?.toString() ?? '';

    return TickerModel(
      id: tickerSym,
      dex: 'Variational',
      symbol: tickerSym,
      fullSymbol: tickerSym,
      displayName: json['name']?.toString() ?? '',
      marketType: 'perp',
      isDelisted: false,
      iconUrl: '',
      cryptoCategory: '',
      lastPrice: _toDouble(json['mark_price']),
      change24hPct: _toDouble(json['total_cost_24h_pct']),
      funding8hPct: _toDouble(json['per_interval_funding_rate_pct']),
      volume24hUSD: _toDouble(json['volume_24h']),
      openInterestUSD: totalOI,
      maxLeverage: 0,
      growthMode: '',
    );
  }


  // Safe null-aware double parse
  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  /// Coin id for order book API path — always bare `symbol` (e.g. `XYZ100`, `BTC`).
  String get orderBookSymbol => symbol;

  /// Returns the dex query param for the order book API.
  /// - hyperliquid coins → null (no dex param, backend uses WebSocket)
  /// - all other dex coins (xyz, flx, etc.) → dex value (backend uses REST)
  String? get orderBookDex {
    if (dex.isEmpty || dex.toLowerCase() == 'hyperliquid') return null;
    return dex;
  }

  String get orderBookLabel {
    final d = orderBookDex;
    if (d != null) return '$d:$symbol';
    return symbol;
  }

  String get displaySymbol {
    String cleanSymbol = symbol.toUpperCase();
    
    // Always strip prefix like "XYZ :" if present
    if (cleanSymbol.contains(':')) {
      cleanSymbol = cleanSymbol.split(':').last.trim();
    }

    if (marketType == 'hip-3') return cleanSymbol;
    
    final suffix = marketType == 'spot' ? '/USDC' : '-USDC';
    
    // Avoid double suffixing
    if (cleanSymbol.endsWith('-USDC') || cleanSymbol.endsWith('/USDC')) {
      return cleanSymbol;
    }
    
    return '$cleanSymbol$suffix';
  }

  TickerModel copyWithPartial(Map<String, dynamic> p) {
    return TickerModel(
      id: id,
      dex: p['dex']?.toString() ?? dex,
      symbol: p['symbol']?.toString() ?? symbol,
      fullSymbol: p['fullSymbol']?.toString() ?? fullSymbol,
      displayName: p['displayName']?.toString() ?? displayName,
      marketType: p['marketType']?.toString() ?? marketType,
      source: p['source']?.toString() ?? source,
      isDelisted: p['isDelisted'] is bool ? p['isDelisted'] : isDelisted,
      iconUrl: p['iconUrl']?.toString() ?? iconUrl,
      cryptoCategory: p['cryptoCategory']?.toString() ?? cryptoCategory,
      updatedAt: p['updatedAt']?.toString() ?? updatedAt,
      createdAt: p['createdAt']?.toString() ?? createdAt,
      lastPrice: p.containsKey('lastPrice') ? _toDouble(p['lastPrice']) : lastPrice,
      markPx: p.containsKey('markPx') ? _toDouble(p['markPx']) : markPx,
      midPx: p.containsKey('midPx') ? _toDouble(p['midPx']) : midPx,
      oraclePx: p.containsKey('oraclePx') ? _toDouble(p['oraclePx']) : oraclePx,
      prevDayPx: p.containsKey('prevDayPx') ? _toDouble(p['prevDayPx']) : prevDayPx,
      premium: p.containsKey('premium') ? _toDouble(p['premium']) : premium,
      change24hPct: p.containsKey('change24hPct') ? _toDouble(p['change24hPct']) : change24hPct,
      funding8hPct: p.containsKey('funding8hPct') ? _toDouble(p['funding8hPct']) : funding8hPct,
      impactBidPx: p.containsKey('impactBidPx') ? _toDouble(p['impactBidPx']) : impactBidPx,
      impactAskPx: p.containsKey('impactAskPx') ? _toDouble(p['impactAskPx']) : impactAskPx,
      openInterest: p.containsKey('openInterest') ? _toDouble(p['openInterest']) : openInterest,
      openInterestUSD: p.containsKey('openInterestUSD') ? _toDouble(p['openInterestUSD']) : openInterestUSD,
      volume24hUSD: p.containsKey('volume24hUSD') ? _toDouble(p['volume24hUSD']) : volume24hUSD,
      dayBaseVlm: p.containsKey('dayBaseVlm') ? _toDouble(p['dayBaseVlm']) : dayBaseVlm,
      marketCapUSD: p.containsKey('marketCapUSD') ? _toDouble(p['marketCapUSD']) : marketCapUSD,
      circulatingSupply: p.containsKey('circulatingSupply') ? _toDouble(p['circulatingSupply']) : circulatingSupply,
      totalSupply: p.containsKey('totalSupply') ? _toDouble(p['totalSupply']) : totalSupply,
      maxSupply: p.containsKey('maxSupply') ? _toDouble(p['maxSupply']) : maxSupply,
      tokenId: p['tokenId']?.toString() ?? tokenId,
      isCanonical: p['isCanonical'] is bool ? p['isCanonical'] : isCanonical,
      szDecimals: p['szDecimals'] is int ? p['szDecimals'] : szDecimals,
      weiDecimals: p['weiDecimals'] is int ? p['weiDecimals'] : weiDecimals,
      evmContract: p.containsKey('evmContract')
          ? (p['evmContract'] != null ? EvmContract.fromJson(p['evmContract'] as Map<String, dynamic>) : null)
          : evmContract,
      deployerTradingFeeShare: p.containsKey('deployerTradingFeeShare')
          ? p['deployerTradingFeeShare']?.toString()
          : deployerTradingFeeShare,
      maxLeverage: p.containsKey('maxLeverage') && p['maxLeverage'] != null
          ? (p['maxLeverage'] as num).toInt()
          : maxLeverage,
      marginTableId: p.containsKey('marginTableId') ? p['marginTableId'] as int? : marginTableId,
      growthMode: p['growthMode']?.toString() ?? growthMode,
      tokenIndex: p.containsKey('tokenIndex') ? p['tokenIndex'] as int? : tokenIndex,
    );
  }
}

class EvmContract {
  final String address;
  final int evmExtraWeiDecimals;

  EvmContract({
    required this.address,
    required this.evmExtraWeiDecimals,
  });

  factory EvmContract.fromJson(Map<String, dynamic> json) {
    return EvmContract(
      address: json['address']?.toString() ?? '',
      evmExtraWeiDecimals: (json['evm_extra_wei_decimals'] ?? 0) is int
          ? (json['evm_extra_wei_decimals'] ?? 0)
          : (json['evm_extra_wei_decimals'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'evm_extra_wei_decimals': evmExtraWeiDecimals,
    };
  }
}

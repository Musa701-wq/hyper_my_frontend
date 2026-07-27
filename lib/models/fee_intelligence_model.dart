class FeeIntelligenceStats {
  final double total24h;
  final double total7d;
  final double change1d;
  final int activeProtocols;
  final int activeChains;

  FeeIntelligenceStats({
    required this.total24h,
    required this.total7d,
    required this.change1d,
    required this.activeProtocols,
    required this.activeChains,
  });

  factory FeeIntelligenceStats.fromJson(Map<String, dynamic> json) {
    return FeeIntelligenceStats(
      total24h: (json['total24h'] ?? 0.0).toDouble(),
      total7d: (json['total7d'] ?? 0.0).toDouble(),
      change1d: (json['change_1d'] ?? json['change1d'] ?? 0.0).toDouble(),
      activeProtocols: json['activeProtocols'] ?? 0,
      activeChains: json['activeChains'] ?? 0,
    );
  }
}

class FeeCategoryBreakdown {
  final String category;
  final double fees;

  FeeCategoryBreakdown({
    required this.category,
    required this.fees,
  });

  factory FeeCategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return FeeCategoryBreakdown(
      category: json['category'] ?? 'Other',
      fees: (json['fees'] ?? json['volume'] ?? 0.0).toDouble(),
    );
  }
}

class FeeTopProtocol {
  final String name;
  final String slug;
  final String? logo;
  final String category;
  final List<String> chains;
  final double fees24h;
  final double change1d;
  final double change7d;
  final double change30d;
  final double fees7d;
  final double fees30d;
  final double fees1y;
  final double feesAllTime;
  final List<String> children;
  final List<String> childrenSlugs;
  final String protocolType;
  final double annualized1y;
  final double average1y;

  FeeTopProtocol({
    required this.name,
    required this.slug,
    this.logo,
    required this.category,
    required this.chains,
    required this.fees24h,
    required this.change1d,
    required this.change7d,
    required this.change30d,
    required this.fees7d,
    required this.fees30d,
    required this.fees1y,
    required this.feesAllTime,
    required this.children,
    required this.childrenSlugs,
    required this.protocolType,
    required this.annualized1y,
    required this.average1y,
  });

  factory FeeTopProtocol.fromJson(Map<String, dynamic> json) {
    final metricsObj = json['metrics'];
    double fees24h = 0.0;
    double change1d = 0.0;
    double change7d = 0.0;
    double change30d = 0.0;
    double fees7d = 0.0;
    double fees30d = 0.0;
    double fees1y = 0.0;
    double feesAllTime = 0.0;
    double annualized1y = 0.0;
    double average1y = 0.0;

    if (metricsObj is Map<String, dynamic>) {
      fees24h = (metricsObj['total24h'] ?? metricsObj['total24H'] ?? 0.0).toDouble();
      change1d = (metricsObj['change1d'] ?? metricsObj['change_1d'] ?? 0.0).toDouble();
      change7d = (metricsObj['change7d'] ?? metricsObj['change_7d'] ?? 0.0).toDouble();
      change30d = (metricsObj['change30d'] ?? metricsObj['change_30d'] ?? 0.0).toDouble();
      fees7d = (metricsObj['total7d'] ?? metricsObj['total7D'] ?? 0.0).toDouble();
      fees30d = (metricsObj['total30d'] ?? metricsObj['total30D'] ?? 0.0).toDouble();
      fees1y = (metricsObj['total1y'] ?? metricsObj['total1Y'] ?? 0.0).toDouble();
      feesAllTime = (metricsObj['totalAllTime'] ?? metricsObj['totalAlltime'] ?? 0.0).toDouble();
      annualized1y = (metricsObj['annualized1y'] ?? metricsObj['annualized1Y'] ?? 0.0).toDouble();
      average1y = (metricsObj['average1y'] ?? metricsObj['average1Y'] ?? 0.0).toDouble();
    } else {
      fees24h = (json['fees24h'] ?? json['fees24H'] ?? json['volume24h'] ?? 0.0).toDouble();
      change1d = (json['change1d'] ?? json['change_1d'] ?? 0.0).toDouble();
      change7d = (json['change7d'] ?? json['change_7d'] ?? 0.0).toDouble();
      change30d = (json['change30d'] ?? json['change_30d'] ?? 0.0).toDouble();
      fees7d = (json['fees7d'] ?? json['fees7D'] ?? 0.0).toDouble();
      fees30d = (json['fees30d'] ?? json['fees30D'] ?? 0.0).toDouble();
      fees1y = (json['fees1y'] ?? json['fees1Y'] ?? 0.0).toDouble();
      feesAllTime = (json['feesAllTime'] ?? json['feesAlltime'] ?? 0.0).toDouble();
    }

    return FeeTopProtocol(
      name: json['name'] ?? json['displayName'] ?? '',
      slug: json['slug'] ?? '',
      logo: json['logo'],
      category: json['category'] ?? '',
      chains: (json['chains'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      fees24h: fees24h,
      change1d: change1d,
      change7d: change7d,
      change30d: change30d,
      fees7d: fees7d,
      fees30d: fees30d,
      fees1y: fees1y,
      feesAllTime: feesAllTime,
      children: (json['children'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      childrenSlugs: (json['childrenSlugs'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      protocolType: json['protocolType'] ?? 'protocol',
      annualized1y: annualized1y,
      average1y: average1y,
    );
  }
}

class FeeProtocolsPaginatedResponse {
  final List<FeeTopProtocol> protocols;
  final int page;
  final int limit;
  final int total;
  final int pages;

  FeeProtocolsPaginatedResponse({
    required this.protocols,
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory FeeProtocolsPaginatedResponse.fromJson(Map<String, dynamic> json) {
    final list = json['protocols'] as List? ?? [];
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};

    return FeeProtocolsPaginatedResponse(
      protocols: list.map((e) => FeeTopProtocol.fromJson(e as Map<String, dynamic>)).toList(),
      page: pagination['page'] as int? ?? 1,
      limit: pagination['limit'] as int? ?? 20,
      total: pagination['total'] as int? ?? 0,
      pages: pagination['pages'] as int? ?? 1,
    );
  }
}

class FeeIntelligenceDashboard {
  final FeeIntelligenceStats stats;
  final List<FeeCategoryBreakdown> categoryBreakdown;
  final List<FeeTopProtocol> topProtocols;

  FeeIntelligenceDashboard({
    required this.stats,
    required this.categoryBreakdown,
    required this.topProtocols,
  });

  factory FeeIntelligenceDashboard.fromJson(Map<String, dynamic> json) {
    final statsData = json['stats'] != null 
        ? FeeIntelligenceStats.fromJson(json['stats'] as Map<String, dynamic>)
        : FeeIntelligenceStats(total24h: 0, total7d: 0, change1d: 0, activeProtocols: 0, activeChains: 0);

    final catList = json['categoryBreakdown'] as List<dynamic>? ?? [];
    final categories = catList.map((e) => FeeCategoryBreakdown.fromJson(e as Map<String, dynamic>)).toList();

    final protList = json['topProtocols'] as List<dynamic>? ?? [];
    final protocols = protList.map((e) => FeeTopProtocol.fromJson(e as Map<String, dynamic>)).toList();

    return FeeIntelligenceDashboard(
      stats: statsData,
      categoryBreakdown: categories,
      topProtocols: protocols,
    );
  }
}

class FeeHistoryPoint {
  final DateTime date;
  final double value;

  FeeHistoryPoint({
    required this.date,
    required this.value,
  });
}

class FeeHistoryData {
  final List<FeeHistoryPoint> points;

  FeeHistoryData({required this.points});

  factory FeeHistoryData.fromJson(Map<String, dynamic> json) {
    final labels = json['labels'] as List<dynamic>? ?? [];
    final data = json['data'] as List<dynamic>? ?? [];
    final List<FeeHistoryPoint> historyPoints = [];

    final length = labels.length < data.length ? labels.length : data.length;
    for (int i = 0; i < length; i++) {
      final ts = (labels[i] as num).toInt();
      final val = (data[i] as num).toDouble();
      historyPoints.add(FeeHistoryPoint(
        date: DateTime.fromMillisecondsSinceEpoch(ts),
        value: val,
      ));
    }
    return FeeHistoryData(points: historyPoints);
  }
}

class FeeCompareResponse {
  final List<DateTime> labels;
  final Map<String, List<double>> series;
  final List<FeeTopProtocol> protocols;

  FeeCompareResponse({
    required this.labels,
    required this.series,
    required this.protocols,
  });

  factory FeeCompareResponse.fromJson(Map<String, dynamic> json) {
    final labelsList = json['labels'] as List<dynamic>? ?? [];
    final labels = labelsList.map((e) {
      final ts = (e as num).toInt();
      return DateTime.fromMillisecondsSinceEpoch(ts);
    }).toList();

    final seriesMap = json['series'] as Map<String, dynamic>? ?? {};
    final Map<String, List<double>> series = {};
    seriesMap.forEach((key, value) {
      if (value is List) {
        series[key] = value.map((e) => (e as num).toDouble()).toList();
      }
    });

    final protocolsList = json['protocols'] as List<dynamic>? ?? [];
    final protocols = protocolsList.map((e) => FeeTopProtocol.fromJson(e as Map<String, dynamic>)).toList();

    return FeeCompareResponse(
      labels: labels,
      series: series,
      protocols: protocols,
    );
  }
}

class TopByFeesProtocol {
  final String displayName;
  final String? logo;
  final FeeTopProtocolMetrics metrics;

  TopByFeesProtocol({
    required this.displayName,
    this.logo,
    required this.metrics,
  });

  factory TopByFeesProtocol.fromJson(Map<String, dynamic> json) {
    return TopByFeesProtocol(
      displayName: json['displayName'] ?? '',
      logo: json['logo'],
      metrics: FeeTopProtocolMetrics.fromJson(json['metrics'] ?? {}),
    );
  }
}

class FeeTopProtocolMetrics {
  final double total24h;
  final double total7d;
  final double total30d;
  final double total1y;
  final double totalAllTime;
  final double change1d;
  final double change7d;
  final double change30d;
  final double annualized1y;
  final double average1y;

  FeeTopProtocolMetrics({
    required this.total24h,
    required this.total7d,
    required this.total30d,
    required this.total1y,
    required this.totalAllTime,
    required this.change1d,
    required this.change7d,
    required this.change30d,
    required this.annualized1y,
    required this.average1y,
  });

  factory FeeTopProtocolMetrics.fromJson(Map<String, dynamic> json) {
    return FeeTopProtocolMetrics(
      total24h: (json['total24h'] ?? 0.0).toDouble(),
      total7d: (json['total7d'] ?? 0.0).toDouble(),
      total30d: (json['total30d'] ?? 0.0).toDouble(),
      total1y: (json['total1y'] ?? 0.0).toDouble(),
      totalAllTime: (json['totalAllTime'] ?? 0.0).toDouble(),
      change1d: (json['change1d'] ?? 0.0).toDouble(),
      change7d: (json['change7d'] ?? 0.0).toDouble(),
      change30d: (json['change30d'] ?? 0.0).toDouble(),
      annualized1y: (json['annualized1y'] ?? 0.0).toDouble(),
      average1y: (json['average1y'] ?? 0.0).toDouble(),
    );
  }
}

class DexChainMetrics {
  final String chain;
  final double totalVolume24h;
  final double totalVolume7d;
  final double totalVolume30d;
  final double totalVolume1y;
  final int protocolCount;

  DexChainMetrics({
    required this.chain,
    required this.totalVolume24h,
    required this.totalVolume7d,
    required this.totalVolume30d,
    required this.totalVolume1y,
    required this.protocolCount,
  });

  factory DexChainMetrics.fromJson(Map<String, dynamic> json) {
    return DexChainMetrics(
      chain: json['chain'] ?? '',
      totalVolume24h: (json['totalVolume24h'] ?? 0.0).toDouble(),
      totalVolume7d: (json['totalVolume7d'] ?? 0.0).toDouble(),
      totalVolume30d: (json['totalVolume30d'] ?? 0.0).toDouble(),
      totalVolume1y: (json['totalVolume1y'] ?? 0.0).toDouble(),
      protocolCount: json['protocolCount'] ?? 0,
    );
  }
}

class DexChainDetailResponse {
  final String chain;
  final int totalProtocols;
  final double totalVolume24h;
  final List<FeeTopProtocol> protocols;

  DexChainDetailResponse({
    required this.chain,
    required this.totalProtocols,
    required this.totalVolume24h,
    required this.protocols,
  });

  factory DexChainDetailResponse.fromJson(Map<String, dynamic> json) {
    final list = json['protocols'] as List? ?? [];
    return DexChainDetailResponse(
      chain: json['chain'] ?? '',
      totalProtocols: json['totalProtocols'] ?? 0,
      totalVolume24h: (json['totalVolume24h'] ?? 0.0).toDouble(),
      protocols: list.map((e) => FeeTopProtocol.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class DexProtocolDetailResponse {
  final FeeTopProtocol protocol;
  final FeeHistoryData history;

  DexProtocolDetailResponse({
    required this.protocol,
    required this.history,
  });

  factory DexProtocolDetailResponse.fromJson(Map<String, dynamic> json) {
    return DexProtocolDetailResponse(
      protocol: FeeTopProtocol.fromJson(json['protocol'] ?? {}),
      history: FeeHistoryData.fromJson(json['history'] ?? {}),
    );
  }
}


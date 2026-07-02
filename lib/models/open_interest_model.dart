class OpenInterestProtocol {
  final String name;
  final String displayName;
  final double total24h;
  final double total7d;
  final double total30d;
  final double change1d;
  final double change7d;
  final double change1m;
  final List<String> chains;
  final String category;
  final String logo;
  final String slug;

  OpenInterestProtocol({
    required this.name,
    required this.displayName,
    required this.total24h,
    required this.total7d,
    required this.total30d,
    required this.change1d,
    required this.change7d,
    required this.change1m,
    required this.chains,
    required this.category,
    required this.logo,
    required this.slug,
  });

  factory OpenInterestProtocol.fromJson(Map<String, dynamic> json) {
    return OpenInterestProtocol(
      name: json['name'] as String? ?? '',
      displayName: json['displayName'] as String? ?? json['name'] as String? ?? '',
      total24h: (json['total24h'] as num?)?.toDouble() ?? 0.0,
      total7d: (json['total7d'] as num?)?.toDouble() ?? 0.0,
      total30d: (json['total30d'] as num?)?.toDouble() ?? 0.0,
      change1d: (json['change_1d'] as num?)?.toDouble() ?? 0.0,
      change7d: (json['change_7d'] as num?)?.toDouble() ?? 0.0,
      change1m: (json['change_1m'] as num?)?.toDouble() ?? 0.0,
      chains: (json['chains'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      category: json['category'] as String? ?? 'Unknown',
      logo: json['logo'] as String? ?? '',
      slug: json['slug'] as String? ?? json['name']?.toString().toLowerCase() ?? '',
    );
  }
}

class OpenInterestChain {
  final String chain;
  final double totalOI;
  final int protocolCount;
  final List<String> protocols;
  final String chainIconUrl;

  OpenInterestChain({
    required this.chain,
    required this.totalOI,
    required this.protocolCount,
    required this.protocols,
    required this.chainIconUrl,
  });

  factory OpenInterestChain.fromJson(Map<String, dynamic> json) {
    return OpenInterestChain(
      chain: json['chain'] as String? ?? '',
      totalOI: (json['totalOI'] as num?)?.toDouble() ?? 0.0,
      protocolCount: (json['protocolCount'] as num?)?.toInt() ?? 0,
      protocols: (json['protocols'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      chainIconUrl: json['chainIconUrl'] as String? ?? '',
    );
  }
}

class OpenInterestSummary {
  final int totalProtocols;
  final int activeProtocols;
  final int growingProtocols;
  final double totalOI;
  final double activeOI;
  final List<OpenInterestTop5Protocol> top5;
  final List<OpenInterestCategoryBreakdown> categoryBreakdown;

  OpenInterestSummary({
    required this.totalProtocols,
    required this.activeProtocols,
    required this.growingProtocols,
    required this.totalOI,
    required this.activeOI,
    required this.top5,
    required this.categoryBreakdown,
  });

  factory OpenInterestSummary.fromJson(Map<String, dynamic> json) {
    return OpenInterestSummary(
      totalProtocols: (json['totalProtocols'] as num?)?.toInt() ?? 0,
      activeProtocols: (json['activeProtocols'] as num?)?.toInt() ?? 0,
      growingProtocols: (json['growingProtocols'] as num?)?.toInt() ?? 0,
      totalOI: (json['totalOI'] as num?)?.toDouble() ?? 0.0,
      activeOI: (json['activeOI'] as num?)?.toDouble() ?? 0.0,
      top5: (json['top5'] as List<dynamic>?)
              ?.map((e) => OpenInterestTop5Protocol.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      categoryBreakdown: (json['categoryBreakdown'] as List<dynamic>?)
              ?.map((e) => OpenInterestCategoryBreakdown.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
    );
  }
}

class OpenInterestTop5Protocol {
  final String name;
  final double total24h;
  final double change7d;

  OpenInterestTop5Protocol({
    required this.name,
    required this.total24h,
    required this.change7d,
  });

  factory OpenInterestTop5Protocol.fromJson(Map<String, dynamic> json) {
    return OpenInterestTop5Protocol(
      name: json['name'] as String? ?? '',
      total24h: (json['total24h'] as num?)?.toDouble() ?? 0.0,
      change7d: (json['change_7d'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class OpenInterestCategoryBreakdown {
  final String category;
  final double totalOI;
  final int protocolCount;

  OpenInterestCategoryBreakdown({
    required this.category,
    required this.totalOI,
    required this.protocolCount,
  });

  factory OpenInterestCategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return OpenInterestCategoryBreakdown(
      category: json['category'] as String? ?? '',
      totalOI: (json['totalOI'] as num?)?.toDouble() ?? 0.0,
      protocolCount: (json['protocolCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class OpenInterestListResponse {
  final List<OpenInterestProtocol> protocols;
  final OpenInterestSummaryStats summary;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  OpenInterestListResponse({
    required this.protocols,
    required this.summary,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory OpenInterestListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final protocolsJson = data['protocols'] as List<dynamic>? ?? [];
    final summaryJson = data['summary'] as Map<String, dynamic>? ?? {};

    return OpenInterestListResponse(
      protocols: protocolsJson.map((e) => OpenInterestProtocol.fromJson(e as Map<String, dynamic>)).toList(),
      summary: OpenInterestSummaryStats.fromJson(summaryJson),
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

class OpenInterestSummaryStats {
  final double totalOI;
  final int totalProtocols;
  final String topProtocol;
  final double averageOI;
  final double maxOI;
  final double minOI;

  OpenInterestSummaryStats({
    required this.totalOI,
    required this.totalProtocols,
    required this.topProtocol,
    required this.averageOI,
    required this.maxOI,
    required this.minOI,
  });

  factory OpenInterestSummaryStats.fromJson(Map<String, dynamic> json) {
    return OpenInterestSummaryStats(
      totalOI: (json['totalOI'] as num?)?.toDouble() ?? 0.0,
      totalProtocols: (json['totalProtocols'] as num?)?.toInt() ?? 0,
      topProtocol: json['topProtocol'] as String? ?? '',
      averageOI: (json['averageOI'] as num?)?.toDouble() ?? 0.0,
      maxOI: (json['maxOI'] as num?)?.toDouble() ?? 0.0,
      minOI: (json['minOI'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

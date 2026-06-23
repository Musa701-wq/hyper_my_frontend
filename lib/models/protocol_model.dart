import 'package:intl/intl.dart';

class TvlPoint {
  final DateTime date;
  final double value;

  TvlPoint({required this.date, required this.value});

  factory TvlPoint.fromJson(Map<String, dynamic> json) {
    return TvlPoint(
      date: DateTime.fromMillisecondsSinceEpoch((json['date'] as num).toInt() * 1000),
      value: (json['totalLiquidityUSD'] as num? ?? 0).toDouble(),
    );
  }
}

class Protocol {
  final String name;
  final String slug;
  final String logo;
  final double tvl;
  final String category;
  final String? division;
  final String type; // core, ecosystem, other
  final int? rank;
  final double? change1h;
  final double? change1d;
  final double? change7d;

  Protocol({
    required this.name,
    required this.slug,
    required this.logo,
    required this.tvl,
    required this.category,
    this.division,
    required this.type,
    this.rank,
    this.change1h,
    this.change1d,
    this.change7d,
  });

  factory Protocol.fromJson(Map<String, dynamic> json, {int? index}) {
    return Protocol(
      name: json['name'] as String? ?? 'Unknown',
      slug: json['slug'] as String? ?? '',
      logo: json['logo'] as String? ?? '',
      tvl: (json['tvl'] as num? ?? 0).toDouble(),
      category: json['category'] as String? ?? 'N/A',
      division: json['division'] as String?,
      type: json['type'] as String? ?? 'other',
      rank: index != null ? index + 1 : null,
      change1h: (json['change_1h'] as num?)?.toDouble(),
      change1d: (json['change_1d'] as num?)?.toDouble(),
      change7d: (json['change_7d'] as num?)?.toDouble(),
    );
  }

  String get formattedTvl {
    if (tvl >= 1e9) {
      return '\$${(tvl / 1e9).toStringAsFixed(2)}B';
    } else if (tvl >= 1e6) {
      return '\$${(tvl / 1e6).toStringAsFixed(2)}M';
    } else if (tvl >= 1e3) {
      return '\$${(tvl / 1e3).toStringAsFixed(2)}K';
    }
    return '\$${tvl.toStringAsFixed(0)}';
  }

  String get fullTvl {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return formatter.format(tvl);
  }
}

class ProtocolDetail {
  final String id;
  final String name;
  final String slug;
  final String logo;
  final double tvl;
  final double change1h;
  final double change1d;
  final double change7d;
  final String category;
  final String description;
  final List<String> chains;
  final String url;
  final String? twitter;
  final Map<String, double> chainTvls;
  final double? mcap;
  final String? division;
  final String type;
  final List<TvlPoint> historicalTvl;

  ProtocolDetail({
    required this.id,
    required this.name,
    required this.slug,
    required this.logo,
    required this.tvl,
    required this.change1h,
    required this.change1d,
    required this.change7d,
    required this.category,
    required this.description,
    required this.chains,
    required this.url,
    this.twitter,
    required this.chainTvls,
    this.mcap,
    this.division,
    required this.type,
    required this.historicalTvl,
  });

  factory ProtocolDetail.fromJson(Map<String, dynamic> json) {
    // Robust TVL and historical data parsing
    double currentTvl = 0;
    List<TvlPoint> historicalTvl = [];
    
    final tvlData = json['tvl'];
    if (tvlData is List) {
      historicalTvl = tvlData.map((e) => TvlPoint.fromJson(e)).toList();
      if (historicalTvl.isNotEmpty) {
        currentTvl = historicalTvl.last.value;
      }
    } else if (tvlData is num) {
      currentTvl = tvlData.toDouble();
    }

    // Parse chainTvls
    final rawChainTvls = json['chainTvls'] as Map<String, dynamic>? ?? {};
    final chainTvls = <String, double>{};
    rawChainTvls.forEach((key, value) {
      chainTvls[key] = (value as num? ?? 0).toDouble();
    });

    // Parse chains
    final rawChains = json['chains'] as List<dynamic>? ?? [];
    final chains = rawChains.map((e) => e.toString()).toList();

    return ProtocolDetail(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Unknown',
      slug: json['slug'] as String? ?? '',
      logo: json['logo'] as String? ?? '',
      tvl: currentTvl,
      change1h: (json['change_1h'] as num? ?? 0).toDouble(),
      change1d: (json['change_1d'] as num? ?? 0).toDouble(),
      change7d: (json['change_7d'] as num? ?? 0).toDouble(),
      category: json['category'] as String? ?? 'N/A',
      description: json['description'] as String? ?? '',
      chains: chains,
      url: json['url'] as String? ?? '',
      twitter: json['twitter'] as String?,
      chainTvls: chainTvls,
      mcap: (json['mcap'] as num?)?.toDouble(),
      division: json['division'] as String?,
      type: json['type'] as String? ?? 'other',
      historicalTvl: historicalTvl,
    );
  }

  String get fullTvl {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return formatter.format(tvl);
  }

  String get formattedTvl {
    if (tvl >= 1e9) return '\$${(tvl / 1e9).toStringAsFixed(2)}B';
    if (tvl >= 1e6) return '\$${(tvl / 1e6).toStringAsFixed(2)}M';
    if (tvl >= 1e3) return '\$${(tvl / 1e3).toStringAsFixed(2)}K';
    return '\$${tvl.toStringAsFixed(0)}';
  }

  String fmtChange(double val) {
    final sign = val >= 0 ? '+' : '';
    return '$sign${val.toStringAsFixed(2)}%';
  }

  String fmtChainTvl(double val) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return formatter.format(val);
  }

  double? get mcapTvlRatio => (mcap != null && tvl > 0) ? mcap! / tvl : null;
}

class CategoryDistribution {
  final String category;
  final double tvl;
  final double percentage;

  CategoryDistribution({
    required this.category,
    required this.tvl,
    required this.percentage,
  });

  factory CategoryDistribution.fromJson(Map<String, dynamic> json, {double? totalTvl}) {
    final tvl = (json['tvl'] as num? ?? 0).toDouble();
    return CategoryDistribution(
      category: json['category'] as String? ?? 'Unknown',
      tvl: tvl,
      percentage: (totalTvl != null && totalTvl > 0) ? (tvl / totalTvl) * 100 : 0.0,
    );
  }

  String get formattedTvl {
    if (tvl >= 1e9) return '\$${(tvl / 1e9).toStringAsFixed(2)}B';
    if (tvl >= 1e6) return '\$${(tvl / 1e6).toStringAsFixed(2)}M';
    if (tvl >= 1e3) return '\$${(tvl / 1e3).toStringAsFixed(2)}K';
    return '\$${tvl.toStringAsFixed(0)}';
  }

  String get fullTvl {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return formatter.format(tvl);
  }
}

class ChainTvl {
  final String chain;
  final double tvl;

  ChainTvl({required this.chain, required this.tvl});

  factory ChainTvl.fromJson(Map<String, dynamic> json) {
    return ChainTvl(
      chain: json['chain'] as String? ?? 'Unknown',
      tvl: (json['tvl'] as num? ?? 0).toDouble(),
    );
  }

  String get formattedTvl {
    if (tvl >= 1e9) return '\$${(tvl / 1e9).toStringAsFixed(2)}B';
    if (tvl >= 1e6) return '\$${(tvl / 1e6).toStringAsFixed(2)}M';
    if (tvl >= 1e3) return '\$${(tvl / 1e3).toStringAsFixed(2)}K';
    return '\$${tvl.toStringAsFixed(0)}';
  }

  String get fullTvl {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return formatter.format(tvl);
  }
}
class ChainFocusProject {
  final String name;
  final double tvl;
  final double pct;

  ChainFocusProject({
    required this.name,
    required this.tvl,
    required this.pct,
  });

  factory ChainFocusProject.fromJson(Map<String, dynamic> json) {
    return ChainFocusProject(
      name: json['name'] as String? ?? 'Unknown',
      tvl: (json['tvl'] as num? ?? 0).toDouble(),
      pct: (json['projectPct'] as num? ?? json['pct'] as num? ?? 0).toDouble(),
    );
  }

  String get fullTvl {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return formatter.format(tvl);
  }
}

class ChainFocus {
  final String chain;
  final double totalTvl;
  final double pct;
  final int count;
  final List<ChainFocusProject> projects;

  ChainFocus({
    required this.chain,
    required this.totalTvl,
    required this.pct,
    required this.count,
    required this.projects,
  });

  factory ChainFocus.fromJson(Map<String, dynamic> json) {
    var rawProjects = json['projects'] as List<dynamic>? ?? [];
    return ChainFocus(
      chain: json['chain'] as String? ?? 'Unknown',
      totalTvl: (json['totalTvl'] as num? ?? 0).toDouble(),
      pct: (json['pct'] as num? ?? 0).toDouble(),
      count: (json['count'] as num? ?? 0).toInt(),
      projects: rawProjects.map((e) => ChainFocusProject.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

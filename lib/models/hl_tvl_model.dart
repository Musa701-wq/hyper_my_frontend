import 'package:intl/intl.dart';

class HlTvlSummary {
  final int lastUpdated;
  final HlMetadata metadata;
  final double marketCap;
  final HlTvlStats tvl;
  final List<HlChainBreakdown> chainBreakdown;
  final List<HlEcosystemItem> ecosystem;

  HlTvlSummary({
    required this.lastUpdated,
    required this.metadata,
    required this.marketCap,
    required this.tvl,
    required this.chainBreakdown,
    required this.ecosystem,
  });

  factory HlTvlSummary.fromJson(Map<String, dynamic> json) {
    return HlTvlSummary(
      lastUpdated: (json['lastUpdated'] as num?)?.toInt() ?? 0,
      metadata: HlMetadata.fromJson(json['metadata'] as Map<String, dynamic>? ?? {}),
      marketCap: (json['marketCap'] as num?)?.toDouble() ?? 0,
      tvl: HlTvlStats.fromJson(json['tvl'] as Map<String, dynamic>? ?? {}),
      chainBreakdown: (json['chainBreakdown'] as List<dynamic>? ?? [])
          .map((e) => HlChainBreakdown.fromJson(e as Map<String, dynamic>))
          .toList(),
      ecosystem: (json['ecosystem'] as List<dynamic>? ?? [])
          .map((e) => HlEcosystemItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class HlMetadata {
  final String name;
  final String description;
  final String logo;
  final String twitter;
  final String url;

  HlMetadata({
    required this.name,
    required this.description,
    required this.logo,
    required this.twitter,
    required this.url,
  });

  factory HlMetadata.fromJson(Map<String, dynamic> json) {
    return HlMetadata(
      name: json['name'] as String? ?? 'Hyperliquid',
      description: json['description'] as String? ?? '',
      logo: json['logo'] as String? ?? '',
      twitter: json['twitter'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }
}

class HlTvlStats {
  final double total;
  final double ath;
  final int athDate;
  final double change24h;
  final double change7d;

  HlTvlStats({
    required this.total,
    required this.ath,
    required this.athDate,
    required this.change24h,
    required this.change7d,
  });

  factory HlTvlStats.fromJson(Map<String, dynamic> json) {
    return HlTvlStats(
      total: (json['total'] as num?)?.toDouble() ?? 0,
      ath: (json['ath'] as num?)?.toDouble() ?? 0,
      athDate: (json['athDate'] as num?)?.toInt() ?? 0,
      change24h: (json['change_24h'] as num?)?.toDouble() ?? 0,
      change7d: (json['change_7d'] as num?)?.toDouble() ?? 0,
    );
  }
}

class HlChainBreakdown {
  final String name;
  final double value;
  final double percentage;

  HlChainBreakdown({
    required this.name,
    required this.value,
    required this.percentage,
  });

  factory HlChainBreakdown.fromJson(Map<String, dynamic> json) {
    return HlChainBreakdown(
      name: json['name'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
    );
  }
}

class HlEcosystemItem {
  final String slug;
  final String name;

  HlEcosystemItem({required this.slug, required this.name});

  factory HlEcosystemItem.fromJson(Map<String, dynamic> json) {
    return HlEcosystemItem(
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class HlTvlMetrics {
  final int lastUpdated;
  final double currentTvl;
  final double athTvl;
  final int athDate;
  final double drawdown;
  final double? change30d;
  final double? change90d;
  final double? change1y;

  HlTvlMetrics({
    required this.lastUpdated,
    required this.currentTvl,
    required this.athTvl,
    required this.athDate,
    required this.drawdown,
    this.change30d,
    this.change90d,
    this.change1y,
  });

  factory HlTvlMetrics.fromJson(Map<String, dynamic> json) {
    return HlTvlMetrics(
      lastUpdated: (json['lastUpdated'] as num?)?.toInt() ?? 0,
      currentTvl: (json['currentTvl'] as num?)?.toDouble() ?? 0,
      athTvl: (json['athTvl'] as num?)?.toDouble() ?? 0,
      athDate: (json['athDate'] as num?)?.toInt() ?? 0,
      drawdown: (json['drawdown'] as num?)?.toDouble() ?? 0,
      change30d: (json['change_30d'] as num?)?.toDouble(),
      change90d: (json['change_90d'] as num?)?.toDouble(),
      change1y: (json['change_1y'] as num?)?.toDouble(),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────
String fmtTvl(double v) {
  if (v >= 1e9) return '\$${(v / 1e9).toStringAsFixed(2)}B';
  if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(2)}M';
  if (v >= 1e3) return '\$${(v / 1e3).toStringAsFixed(1)}K';
  return '\$${v.toStringAsFixed(0)}';
}

String fmtDate(int unixSec) {
  final dt = DateTime.fromMillisecondsSinceEpoch(unixSec * 1000);
  return DateFormat('MMM d, yyyy').format(dt);
}

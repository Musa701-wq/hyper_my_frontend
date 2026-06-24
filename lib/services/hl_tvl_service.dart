import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/hl_tvl_model.dart';
import '../utils/app_config.dart';

class HlTvlService {
  String get _base => AppConfig.baseUrl; // coingecko.renderonnodes.com

  Future<HlTvlSummary> fetchSummary() async {
    final res = await http
        .get(Uri.parse('$_base/api/v1/hyperliquid/summary'))
        .timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      return HlTvlSummary.fromJson(json.decode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to load Hyperliquid TVL summary (${res.statusCode})');
  }

  Future<HlTvlMetrics> fetchMetrics() async {
    final res = await http
        .get(Uri.parse('$_base/api/v1/hyperliquid/metrics'))
        .timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      return HlTvlMetrics.fromJson(json.decode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to load Hyperliquid TVL metrics (${res.statusCode})');
  }

  Future<HlTvlHistory> fetchHistory({String range = 'all'}) async {
    final res = await http
        .get(Uri.parse('$_base/api/v1/hyperliquid/tvl?range=$range&interval=daily'))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      return HlTvlHistory.fromJson(json.decode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to load TVL history (${res.statusCode})');
  }

  Future<HlChainsHistory> fetchChainsHistory({String range = 'all'}) async {
    final res = await http
        .get(Uri.parse('$_base/api/v1/hyperliquid/chains?range=$range&interval=daily'))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      return HlChainsHistory.fromJson(json.decode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to load Chains TVL history (${res.statusCode})');
  }
}

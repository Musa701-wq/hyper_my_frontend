import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/fee_intelligence_model.dart';
import '../utils/app_config.dart';

class FeeIntelligenceService {
  String get _baseUrl => AppConfig.baseUrl;

  String _getPrefix(bool isRevenue, [String? dataType]) {
    if (dataType != null) return dataType;
    return isRevenue ? 'revenue' : 'fees';
  }

  Future<FeeIntelligenceDashboard> fetchDashboard({bool isRevenue = false, String? dataType}) async {
    final prefix = _getPrefix(isRevenue, dataType);
    final uri = Uri.parse('$_baseUrl/api/v1/$prefix/dashboard');
    debugPrint('FeeIntelligenceService: GET $uri');
    
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        return FeeIntelligenceDashboard.fromJson(decoded);
      }
      throw Exception('Unexpected dashboard response format');
    }
    throw Exception('Failed to load dashboard stats (${response.statusCode})');
  }

  Future<FeeHistoryData> fetchHistory({String range = '90d', bool isRevenue = false, String? dataType}) async {
    final prefix = _getPrefix(isRevenue, dataType);
    final uri = Uri.parse('$_baseUrl/api/v1/$prefix/history?range=$range');
    debugPrint('FeeIntelligenceService: GET $uri');

    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        return FeeHistoryData.fromJson(decoded);
      }
      throw Exception('Unexpected history response format');
    }
    throw Exception('Failed to load history chart (${response.statusCode})');
  }

  String _mapSortBy(String sortBy, String prefix) {
    switch (sortBy) {
      case 'fees24h':
        if (prefix == 'dexs') return 'volume';
        if (prefix == 'revenue') return 'revenue';
        if (prefix == 'holders-revenue') return 'revenue';
        return 'fees';
      case 'change_1d':
      case 'change1d':
        return 'change1d';
      case 'change_7d':
      case 'change7d':
        return 'change7d';
      case 'fees7d':
        return 'total7d';
      case 'fees30d':
        return 'total30d';
      case 'fees1y':
        return 'total1y';
      case 'feesAllTime':
        return 'totalAllTime';
      default:
        return sortBy;
    }
  }

  Future<List<FeeTopProtocol>> fetchProtocols({int limit = 15, bool isRevenue = false, String? dataType}) async {
    final prefix = _getPrefix(isRevenue, dataType);
    final sortBy = _mapSortBy('fees24h', prefix);
    final uri = Uri.parse('$_baseUrl/api/v1/$prefix/protocols?limit=$limit&sortBy=$sortBy&sortOrder=desc');
    debugPrint('FeeIntelligenceService: GET $uri');

    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic> && decoded['protocols'] is List) {
        final list = decoded['protocols'] as List;
        return list.map((e) => FeeTopProtocol.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Unexpected protocols response format');
    }
    throw Exception('Failed to load protocols leaderboard (${response.statusCode})');
  }

  Future<FeeProtocolsPaginatedResponse> fetchProtocolsPaginated({
    int page = 1,
    int limit = 20,
    required String sortBy,
    String sortOrder = 'desc',
    String? search,
    String? category,
    String? dataType, // Query parameter filter
    bool isRevenue = false,
    String? customPrefix, // Path prefix override ('fees', 'revenue', or 'holders-revenue')
  }) async {
    final prefix = customPrefix ?? _getPrefix(isRevenue);
    final mappedSortBy = _mapSortBy(sortBy, prefix);
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'sortBy': mappedSortBy,
      'sortOrder': sortOrder,
    };

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (category != null && category.trim().isNotEmpty && category != 'All' && category != 'All Categories') {
      queryParams['category'] = category.trim();
    }
    if (dataType != null && dataType.trim().isNotEmpty) {
      queryParams['dataType'] = dataType.trim();
    }

    final query = Uri(queryParameters: queryParams).query;
    final uri = Uri.parse('$_baseUrl/api/v1/$prefix/protocols?$query');
    debugPrint('FeeIntelligenceService: GET $uri');

    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        return FeeProtocolsPaginatedResponse.fromJson(decoded);
      }
      throw Exception('Unexpected protocols response format');
    }
    throw Exception('Failed to load protocols explorer (${response.statusCode})');
  }

  Future<FeeCompareResponse> fetchCompare(List<String> slugs, {String range = '90d', bool isRevenue = false, String? dataType}) async {
    final prefix = _getPrefix(isRevenue, dataType);
    final uri = Uri.parse('$_baseUrl/api/v1/$prefix/compare');
    debugPrint('FeeIntelligenceService: POST $uri with slugs: $slugs, range: $range');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'slugs': slugs,
        'range': range,
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        return FeeCompareResponse.fromJson(decoded);
      }
      throw Exception('Unexpected compare response format');
    }
    throw Exception('Failed to load comparison data (${response.statusCode})');
  }

  Future<List<TopByFeesProtocol>> fetchTopByFees({bool isRevenue = false, String? dataType}) async {
    final prefix = _getPrefix(isRevenue, dataType);
    final pathSuffix = (prefix == 'revenue' || prefix == 'holders-revenue') ? 'top-by-revenue' : 'top-by-fees';
    final uri = Uri.parse('$_baseUrl/api/v1/$prefix/$pathSuffix');
    debugPrint('FeeIntelligenceService: GET $uri');

    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List) {
        return decoded.map((e) => TopByFeesProtocol.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Unexpected response format');
    }
    throw Exception('Failed to load top protocols (${response.statusCode})');
  }

  Future<List<FeeTopProtocol>> searchDexs(String query) async {
    final uri = Uri.parse('$_baseUrl/api/v1/dexs/search?q=${Uri.encodeComponent(query)}');
    debugPrint('FeeIntelligenceService: GET $uri');

    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List) {
        return decoded.map((e) => FeeTopProtocol.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Unexpected search response format');
    }
    throw Exception('Failed to search DEXs (${response.statusCode})');
  }

  Future<DexProtocolDetailResponse> fetchProtocolDetail(String slug, {String range = '90d'}) async {
    final uri = Uri.parse('$_baseUrl/api/v1/dexs/protocols/${Uri.encodeComponent(slug)}?range=$range');
    debugPrint('FeeIntelligenceService: GET $uri');

    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        return DexProtocolDetailResponse.fromJson(decoded);
      }
      throw Exception('Unexpected protocol detail response format');
    }
    throw Exception('Failed to load protocol details (${response.statusCode})');
  }

  Future<List<DexChainMetrics>> fetchChainsList() async {
    final uri = Uri.parse('$_baseUrl/api/v1/dexs/chains');
    debugPrint('FeeIntelligenceService: GET $uri');

    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List) {
        return decoded.map((e) => DexChainMetrics.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Unexpected chains response format');
    }
    throw Exception('Failed to load chains (${response.statusCode})');
  }

  Future<DexChainDetailResponse> fetchProtocolsByChain(String chain, {String sortBy = 'total24h', String sortOrder = 'desc'}) async {
    final uri = Uri.parse('$_baseUrl/api/v1/dexs/by-chain/${Uri.encodeComponent(chain)}?sortBy=$sortBy&sortOrder=$sortOrder');
    debugPrint('FeeIntelligenceService: GET $uri');

    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        return DexChainDetailResponse.fromJson(decoded);
      }
      throw Exception('Unexpected chain detail response format');
    }
    throw Exception('Failed to load chain protocols (${response.statusCode})');
  }

  Future<List<TopByFeesProtocol>> fetchTopDexsByVolume() async {
    final uri = Uri.parse('$_baseUrl/api/v1/dexs/top-by-volume');
    debugPrint('FeeIntelligenceService: GET $uri');

    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List) {
        return decoded.map((e) => TopByFeesProtocol.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Unexpected top volume response format');
    }
    throw Exception('Failed to load top volume protocols (${response.statusCode})');
  }
}

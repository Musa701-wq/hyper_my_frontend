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

  Future<List<FeeTopProtocol>> fetchProtocols({int limit = 15, bool isRevenue = false, String? dataType}) async {
    final prefix = _getPrefix(isRevenue, dataType);
    final sortBy = (prefix == 'revenue' || prefix == 'holders-revenue') ? 'revenue' : 'fees24h';
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
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'sortBy': sortBy,
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
}

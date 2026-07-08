import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/fee_intelligence_model.dart';
import '../utils/app_config.dart';

class FeeIntelligenceService {
  String get _baseUrl => AppConfig.baseUrl;

  Future<FeeIntelligenceDashboard> fetchDashboard() async {
    final uri = Uri.parse('$_baseUrl/api/v1/fees/dashboard');
    debugPrint('FeeIntelligenceService: GET $uri');
    
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        return FeeIntelligenceDashboard.fromJson(decoded);
      }
      throw Exception('Unexpected dashboard response format');
    }
    throw Exception('Failed to load fee dashboard stats (${response.statusCode})');
  }

  Future<FeeHistoryData> fetchHistory({String range = '90d'}) async {
    final uri = Uri.parse('$_baseUrl/api/v1/fees/history?range=$range');
    debugPrint('FeeIntelligenceService: GET $uri');

    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        return FeeHistoryData.fromJson(decoded);
      }
      throw Exception('Unexpected fee history response format');
    }
    throw Exception('Failed to load fee history chart (${response.statusCode})');
  }

  Future<List<FeeTopProtocol>> fetchProtocols({int limit = 15}) async {
    final uri = Uri.parse('$_baseUrl/api/v1/fees/protocols?limit=$limit&sortBy=fees24h&sortOrder=desc');
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
    String sortBy = 'fees24h',
    String sortOrder = 'desc',
    String? search,
    String? category,
    String? dataType,
  }) async {
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
    final uri = Uri.parse('$_baseUrl/api/v1/fees/protocols?$query');
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

  Future<FeeCompareResponse> fetchCompare(List<String> slugs, {String range = '90d'}) async {
    final uri = Uri.parse('$_baseUrl/api/v1/fees/compare');
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

  Future<List<TopByFeesProtocol>> fetchTopByFees() async {
    final uri = Uri.parse('$_baseUrl/api/v1/fees/top-by-fees');
    debugPrint('FeeIntelligenceService: GET $uri');

    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List) {
        return decoded.map((e) => TopByFeesProtocol.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Unexpected top-by-fees response format');
    }
    throw Exception('Failed to load top-by-fees protocols (${response.statusCode})');
  }
}

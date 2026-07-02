import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/open_interest_model.dart';
import '../utils/app_config.dart';

class OpenInterestService {
  String get _baseUrl => AppConfig.defillamaUrl;

  Future<OpenInterestListResponse> fetchProtocols({
    String? protocol,
    String? chain,
    String? category,
    double? minOI,
    double? maxOI,
    double? minChange7d,
    double? maxChange7d,
    String? sortBy,
    String? order,
    int? limit,
    int? page,
    bool? activeOnly,
    bool? growthOnly,
    String? fields,
  }) async {
    final queryParams = <String, String>{};
    if (protocol != null && protocol.isNotEmpty) queryParams['protocol'] = protocol;
    if (chain != null && chain.isNotEmpty) queryParams['chain'] = chain;
    if (category != null && category.isNotEmpty) queryParams['category'] = category;
    if (minOI != null) queryParams['minOI'] = minOI.toString();
    if (maxOI != null) queryParams['maxOI'] = maxOI.toString();
    if (minChange7d != null) queryParams['minChange7d'] = minChange7d.toString();
    if (maxChange7d != null) queryParams['maxChange7d'] = maxChange7d.toString();
    if (sortBy != null && sortBy.isNotEmpty) queryParams['sortBy'] = sortBy;
    if (order != null && order.isNotEmpty) queryParams['order'] = order;
    if (limit != null) queryParams['limit'] = limit.toString();
    if (page != null) queryParams['page'] = page.toString();
    if (activeOnly != null) queryParams['activeOnly'] = activeOnly.toString();
    if (growthOnly != null) queryParams['growthOnly'] = growthOnly.toString();
    if (fields != null && fields.isNotEmpty) queryParams['fields'] = fields;

    final uri = Uri.parse('$_baseUrl/api/open-interest').replace(queryParameters: queryParams);
    
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      if (decoded['success'] == true) {
        return OpenInterestListResponse.fromJson(decoded);
      }
      throw Exception(decoded['error'] ?? 'API response error');
    }
    throw Exception('Failed to load open interest protocols (${response.statusCode})');
  }

  Future<List<OpenInterestProtocol>> fetchTop({int limit = 10, String? fields}) async {
    final queryParams = <String, String>{};
    queryParams['limit'] = limit.toString();
    if (fields != null && fields.isNotEmpty) queryParams['fields'] = fields;

    final uri = Uri.parse('$_baseUrl/api/open-interest/top').replace(queryParameters: queryParams);
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      if (decoded['success'] == true) {
        final dataList = decoded['data'] as List<dynamic>? ?? [];
        return dataList.map((e) => OpenInterestProtocol.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception(decoded['error'] ?? 'API response error');
    }
    throw Exception('Failed to load top open interest protocols (${response.statusCode})');
  }

  Future<OpenInterestListResponse> fetchHyperliquid({String? fields}) async {
    final queryParams = <String, String>{};
    if (fields != null && fields.isNotEmpty) queryParams['fields'] = fields;

    final uri = Uri.parse('$_baseUrl/api/open-interest/hyperliquid').replace(queryParameters: queryParams);
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      if (decoded['success'] == true) {
        return OpenInterestListResponse.fromJson(decoded);
      }
      throw Exception(decoded['error'] ?? 'API response error');
    }
    throw Exception('Failed to load Hyperliquid open interest protocols (${response.statusCode})');
  }

  Future<List<OpenInterestChain>> fetchChains() async {
    final uri = Uri.parse('$_baseUrl/api/open-interest/chains');
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      if (decoded['success'] == true) {
        final dataList = decoded['data'] as List<dynamic>? ?? [];
        return dataList.map((e) => OpenInterestChain.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception(decoded['error'] ?? 'API response error');
    }
    throw Exception('Failed to load open interest chains overview (${response.statusCode})');
  }

  Future<OpenInterestSummary> fetchSummary() async {
    final uri = Uri.parse('$_baseUrl/api/open-interest/summary');
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      if (decoded['success'] == true) {
        return OpenInterestSummary.fromJson(decoded['data'] as Map<String, dynamic>? ?? {});
      }
      throw Exception(decoded['error'] ?? 'API response error');
    }
    throw Exception('Failed to load open interest summary statistics (${response.statusCode})');
  }
}

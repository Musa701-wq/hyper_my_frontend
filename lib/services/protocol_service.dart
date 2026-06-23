import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/protocol_model.dart';
import '../utils/app_config.dart';

class ProtocolService {
  final String _baseUrl = AppConfig.defillamaUrl;

  Future<List<Protocol>> getTopByTvl({int limit = 20, String? category}) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        if (category != null && category != 'All Categories') 'category': category,
      };

      final uri = Uri.parse('$_baseUrl/protocols/top-by-tvl').replace(queryParameters: queryParams);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.asMap().entries.map((entry) => Protocol.fromJson(entry.value, index: entry.key)).toList();
      } else {
        throw Exception('Failed to load protocols: ${response.statusCode}');
      }
    } catch (e) {
      print('ProtocolService Error: $e');
      rethrow;
    }
  }

  Future<ProtocolDetail> getProjectDetail(String slug) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/protocols/$slug'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return ProtocolDetail.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Project not found');
      } else {
        throw Exception('Failed to load project detail: ${response.statusCode}');
      }
    } catch (e) {
      print('ProtocolService Detail Error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCategoryDistribution() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/protocols/category-distribution'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load category distribution');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTopChains({int limit = 10}) async {
    try {
      final queryParams = {'limit': limit.toString()};
      final uri = Uri.parse('$_baseUrl/protocols/top-by-chain').replace(queryParameters: queryParams);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load top chains');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ChainFocus>> getChainFocus() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/protocols/chain-focus')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => ChainFocus.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load chain focus data');
      }
    } catch (e) {
      print('ProtocolService ChainFocus Error: $e');
      rethrow;
    }
  }
}

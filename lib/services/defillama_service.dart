import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';

class DefiLlamaService {
  final String baseUrl;

  DefiLlamaService({String? url})
      : baseUrl = url ?? AppConfig.defillamaUrl;

  Future<Map<String, dynamic>> fetchFees({String protocol = 'hyperliquid'}) async {
    final response = await http
        .get(Uri.parse('$baseUrl/defillama/fees?protocol=$protocol&chart=false&breakdown=false'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch DefiLlama fees');
  }

  Future<Map<String, dynamic>> fetchRevenue({String protocol = 'hyperliquid'}) async {
    final response = await http
        .get(Uri.parse('$baseUrl/defillama/revenue?protocol=$protocol&chart=false&breakdown=false'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch DefiLlama revenue');
  }

  Future<Map<String, dynamic>> fetchFeesBreakdown() async {
    final response = await http
        .get(Uri.parse('$baseUrl/defillama/fees/breakdown'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch DefiLlama fees breakdown');
  }

  Future<Map<String, dynamic>> fetchRevenueBreakdown() async {
    final response = await http
        .get(Uri.parse('$baseUrl/defillama/revenue/breakdown'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch DefiLlama revenue breakdown');
  }

  Future<Map<String, dynamic>> fetchFeesChart({String scope = 'all'}) async {
    final response = await http
        .get(Uri.parse('$baseUrl/defillama/fees/chart?scope=$scope'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch DefiLlama fees chart');
  }

  Future<Map<String, dynamic>> fetchRevenueChart({String scope = 'all'}) async {
    final response = await http
        .get(Uri.parse('$baseUrl/defillama/revenue/chart?scope=$scope'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch DefiLlama revenue chart');
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/portfolio_summary_model.dart';
import '../models/portfolio_history_model.dart';

class PortfolioService {
  final String baseUrl;

  PortfolioService({String? url}) 
    : baseUrl = url ?? (dotenv.env['WORKER_URL'] ?? 'http://localhost:4001');

  Future<PortfolioSummaryModel> getPortfolioSummary(String wallet) async {
    final response = await http.get(Uri.parse('$baseUrl/api/portfolio/$wallet/summary'));
    
    if (response.statusCode == 200) {
      return PortfolioSummaryModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load portfolio summary: ${response.statusCode}');
    }
  }

  Future<PortfolioHistoryModel> getPortfolioHistory(String wallet) async {
    final response = await http.get(Uri.parse('$baseUrl/api/portfolio/$wallet/history'));
    
    if (response.statusCode == 200) {
      return PortfolioHistoryModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load portfolio history: ${response.statusCode}');
    }
  }
}

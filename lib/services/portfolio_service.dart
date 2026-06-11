import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/portfolio_summary_model.dart';
import '../models/portfolio_history_model.dart';

class PortfolioService {
  final String baseUrl;

  PortfolioService({String? url}) 
    : baseUrl = url ?? (dotenv.env['BASE_URL'] ?? 'https://coingecko.renderonnodes.com');

  Future<PortfolioSummaryModel> getPortfolioSummary(String wallet) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/portfolio/$wallet/summary'))
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return PortfolioSummaryModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load portfolio summary: ${response.statusCode}');
      }
    } catch (e) {
      if (e is TimeoutException) {
        throw Exception('Portfolio summary request timed out. Please check your connection.');
      }
      rethrow;
    }
  }

  Future<PortfolioHistoryModel> getPortfolioHistory(String wallet) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/portfolio/$wallet/history'))
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return PortfolioHistoryModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load portfolio history: ${response.statusCode}');
      }
    } catch (e) {
      if (e is TimeoutException) {
        throw Exception('Portfolio history request timed out. Please check your connection.');
      }
      rethrow;
    }
  }
}


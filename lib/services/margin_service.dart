import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/ticker_model.dart';

class MarginService {
  static String get baseUrl {
    return dotenv.env['LEVERAGE_API_URL'] ?? dotenv.env['LIQUIDATION_API_URL'] ?? 'http://localhost:4001';
  }

  /// Fetch perp markets (tickers) from /perps to parse maxLeverage and marginTableId
  Future<List<TickerModel>> getPerpMarkets() async {
    final uri = Uri.parse('$baseUrl/perps');
    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('API Error: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded.map((x) => TickerModel.fromJson(x as Map<String, dynamic>)).toList();
    }
    throw Exception('Invalid response format');
  }
}

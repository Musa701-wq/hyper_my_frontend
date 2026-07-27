import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/liquidatable_model.dart';
import '../utils/app_config.dart';

class LiquidatableService {
  static String get baseUrl {
    return dotenv.env['LIQUIDATION_API_URL'] ?? AppConfig.baseUrl;
  }

  /// Sab liquidatable positions
  Future<LiquidatableResponse> getLiquidatable({String? coin}) async {
    final uri = Uri.parse('$baseUrl/api/liquidatable').replace(
      queryParameters: coin != null && coin.isNotEmpty ? {'coin': coin.toUpperCase()} : null,
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('API Error: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return LiquidatableResponse.fromJson(json);
  }
}

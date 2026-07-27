import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/borrow_lend_model.dart';
import '../utils/app_config.dart';

class BorrowLendService {
  String get _base => dotenv.env['BORROW_LEND_API_URL'] ?? AppConfig.baseUrl; // Use env config or fallback to CoinGecko base URL

  Future<List<BorrowLendModel>> getAllPools() async {
    final uri = Uri.parse('$_base/api/borrow-lend/all');
    try {
      debugPrint('🌐 [BorrowLendService] GET: $uri');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw Exception('API Error: ${res.statusCode}');
      }
      
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      if (decoded['success'] != true) {
        throw Exception('API returned success=false');
      }

      final data = decoded['data'] as List? ?? [];
      return data.map((e) => BorrowLendModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Exception in getAllPools: $e');
      rethrow;
    }
  }
}

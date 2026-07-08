import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/funding_history_model.dart';
import '../utils/app_config.dart';

class FundingHistoryService {
  String get _base => AppConfig.hip4DetailsTabBaseUrl; // Using local worker on port 4001

  Future<List<FundingHistoryEntry>> fetchFundingHistory(String coin, int startTimeMs, {int? endTimeMs}) async {
    var url = '$_base/api/funding-history/${coin.toUpperCase()}?startTime=$startTimeMs';
    if (endTimeMs != null) {
      url += '&endTime=$endTimeMs';
    }

    try {
      debugPrint('🌐 [FundingHistoryService] GET: $url');
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        if (decoded['success'] == true) {
          final resObj = FundingHistoryResponse.fromJson(decoded);
          return resObj.data;
        } else {
          throw Exception(decoded['error'] ?? 'API reports success=false');
        }
      } else {
        throw Exception('Failed to load funding history: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('API Exception: $e');
      rethrow;
    }
  }
}

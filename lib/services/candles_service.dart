import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/hip4_model.dart';

class CandlesService {
  static const String _url = 'https://api.hyperliquid.xyz/info';

  static Future<List<Hip4Candle>> fetchCandles({
    required String coin,
    required String interval,
    required int daysBack,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final startTime = now - (daysBack * 24 * 60 * 60 * 1000);

      // Clean the coin symbol (e.g. BTC-USDC -> BTC, xyz:HOOD-USDC -> xyz:HOOD)
      String cleanCoin = coin;
      if (cleanCoin.endsWith('-USDC')) {
        cleanCoin = cleanCoin.substring(0, cleanCoin.length - 5);
      } else if (cleanCoin.endsWith('/USDC')) {
        cleanCoin = cleanCoin.substring(0, cleanCoin.length - 5);
      }

      final payload = {
        'type': 'candleSnapshot',
        'req': {
          'coin': cleanCoin,
          'interval': interval,
          'startTime': startTime,
          'endTime': now,
        }
      };

      debugPrint('CandlesService: Fetching candles for $cleanCoin ($interval)...');
      final response = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          final list = decoded.map((c) => Hip4Candle.fromJson(c as Map<String, dynamic>)).toList();
          debugPrint('CandlesService: Successfully fetched ${list.length} candles.');
          // Sort candles chronologically (oldest first, which is standard for painters)
          list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return list;
        } else {
          debugPrint('CandlesService: Unexpected response format: $decoded');
        }
      } else {
        debugPrint('CandlesService: Non-200 response: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('CandlesService error: $e');
    }
    return [];
  }
}

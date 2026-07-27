import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/hip4_model.dart';

class CandlesService {
  static const String _url = 'https://api.hyperliquid.xyz/info';

  static Map<int, String>? _spotIndexToUniverseName;

  static Future<void> _loadSpotUniverse() async {
    try {
      final payload = {
        'type': 'spotMetaAndAssetCtxs'
      };
      final response = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          final first = decoded[0];
          if (first is Map && first.containsKey('universe')) {
            final universeList = first['universe'] as List;
            final Map<int, String> newMap = {};
            for (final item in universeList) {
              if (item is Map) {
                final tokens = item['tokens'];
                final uName = item['name']?.toString();
                if (tokens is List &&
                    tokens.length >= 2 &&
                    tokens[0] != null &&
                    tokens[1] != null &&
                    (tokens[1] as num).toInt() == 0 &&
                    uName != null) {
                  final baseTokenIdx = (tokens[0] as num).toInt();
                  // Strip suffix "/USDC" if present
                  String cleanName = uName;
                  if (cleanName.endsWith('/USDC')) {
                    cleanName = cleanName.substring(0, cleanName.length - 5);
                  }
                  newMap[baseTokenIdx] = cleanName;
                }
              }
            }
            _spotIndexToUniverseName = newMap;
            debugPrint('CandlesService: Loaded ${_spotIndexToUniverseName!.length} spot universe names.');
          }
        }
      }
    } catch (e) {
      debugPrint('CandlesService: Error loading spot universe metadata: $e');
    }
  }

  static Future<List<Hip4Candle>> fetchCandles({
    required String coin,
    required String interval,
    required int daysBack,
    int? tokenIndex,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final startTime = now - (daysBack * 24 * 60 * 60 * 1000);

      // Clean the coin symbol (e.g. BTC-USDC -> BTC, xyz:HOOD-USDC -> xyz:HOOD)
      String cleanCoin = coin;
      if (tokenIndex != null) {
        if (_spotIndexToUniverseName == null) {
          await _loadSpotUniverse();
        }
        final mappedName = _spotIndexToUniverseName?[tokenIndex];
        if (mappedName != null) {
          cleanCoin = mappedName;
        } else {
          if (cleanCoin.endsWith('-USDC')) {
            cleanCoin = cleanCoin.substring(0, cleanCoin.length - 5);
          } else if (cleanCoin.endsWith('/USDC')) {
            cleanCoin = cleanCoin.substring(0, cleanCoin.length - 5);
          }
        }
      } else {
        if (cleanCoin.endsWith('-USDC')) {
          cleanCoin = cleanCoin.substring(0, cleanCoin.length - 5);
        } else if (cleanCoin.endsWith('/USDC')) {
          cleanCoin = cleanCoin.substring(0, cleanCoin.length - 5);
        }
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

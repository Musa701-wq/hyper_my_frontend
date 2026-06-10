import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/leaderboard_model.dart';

class LeaderboardService {
  final String baseUrl;

  LeaderboardService({String? url})
    : baseUrl = url ?? (dotenv.env['STATS_API_URL'] ?? 'http://localhost:4000');

  Future<LeaderboardStats> getStats({String period = 'allTime'}) async {
    final url = '$baseUrl/leaderboard/stats?period=$period';
    try {
      debugPrint('🌐 [LeaderboardService] GET Stats: $url');
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      debugPrint('📥 [LeaderboardService] Response (${response.statusCode}): ${response.body}');
      if (response.statusCode == 200) {
        return LeaderboardStats.fromJson(json.decode(response.body));
      } else {
        debugPrint('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load leaderboard stats');
      }
    } catch (e) {
      print('API Exception: $e');
      rethrow;
    }
  }

  Future<LeaderboardResponse> getTraders({
    int page = 1,
    int limit = 10,
    String sortBy = 'accountValue',
    String sortOrder = 'desc',
    String period = 'allTime',
    String? search,
  }) async {
    var url = '$baseUrl/leaderboard/traders?page=$page&limit=$limit&sortBy=$sortBy&sortOrder=$sortOrder&period=$period';
    if (search != null && search.isNotEmpty) {
      url += '&search=$search';
    }

    try {
      print('🌐 [LeaderboardService] GET Traders: $url');
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      print('📥 [LeaderboardService] Response (${response.statusCode}): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 200) {
        return LeaderboardResponse.fromJson(json.decode(response.body));
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load traders');
      }
    } catch (e) {
      print('API Exception: $e');
      rethrow;
    }
  }

  Future<List<Trader>> getTopTraders(String metric, {int limit = 10, String period = 'allTime'}) async {
    final url = '$baseUrl/leaderboard/traders/top/$metric?limit=$limit&period=$period';
    try {
      print('🌐 [LeaderboardService] GET Top Traders: $url');
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      print('📥 [LeaderboardService] Response (${response.statusCode}): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        return (data['traders'] as List).map((t) => Trader.fromJson(t)).toList();
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load top traders');
      }
    } catch (e) {
      print('API Exception: $e');
      rethrow;
    }
  }

  Future<HeadlineResponse> getHeadline({int limit = 5}) async {
    final url = '$baseUrl/leaderboard/traders/headline?limit=$limit';
    try {
      debugPrint('🌐 [LeaderboardService] GET Headline: $url');
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      debugPrint('📥 [LeaderboardService] Headline Response (${response.statusCode}): ${response.body}');
      if (response.statusCode == 200) {
        return HeadlineResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load headline');
      }
    } catch (e) {
      debugPrint('Headline API Exception: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTraderDetails(String address) async {
    final response = await http.get(
      Uri.parse('$baseUrl/leaderboard/traders/$address'),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    } else {
      throw Exception('Trader not found');
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../utils/app_config.dart';

class PredictedFundingVenue {
  final String venue;
  final double fundingRate;
  final int nextFundingTime;
  final String nextFundingTimeISO;
  final int fundingIntervalHours;

  PredictedFundingVenue({
    required this.venue,
    required this.fundingRate,
    required this.nextFundingTime,
    required this.nextFundingTimeISO,
    required this.fundingIntervalHours,
  });

  factory PredictedFundingVenue.fromJson(Map<String, dynamic> json) {
    return PredictedFundingVenue(
      venue:                json['venue'] as String? ?? '',
      fundingRate:          (json['fundingRate'] as num? ?? 0.0).toDouble(),
      nextFundingTime:      json['nextFundingTime'] as int? ?? 0,
      nextFundingTimeISO:   json['nextFundingTimeISO'] as String? ?? '',
      fundingIntervalHours: json['fundingIntervalHours'] as int? ?? 8,
    );
  }
}

class PredictedFunding {
  final String coin;
  final List<PredictedFundingVenue> venues;

  PredictedFunding({required this.coin, required this.venues});

  factory PredictedFunding.fromJson(Map<String, dynamic> json) {
    final venuesList = json['venues'] as List? ?? [];
    return PredictedFunding(
      coin:   json['coin'] as String? ?? '',
      venues: venuesList
          .map((v) => PredictedFundingVenue.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PredictedFundingsService {
  String get _base => AppConfig.hip4DetailsTabBaseUrl; // points to http://localhost:4001 or .env

  /// Sab coins ka predicted funding (optional venue filter)
  Future<List<PredictedFunding>> getAllFundings({String? venue}) async {
    final queryParams = venue != null ? {'venue': venue} : null;
    final uri = Uri.parse('$_base/api/predicted-fundings').replace(
      queryParameters: queryParams,
    );

    try {
      debugPrint('🌐 [PredictedFundingsService] GET: $uri');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('API Error: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'] as List? ?? [];
      return data.map((e) => PredictedFunding.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Exception in getAllFundings: $e');
      rethrow;
    }
  }

  /// Single coin ka predicted funding
  Future<PredictedFunding?> getCoinFunding(String coin, {String? venue}) async {
    final queryParams = venue != null ? {'venue': venue} : null;
    final uri = Uri.parse('$_base/api/predicted-fundings/${coin.toUpperCase()}').replace(
      queryParameters: queryParams,
    );

    try {
      debugPrint('🌐 [PredictedFundingsService] GET: $uri');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 404) {
        return null; // Coin not found (e.g. Spot assets)
      }
      if (response.statusCode != 200) {
        throw Exception('API Error: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return PredictedFunding.fromJson(decoded);
    } catch (e) {
      debugPrint('Exception in getCoinFunding: $e');
      rethrow;
    }
  }
}

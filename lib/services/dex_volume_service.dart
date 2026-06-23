import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dex_volume_model.dart';
import '../utils/app_config.dart';

class DexVolumeService {
  final String dexVolumeUrl = AppConfig.dexVolumeUrl;

  Future<DexVolumeMetrics> fetchVolumeMetrics() async {
    final response = await http.get(Uri.parse('$dexVolumeUrl/api/dex-volume'));
    if (response.statusCode == 200) {
      return DexVolumeMetrics.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load DEX volume metrics');
    }
  }

  Future<List<DexVolumeChartPoint>> fetchChartData({String scope = 'all'}) async {
    final response = await http.get(Uri.parse('$dexVolumeUrl/api/dex-volume/chart?scope=$scope'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      
      // Documentation says: 
      // scope=all -> totalDataChart
      // scope=spot -> chart
      final dynamic rawChart = data['totalDataChart'] ?? data['chart'];
      
      if (rawChart is! List) return [];
      return rawChart.map((e) => DexVolumeChartPoint.fromList(e as List)).toList();
    } else {
      throw Exception('Failed to load DEX chart data ($scope)');
    }
  }

  Future<AdoptionMetrics> fetchAdoptionMetrics() async {
    final response = await http.get(Uri.parse('$dexVolumeUrl/api/hyperliquid-adoption'));
    if (response.statusCode == 200) {
      return AdoptionMetrics.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load adoption metrics');
    }
  }
}

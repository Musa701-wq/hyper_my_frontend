import 'dart:math';
import 'package:flutter/material.dart';
import '../models/dex_volume_model.dart';
import '../services/dex_volume_service.dart';

class DexVolumeViewModel extends ChangeNotifier {
  final DexVolumeService _service = DexVolumeService();

  DexVolumeMetrics? _metrics;
  List<DexVolumeChartPoint> _chartData = [];
  List<DexVolumeChartPoint> _spotChartData = [];
  AdoptionMetrics? _adoption;
  
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedScope = 'spot'; // all, spot, perps
  String _selectedTimeRange = 'M'; // All, D, W, M, Y
  String _selectedChartType = 'Area'; // Area, Bar

  DexVolumeMetrics? get metrics => _metrics;
  
  List<DexVolumeChartPoint> get chartData {
    List<DexVolumeChartPoint> baseData;
    if (_selectedScope == 'spot') {
      baseData = _spotChartData;
    } else if (_selectedScope == 'perps') {
      // Calculate Perps = Total - Spot (matched by timestamp)
      final spotMap = {for (var e in _spotChartData) e.timestamp.millisecondsSinceEpoch: e.volume};
      baseData = _chartData.map((e) {
        final spot = spotMap[e.timestamp.millisecondsSinceEpoch] ?? 0;
        return DexVolumeChartPoint(
          timestamp: e.timestamp,
          volume: max(0.0, e.volume - spot),
        );
      }).toList();
    } else {
      baseData = _chartData;
    }

    // Apply granularity aggregation based on _selectedTimeRange
    return _aggregateByGranularity(baseData, _selectedTimeRange);
  }

  AdoptionMetrics? get adoption => _adoption;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get selectedScope => _selectedScope;
  String get selectedTimeRange => _selectedTimeRange;
  String get selectedChartType => _selectedChartType;

  Future<void> init() async {
    await fetchAllData();
  }

  Future<void> fetchAllData() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Parallel API fetching as per documentation
      final results = await Future.wait([
        _service.fetchVolumeMetrics(),
        _service.fetchChartData(scope: 'all'),
        _service.fetchChartData(scope: 'spot'),
        _service.fetchAdoptionMetrics(),
      ]);

      _metrics = results[0] as DexVolumeMetrics;
      _chartData = results[1] as List<DexVolumeChartPoint>;
      _spotChartData = results[2] as List<DexVolumeChartPoint>;
      _adoption = results[3] as AdoptionMetrics;
      
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'We encountered a problem connecting to the server. Please check your internet connection or try again later.';
      debugPrint('Fetch error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<DexVolumeChartPoint> _aggregateByGranularity(List<DexVolumeChartPoint> daily, String g) {
    if (g == 'All' || g == 'D') return daily;

    final Map<int, double> buckets = {};
    for (final p in daily) {
      final date = p.timestamp;
      DateTime bucketDate;
      
      if (g == 'W') {
        // Monday of the week
        final diff = date.weekday == DateTime.monday ? 0 : date.weekday - 1;
        bucketDate = DateTime.utc(date.year, date.month, date.day).subtract(Duration(days: diff));
      } else if (g == 'M') {
        bucketDate = DateTime.utc(date.year, date.month, 1);
      } else if (g == 'Y') {
        bucketDate = DateTime.utc(date.year, 1, 1);
      } else {
        bucketDate = date;
      }

      final key = bucketDate.millisecondsSinceEpoch;
      buckets[key] = (buckets[key] ?? 0) + p.volume;
    }

    final result = buckets.entries
        .map((e) => DexVolumeChartPoint(
              timestamp: DateTime.fromMillisecondsSinceEpoch(e.key, isUtc: true),
              volume: e.value,
            ))
        .toList();
    
    // Sort by timestamp
    result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    // For W, M, Y, we might want to filter to only show recent if it was D/W/M/Y toggles
    // But documentation says "All" / "D" -> raw, "W" -> week, etc.
    // So we just return the aggregated bucketed data.
    return result;
  }

  void setScope(String scope) {
    if (_selectedScope == scope) return;
    _selectedScope = scope;
    notifyListeners();
  }

  void setTimeRange(String range) {
    if (_selectedTimeRange == range) return;
    _selectedTimeRange = range;
    notifyListeners();
  }

  void setChartType(String type) {
    if (_selectedChartType == type) return;
    _selectedChartType = type;
    notifyListeners();
  }
}

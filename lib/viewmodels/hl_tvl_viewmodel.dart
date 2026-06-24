import 'package:flutter/material.dart';
import '../models/hl_tvl_model.dart';
import '../services/hl_tvl_service.dart';

class HlTvlViewModel extends ChangeNotifier {
  final HlTvlService _service = HlTvlService();

  HlTvlSummary? _summary;
  HlTvlMetrics? _metrics;
  bool _isLoading = false;
  String _error = '';

  HlTvlSummary? get summary => _summary;
  HlTvlMetrics? get metrics => _metrics;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> fetchAll() async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.fetchSummary(),
        _service.fetchMetrics(),
      ]);
      _summary = results[0] as HlTvlSummary;
      _metrics = results[1] as HlTvlMetrics;
    } catch (e) {
      _error = 'Failed to load data. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

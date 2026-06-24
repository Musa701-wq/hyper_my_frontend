import 'package:flutter/material.dart';
import '../models/hl_tvl_model.dart';
import '../services/hl_tvl_service.dart';

class HlTvlViewModel extends ChangeNotifier {
  final HlTvlService _service = HlTvlService();

  HlTvlSummary? _summary;
  HlTvlMetrics? _metrics;
  HlTvlHistory? _history;
  HlChainsHistory? _chainsHistory;
  String _selectedRange = 'all';
  String _selectedChainsRange = 'all';
  bool _isLoading = false;
  bool _isHistoryLoading = false;
  bool _isChainsHistoryLoading = false;
  String _error = '';

  HlTvlSummary? get summary => _summary;
  HlTvlMetrics? get metrics => _metrics;
  HlTvlHistory? get history => _history;
  HlChainsHistory? get chainsHistory => _chainsHistory;
  String get selectedRange => _selectedRange;
  String get selectedChainsRange => _selectedChainsRange;
  bool get isLoading => _isLoading;
  bool get isHistoryLoading => _isHistoryLoading;
  bool get isChainsHistoryLoading => _isChainsHistoryLoading;
  String get error => _error;

  Future<void> fetchAll() async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.fetchSummary(),
        _service.fetchMetrics(),
        _service.fetchHistory(range: _selectedRange),
        _service.fetchChainsHistory(range: _selectedChainsRange),
      ]);
      _summary = results[0] as HlTvlSummary;
      _metrics = results[1] as HlTvlMetrics;
      _history = results[2] as HlTvlHistory;
      _chainsHistory = results[3] as HlChainsHistory;
    } catch (e) {
      _error = 'Failed to load data. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setRange(String range) async {
    if (_selectedRange == range) return;
    _selectedRange = range;
    _isHistoryLoading = true;
    notifyListeners();
    try {
      _history = await _service.fetchHistory(range: range);
    } catch (e) {
    } finally {
      _isHistoryLoading = false;
      notifyListeners();
    }
  }

  Future<void> setChainsRange(String range) async {
    if (_selectedChainsRange == range) return;
    _selectedChainsRange = range;
    _isChainsHistoryLoading = true;
    notifyListeners();
    try {
      _chainsHistory = await _service.fetchChainsHistory(range: range);
    } catch (e) {
    } finally {
      _isChainsHistoryLoading = false;
      notifyListeners();
    }
  }
}

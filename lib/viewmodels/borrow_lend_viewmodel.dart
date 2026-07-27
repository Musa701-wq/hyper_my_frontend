import 'dart:async';
import 'package:flutter/material.dart';
import '../models/borrow_lend_model.dart';
import '../services/borrow_lend_service.dart';

class BorrowLendViewModel extends ChangeNotifier {
  final BorrowLendService _service = BorrowLendService();

  List<BorrowLendModel> _pools = [];
  bool _isLoading = false;
  String _error = '';
  Timer? _refreshTimer;

  List<BorrowLendModel> get pools => _pools;
  bool get isLoading => _isLoading;
  String get error => _error;

  /// Fetch pools from backend
  Future<void> fetchPools({bool silent = false}) async {
    if (!silent && _pools.isEmpty) {
      _isLoading = true;
      _error = '';
      notifyListeners();
    }

    try {
      final data = await _service.getAllPools();
      _pools = data;
      _error = '';
    } catch (e) {
      if (_pools.isEmpty) {
        _error = 'Failed to load borrowing and lending pools.';
      }
      debugPrint('Error in BorrowLendViewModel.fetchPools: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Start automatic polling every 10 seconds
  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      fetchPools(silent: true);
    });
  }

  /// Stop automatic polling
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}

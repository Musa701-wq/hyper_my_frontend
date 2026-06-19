import 'dart:async';
import 'package:flutter/material.dart';

import '../models/leaderboard_model.dart';
import '../services/leaderboard_service.dart';
import '../utils/app_exceptions.dart';

class LeaderboardViewModel extends ChangeNotifier {
  final LeaderboardService _service = LeaderboardService();

  LeaderboardStats? _stats;
  HeadlineResponse? _headline;
  LeaderboardResponse? _tradersResponse;
  List<Trader> _topTraders = [];
  bool _isLoading = false;
  String? _error;
  String _selectedPeriod = 'allTime';
  String _selectedMetric = 'accountValue';
  int _currentPage = 1;
  int _rowsPerPage = 20;
  String _searchQuery = '';
  Timer? _searchDebounce;


  // Getters
  LeaderboardStats? get stats => _stats;
  HeadlineResponse? get headline => _headline;
  List<Trader> get traders => _tradersResponse?.traders ?? [];
  List<Trader> get topTraders => _topTraders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedPeriod => _selectedPeriod;
  String get selectedMetric => _selectedMetric;
  int get currentPage => _currentPage;
  int get rowsPerPage => _rowsPerPage;
  int get totalPages => _tradersResponse?.totalPages ?? 1;
  String get searchQuery => _searchQuery;

  Future<void> fetchAllData() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('LeaderboardViewModel: Start Fetch Sequence (Stats & Top Traders)...');
      
      _stats = await _service.getStats(period: _selectedPeriod);
      _headline = await _service.getHeadline(limit: 5);
      await fetchTopTraders();
      
      _error = null;
      debugPrint('LeaderboardViewModel: Data successfully fetched');
    } catch (e) {
      debugPrint('LeaderboardViewModel Aggregate Error: $e');
      _error = AppException.fromError(e).message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTopTraders() async {
    _isLoading = true;
    notifyListeners();
    try {
      _tradersResponse = await _service.getTraders(
        page: _currentPage,
        limit: _rowsPerPage,
        sortBy: _selectedMetric,
        period: _selectedPeriod,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      _topTraders = _tradersResponse?.traders ?? [];
    } catch (e) {
      debugPrint('Fetch Traders Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _currentPage = 1;

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      fetchTopTraders();
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void setRowsPerPage(int rows) {
    _rowsPerPage = rows;
    _currentPage = 1;
    fetchTopTraders();
  }

  void nextPage() {
    if (_currentPage < totalPages) {
      _currentPage++;
      fetchTopTraders();
    }
  }

  void previousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      fetchTopTraders();
    }
  }

  void setPage(int page) {
    _currentPage = page;
    fetchTopTraders();
  }

  void setPeriod(String period) {
    if (_selectedPeriod == period) return;
    _selectedPeriod = period;
    fetchAllData();
  }

  void setMetric(String metric) {
    if (_selectedMetric == metric) return;
    _selectedMetric = metric;
    
    // Reset period to allTime if switching to accountValue
    if (metric == 'accountValue') {
      _selectedPeriod = 'allTime';
    }
    
    fetchTopTraders();
  }

}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../models/protocol_model.dart';
import '../services/protocol_service.dart';

class ProtocolViewModel extends ChangeNotifier {
  final ProtocolService _service = ProtocolService();

  List<Protocol> _protocols = [];
  bool _isLoading = false;
  String _errorMessage = '';
  
  // View-specific filters
  String _gridSearch = '';
  String _listSearch = '';
  String _chartSearch = '';
  
  String _gridCategory = 'All';
  String _listCategory = 'All';
  String _chartCategory = 'All';

  int _limit = 100;
  List<String> _categories = ['All'];
  bool _isAscending = false;
  String _sortBy = 'TVL (High to Low)';

  // Main Tabs (Categories vs Chains)
  int _mainTabIndex = 0; // 0: TVL by Category, 1: TVL by Chain
  // Sub Views for Categories (Grid, List, Chart)
  int _tvlViewIndex = 0; // 0: Grid, 1: List, 2: Chart

  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 20;

  // Category Distribution
  List<CategoryDistribution> _categoryDistribution = [];
  bool _isCategoryDistLoading = false;

  // Top Chains
  List<ChainTvl> _topChains = [];
  bool _isChainsLoading = false;

  // Chain Focus
  List<ChainFocus> _chainFocusData = [];
  String _selectedChain = 'Overall';
  bool _isChainFocusLoading = false;
  
  bool _isSearchExpanded = false;

  List<Protocol> get protocols => _protocols;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  int get limit => _limit;
  List<String> get categories => _categories;
  bool get isAscending => _isAscending;
  String get sortBy => _sortBy;

  // View-specific getters
  String get gridSearch => _gridSearch;
  String get listSearch => _listSearch;
  String get chartSearch => _chartSearch;
  String get gridCategory => _gridCategory;
  String get listCategory => _listCategory;
  String get chartCategory => _chartCategory;

  List<Protocol> get gridProtocols => _applyFilters(_protocols, _gridSearch, _gridCategory);
  List<Protocol> get listProtocols => _applyFilters(_protocols, _listSearch, _listCategory);
  List<Protocol> get chartProtocols => _applyFilters(_protocols, _chartSearch, _chartCategory);
  int get currentPage => _currentPage;
  int get itemsPerPage => _itemsPerPage;
  int get totalPages => (listProtocols.length / _itemsPerPage).ceil();

  List<Protocol> get paginatedListProtocols {
    final start = (_currentPage - 1) * _itemsPerPage;
    final filtered = listProtocols;
    if (start >= filtered.length) return [];
    final end = (start + _itemsPerPage).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }
  List<CategoryDistribution> get categoryDistribution => _categoryDistribution;
  bool get isCategoryDistLoading => _isCategoryDistLoading;
  List<ChainTvl> get topChains => _topChains;
  bool get isChainsLoading => _isChainsLoading;

  List<ChainFocus> get chainFocusData => _chainFocusData;
  String get selectedChain => _selectedChain;
  bool get isChainFocusLoading => _isChainFocusLoading;

  ChainFocus? get currentChainFocus {
    if (_chainFocusData.isEmpty) return null;
    return _chainFocusData.firstWhere(
      (e) => e.chain == _selectedChain,
      orElse: () => _chainFocusData.first,
    );
  }

  double get totalTvl => _protocols.fold(0.0, (sum, p) => sum + p.tvl);
  int get protocolCount => _protocols.length;
  int get categoryCount => _categories.length > 1 ? _categories.length - 1 : 0;
  int get chainCount => _topChains.length;

  int get mainTabIndex => _mainTabIndex;
  int get tvlViewIndex => _tvlViewIndex;
  bool get isSearchExpanded => _isSearchExpanded;

  void setMainTab(int index) {
    _mainTabIndex = index;
    notifyListeners();
  }

  void setTvlView(int index) {
    _tvlViewIndex = index;
    notifyListeners();
  }

  void toggleSearchExpanded() {
    _isSearchExpanded = !_isSearchExpanded;
    notifyListeners();
  }

  String get formattedTotalTvl {
    final tvl = totalTvl;
    if (tvl >= 1e9) return '\$${(tvl / 1e9).toStringAsFixed(2)}B';
    if (tvl >= 1e6) return '\$${(tvl / 1e6).toStringAsFixed(2)}M';
    return '\$${tvl.toStringAsFixed(0)}';
  }

  Future<void> fetchProtocols() async {
    _setLoading(true);
    _errorMessage = '';
    
    try {
      _protocols = await _service.getTopByTvl(limit: 100);
      
      _sortProtocols();
      
      if (_categories.length == 1) {
        await _fetchCategories();
      }
    } catch (e) {
      _errorMessage = _getFriendlyErrorMessage(e);
    } finally {
      _setLoading(false);
    }
  }

  List<Protocol> _applyFilters(List<Protocol> list, String query, String category) {
    var result = list;
    
    // Category Filter
    if (category != 'All') {
      result = result.where((p) => p.category == category).toList();
    }

    // Search Filter
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      result = result.where((p) => 
        p.name.toLowerCase().contains(q) || 
        p.category.toLowerCase().contains(q)
      ).toList();
    }
    
    return result;
  }

  Future<void> fetchCategoryDistribution() async {
    _isCategoryDistLoading = true;
    notifyListeners();

    try {
      final raw = await _service.getCategoryDistribution();
      debugPrint('CategoryDistribution raw: $raw');
      if (raw.isNotEmpty) {
        debugPrint('CategoryDistribution first item keys: ${raw.first.keys}');
      }
      final totalTvl = raw.fold<double>(0, (sum, e) {
        final tvl = _extractTvl(e);
        return sum + tvl;
      });
      _categoryDistribution = raw.map((e) {
        final tvl = _extractTvl(e);
        return CategoryDistribution(
          category: e['category'] as String? ?? 'Unknown',
          tvl: tvl,
          percentage: totalTvl > 0 ? (tvl / totalTvl) * 100 : 0.0,
        );
      }).toList();
      _categoryDistribution.sort((a, b) => b.tvl.compareTo(a.tvl));
    } catch (e) {
      debugPrint('Error fetching category distribution: $e');
      _categoryDistribution = [];
    } finally {
      _isCategoryDistLoading = false;
      notifyListeners();
    }
  }

  double _extractTvl(Map<String, dynamic> json) {
    const possibleKeys = ['tvl', 'totalTvl', 'totalValueLocked', 'value', 'amount', 'usdTvl'];
    for (final key in possibleKeys) {
      final val = json[key];
      if (val != null && val is num && val > 0) {
        return val.toDouble();
      }
    }
    return (json['tvl'] as num? ?? 0).toDouble();
  }

  Future<void> fetchTopChains() async {
    _isChainsLoading = true;
    notifyListeners();

    try {
      final raw = await _service.getTopChains(limit: 10);
      _topChains = raw.map((e) => ChainTvl.fromJson(e)).toList();
      _topChains.sort((a, b) => b.tvl.compareTo(a.tvl));
    } catch (e) {
      print('Error fetching top chains: $e');
      _topChains = [];
    } finally {
      _isChainsLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchChainFocus() async {
    _isChainFocusLoading = true;
    _isChainsLoading = true;
    notifyListeners();

    try {
      _chainFocusData = await _service.getChainFocus();
      
      // Populate _topChains from _chainFocusData to avoid "No chain data" issue
      _topChains = _chainFocusData.map((e) => ChainTvl(
        chain: e.chain,
        tvl: e.totalTvl,
      )).toList();
      _topChains.sort((a, b) => b.tvl.compareTo(a.tvl));

      if (_chainFocusData.isNotEmpty && _selectedChain == 'Hyperliquid L1') {
        _selectedChain = 'Overall';
      }
    } catch (e) {
      debugPrint('Error fetching chain focus: $e');
      _chainFocusData = [];
      _topChains = [];
    } finally {
      _isChainFocusLoading = false;
      _isChainsLoading = false;
      notifyListeners();
    }
  }

  void setSelectedChain(String chain) {
    _selectedChain = chain;
    notifyListeners();
  }

  String _getFriendlyErrorMessage(Object e) {
    if (e is SocketException || e.toString().contains('SocketException')) {
      return 'Unable to connect to the server. Please check if the backend service is running or try again later.';
    } else if (e is ClientException || e.toString().contains('ClientException')) {
      return 'Connection failed. Please check your internet connection and try again.';
    } else if (e is HttpException || e.toString().contains('HttpException')) {
      return 'Server error occurred. Please try again later.';
    } else if (e.toString().contains('timeout')) {
      return 'The connection timed out. Please try again.';
    }
    return 'Something went wrong while fetching data. Please try again.';
  }

  Future<void> _fetchCategories() async {
    try {
      final dist = await _service.getCategoryDistribution();
      final fetchedCategories = dist.map((e) => e['category'] as String).toList();
      _categories = ['All', ...fetchedCategories];
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  void setGridSearch(String text) {
    _gridSearch = text;
    notifyListeners();
  }

  void setListSearch(String text) {
    _listSearch = text;
    _currentPage = 1;
    notifyListeners();
  }

  void setChartSearch(String text) {
    _chartSearch = text;
    notifyListeners();
  }

  void setGridCategory(String category) {
    _gridCategory = category;
    notifyListeners();
  }

  void setListCategory(String category) {
    _listCategory = category;
    _currentPage = 1;
    notifyListeners();
  }

  void setChartCategory(String category) {
    _chartCategory = category;
    notifyListeners();
  }

  void toggleSortOrder() {
    _isAscending = !_isAscending;
    _sortProtocols();
    notifyListeners();
  }

  void _sortProtocols() {
    if (_sortBy.contains('TVL')) {
      _protocols.sort((a, b) => _isAscending 
        ? a.tvl.compareTo(b.tvl) 
        : b.tvl.compareTo(a.tvl));
    } else if (_sortBy == '1D Change') {
      _protocols.sort((a, b) => (b.change1d ?? -999.0).compareTo(a.change1d ?? -999.0));
    } else if (_sortBy == '7D Change') {
      _protocols.sort((a, b) => (b.change7d ?? -999.0).compareTo(a.change7d ?? -999.0));
    }
  }

  void setPage(int page) {
    if (page >= 1 && page <= totalPages) {
      _currentPage = page;
      notifyListeners();
    }
  }

  void setLimit(int value) {
    _limit = value;
    fetchProtocols();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../models/open_interest_model.dart';
import '../services/open_interest_service.dart';

class OpenInterestViewModel extends ChangeNotifier {
  final OpenInterestService _service = OpenInterestService();

  List<OpenInterestProtocol> _protocols = [];
  List<OpenInterestChain> _chains = [];
  OpenInterestSummary? _summary;
  bool _isLoading = false;
  String _errorMessage = '';

  // Main UI states
  int _mainTabIndex = 0; // 0: TOP PROTOCOLS, 1: CHAIN
  String _selectedCategory = 'ALL';
  String _selectedChainFilter = 'ALL';
  String _searchQuery = '';

  // Active Sorting & Metrics
  String _oiMetric = 'total24h'; // 'total24h', 'total7d', 'total30d'
  String _changeMetric = 'change_7d'; // 'change_1d', 'change_7d', 'change_1m'
  String _sortType = 'oi'; // 'oi' or 'change'

  // Pagination
  int _currentPage = 1;
  int _itemsPerPage = 20;

  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  int get mainTabIndex => _mainTabIndex;
  String get selectedCategory => _selectedCategory;
  String get selectedChainFilter => _selectedChainFilter;
  String get searchQuery => _searchQuery;
  String get oiMetric => _oiMetric;
  String get changeMetric => _changeMetric;
  String get sortType => _sortType;
  int get currentPage => _currentPage;
  int get itemsPerPage => _itemsPerPage;
  OpenInterestSummary? get summary => _summary;
  List<OpenInterestChain> get chains => _chains;

  // Unique categories list derived dynamically
  List<String> get categories {
    final cats = {'ALL'};
    for (final p in _protocols) {
      if (p.category.isNotEmpty) {
        cats.add(p.category.toUpperCase());
      }
    }
    return cats.toList();
  }

  // Unique chains list derived dynamically for filters
  List<String> get chainOptions {
    final chs = {'ALL'};
    for (final c in _chains) {
      if (c.chain.isNotEmpty) {
        chs.add(c.chain);
      }
    }
    return chs.toList();
  }

  // Filtered & Sorted protocols list
  List<OpenInterestProtocol> get filteredProtocols {
    var list = List<OpenInterestProtocol>.from(_protocols);

    // Filter by Category
    if (_selectedCategory != 'ALL') {
      list = list.where((p) => p.category.toUpperCase() == _selectedCategory).toList();
    }

    // Filter by Chain
    if (_selectedChainFilter != 'ALL') {
      list = list.where((p) => p.chains.any((c) => c.toLowerCase() == _selectedChainFilter.toLowerCase())).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) =>
        p.displayName.toLowerCase().contains(q) ||
        p.name.toLowerCase().contains(q) ||
        p.category.toLowerCase().contains(q)
      ).toList();
    }

    // Sorting
    list.sort((a, b) {
      double valA = 0;
      double valB = 0;

      if (_sortType == 'oi') {
        if (_oiMetric == 'total24h') {
          valA = a.total24h;
          valB = b.total24h;
        } else if (_oiMetric == 'total7d') {
          valA = a.total7d;
          valB = b.total7d;
        } else {
          valA = a.total30d;
          valB = b.total30d;
        }
      } else {
        if (_changeMetric == 'change_1d') {
          valA = a.change1d;
          valB = b.change1d;
        } else if (_changeMetric == 'change_7d') {
          valA = a.change7d;
          valB = b.change7d;
        } else {
          valA = a.change1m;
          valB = b.change1m;
        }
      }

      // Descending sort
      return valB.compareTo(valA);
    });

    return list;
  }

  int get totalPages {
    final count = filteredProtocols.length;
    if (count == 0) return 1;
    return (count / _itemsPerPage).ceil();
  }

  List<OpenInterestProtocol> get paginatedProtocols {
    final list = filteredProtocols;
    final start = (_currentPage - 1) * _itemsPerPage;
    if (start >= list.length) return [];
    final end = (start + _itemsPerPage).clamp(0, list.length);
    return list.sublist(start, end);
  }

  // Chain view data sorted by totalOI descending
  List<OpenInterestChain> get sortedChains {
    final list = List<OpenInterestChain>.from(_chains);
    list.sort((a, b) => b.totalOI.compareTo(a.totalOI));
    return list;
  }

  // Actions
  void setMainTab(int index) {
    _mainTabIndex = index;
    _currentPage = 1;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category.toUpperCase();
    _currentPage = 1;
    notifyListeners();
  }

  void setSelectedChainFilter(String chain) {
    _selectedChainFilter = chain;
    _currentPage = 1;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _currentPage = 1;
    notifyListeners();
  }

  void setOiMetric(String metric) {
    _oiMetric = metric;
    _sortType = 'oi';
    notifyListeners();
  }

  void setChangeMetric(String metric) {
    _changeMetric = metric;
    _sortType = 'change';
    notifyListeners();
  }

  void setPage(int page) {
    if (page >= 1 && page <= totalPages) {
      _currentPage = page;
      notifyListeners();
    }
  }

  void setItemsPerPage(int limit) {
    if (limit > 0) {
      _itemsPerPage = limit;
      _currentPage = 1;
      notifyListeners();
    }
  }

  Future<void> fetchData() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Fetch summary stats
      _summary = await _service.fetchSummary();
      
      // Fetch chains overview
      _chains = await _service.fetchChains();

      // Fetch all protocols (limit 150 covers all)
      final response = await _service.fetchProtocols(limit: 150);
      _protocols = response.protocols;
    } catch (e) {
      _errorMessage = _getFriendlyErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _getFriendlyErrorMessage(Object e) {
    if (e is SocketException || e.toString().contains('SocketException')) {
      return 'Unable to connect to the server. Please check your internet connection.';
    } else if (e is ClientException || e.toString().contains('ClientException')) {
      return 'Connection failed. Please try again.';
    } else if (e.toString().contains('timeout')) {
      return 'The connection timed out. Please try again.';
    }
    return 'Failed to load Open Interest data: $e';
  }
}

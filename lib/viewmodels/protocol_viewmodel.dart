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
  
  // Filters
  int _limit = 20;
  String _selectedCategory = 'All Categories';
  List<String> _categories = ['All Categories'];
  bool _isAscending = false;

  // Category Distribution
  List<CategoryDistribution> _categoryDistribution = [];
  bool _isCategoryDistLoading = false;

  // Top Chains
  List<ChainTvl> _topChains = [];
  bool _isChainsLoading = false;

  List<Protocol> get protocols => _protocols;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  int get limit => _limit;
  String get selectedCategory => _selectedCategory;
  List<String> get categories => _categories;
  bool get isAscending => _isAscending;
  List<CategoryDistribution> get categoryDistribution => _categoryDistribution;
  bool get isCategoryDistLoading => _isCategoryDistLoading;
  List<ChainTvl> get topChains => _topChains;
  bool get isChainsLoading => _isChainsLoading;

  Future<void> fetchProtocols() async {
    _setLoading(true);
    _errorMessage = '';
    
    try {
      _protocols = await _service.getTopByTvl(
        limit: _limit,
        category: _selectedCategory,
      );
      
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
      _categories = ['All Categories', ...fetchedCategories];
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  void setLimit(int newLimit) {
    if (_limit == newLimit) return;
    _limit = newLimit;
    fetchProtocols();
  }

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    fetchProtocols();
  }

  void toggleSortOrder() {
    _isAscending = !_isAscending;
    _sortProtocols();
    notifyListeners();
  }

  void _sortProtocols() {
    if (_isAscending) {
      _protocols.sort((a, b) => a.tvl.compareTo(b.tvl));
    } else {
      _protocols.sort((a, b) => b.tvl.compareTo(a.tvl));
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
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

  List<Protocol> get protocols => _protocols;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  int get limit => _limit;
  String get selectedCategory => _selectedCategory;
  List<String> get categories => _categories;

  Future<void> fetchProtocols() async {
    _setLoading(true);
    _errorMessage = '';
    
    try {
      _protocols = await _service.getTopByTvl(
        limit: _limit,
        category: _selectedCategory,
      );
      
      // Fetch categories if we don't have them yet
      if (_categories.length == 1) {
        await _fetchCategories();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/trade_model.dart';

class TradesViewModel extends ChangeNotifier {
  final String symbol;
  List<Trade> _trades = [];
  bool _isLoading = false;
  String? _error;
  Timer? _pollTimer;
  bool _disposed = false;

  int _currentPage = 1;
  int _rowsPerPage = 10;

  TradesViewModel({required this.symbol});

  List<Trade> get trades => _trades;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get currentPage => _currentPage;
  int get rowsPerPage => _rowsPerPage;
  int get totalTrades => _trades.length;

  List<Trade> get paginatedTrades {
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    if (startIndex >= _trades.length) return [];
    final endIndex = (startIndex + _rowsPerPage > _trades.length) 
        ? _trades.length 
        : startIndex + _rowsPerPage;
    return _trades.sublist(startIndex, endIndex);
  }

  double get lastPrice => _trades.isNotEmpty ? _trades.first.price : 0.0;
  
  double get buyPercentage {
    if (_trades.isEmpty) return 50.0;
    final buys = _trades.where((t) => t.isBuy).length;
    return (buys / _trades.length) * 100;
  }

  double get sellPercentage => 100 - buyPercentage;

  double get vwap {
    if (_trades.isEmpty) return 0.0;
    double totalValue = 0;
    double totalSize = 0;
    for (var t in _trades) {
      totalValue += t.value;
      totalSize += t.size;
    }
    return totalSize > 0 ? totalValue / totalSize : 0.0;
  }

  void setPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  void setRowsPerPage(int count) {
    _rowsPerPage = count;
    _currentPage = 1;
    notifyListeners();
  }

  Future<void> startPolling() async {
    _isLoading = true;
    notifyListeners();
    
    await _fetchTrades();
    _isLoading = false;
    notifyListeners();

    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchTrades());
  }

  Future<void> _fetchTrades() async {
    if (_disposed) return;
    
    try {
      final baseUrl = dotenv.env['BASE_URL'] ?? 'http://localhost:4001';
      // Fetch more to support local pagination
      final url = Uri.parse('$baseUrl/api/trades/$symbol?limit=200');
      
      final response = await http.get(url);
      
      if (_disposed) return;

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true && decoded['data'] != null) {
          final List tradesJson = decoded['data']['trades'] ?? [];
          _trades = tradesJson.map((j) => Trade.fromJson(j)).toList();
          _error = null;
        }
      } else {
        _error = 'Server Error: ${response.statusCode}';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    super.dispose();
  }
}

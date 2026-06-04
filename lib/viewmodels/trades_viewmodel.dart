import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/trade_model.dart';
import '../services/trades_service.dart';

class TradesViewModel extends ChangeNotifier {
  final String symbol;
  final String? dex;

  final TradesService _tradesService;
  List<Trade> _trades = [];
  bool _isLoading = false;
  String? _error;
  bool _disposed = false;

  int _currentPage = 1;
  int _rowsPerPage = 10;

  TradesViewModel({required this.symbol, this.dex})
      : _tradesService = TradesService(symbol: symbol, dex: dex);

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
    for (final t in _trades) {
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

  Future<void> startUpdates() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await _tradesService.start(
      onSnapshot: (snapshot) {
        _handleSnapshot(snapshot);
        _isLoading = false;
        notifyListeners();
      },
      onUpdates: (updates) {
        _handleUpdates(updates);
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );

    // Timeout if trades list is still empty after a while
    Future.delayed(const Duration(seconds: 10), () {
      if (_disposed) return;
      if (_isLoading && _trades.isEmpty) {
        _isLoading = false;
        notifyListeners();
      }
    });

    _isLoading = false;
    notifyListeners();
  }

  void _handleSnapshot(List<Trade> snapshot) {
    if (_disposed) return;
    // Strictly follow breakdown: snapshots REPLACE the entire list
    _trades = snapshot;
    if (_trades.length > 50) {
      _trades = _trades.sublist(0, 50);
    }
    _sortTrades();
    notifyListeners();
  }

  void _handleUpdates(List<Trade> updates) {
    if (_disposed) return;
    
    // Deduplication key: ${trade.time}-${trade.hash ?? trade.price}
    final existingKeys = _trades.map((t) => _getTradeKey(t)).toSet();
    
    final newTrades = updates.where((t) {
      final key = _getTradeKey(t);
      return !existingKeys.contains(key);
    }).toList();

    if (newTrades.isNotEmpty) {
      _trades.insertAll(0, newTrades);
      _sortTrades();
      
      // Breakdown requirement: Keep max 50
      if (_trades.length > 50) {
        _trades = _trades.sublist(0, 50);
      }
      notifyListeners();
    }
  }

  String _getTradeKey(Trade t) {
    return '${t.time}-${t.hash ?? t.price}';
  }

  void _sortTrades() {
    _trades.sort((a, b) => b.time.compareTo(a.time));
  }

  @override
  void dispose() {
    _disposed = true;
    _tradesService.dispose();
    super.dispose();
  }
}

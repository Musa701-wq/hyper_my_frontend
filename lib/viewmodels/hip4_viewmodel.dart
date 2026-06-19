import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/hip4_model.dart';
import '../utils/app_config.dart';
import '../utils/app_exceptions.dart';

class Hip4ViewModel extends ChangeNotifier {
  List<Hip4Market> _markets = [];
  bool _isLoading = false;
  String _errorMessage = '';
  WebSocketChannel? _channel;
  Timer? _refreshTimer;

  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _sortColumn = 'probability';
  bool _sortAscending = false;

  final List<String> categories = ['All', 'Crypto', 'Sports', 'Custom'];

  String get sortColumn => _sortColumn;
  bool get sortAscending => _sortAscending;

  void setSort(String column) {
    if (_sortColumn == column) {
      _sortAscending = !_sortAscending;
    } else {
      _sortColumn = column;
      _sortAscending = true;
    }
    notifyListeners();
  }

  List<Hip4Market> get markets => _markets;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  List<Hip4Market> get filteredMarkets {
    var list = _markets.where((m) {
      final matchesCategory = _selectedCategory == 'All' || 
          m.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty || 
          m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.id.toString().contains(_searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();

    // Apply sort
    list.sort((a, b) {
      int cmp;
      switch (_sortColumn) {
        case 'probability':
          // Sort by highest single outcome probability
          final aMax = a.outcomes.isEmpty ? 0.0 : a.outcomes.map((o) => o.probability).reduce((x, y) => x > y ? x : y);
          final bMax = b.outcomes.isEmpty ? 0.0 : b.outcomes.map((o) => o.probability).reduce((x, y) => x > y ? x : y);
          cmp = aMax.compareTo(bMax);
          break;
        case 'expiry':
          final aT = a.expiry?.millisecondsSinceEpoch ?? 0;
          final bT = b.expiry?.millisecondsSinceEpoch ?? 0;
          cmp = aT.compareTo(bT);
          break;
        default:
          cmp = a.name.compareTo(b.name);
      }
      return _sortAscending ? cmp : -cmp;
    });

    return list;
  }

  Future<void> init() async {
    await fetchMarkets();
    _startRefreshTimer();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchMarkets() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final baseUrl = AppConfig.baseUrl; // Using proxy worker API
      final response = await http.get(
        Uri.parse('$baseUrl/api/hip4/markets'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        List<dynamic> jsonList = [];
        if (decoded is List) {
          jsonList = decoded;
        } else if (decoded is Map<String, dynamic> && decoded['data'] is List) {
          jsonList = decoded['data'];
        }

        _markets = jsonList.map((m) => Hip4Market.fromJson(m)).toList();
        _connectWebSocket();
      } else {
        _errorMessage = 'Failed to load markets: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = AppException.fromError(e).message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _connectWebSocket() {
    _channel?.sink.close();
    try {
      final baseUrl = AppConfig.baseUrl; // e.g. https://coingecko.renderonnodes.com
      final domain = baseUrl.split('//').last;
      final protocol = baseUrl.startsWith('https') ? 'wss' : 'ws';
      final wsUrl = '$protocol://$domain/hip4';
      
      debugPrint('Connecting to HIP4 WS: $wsUrl');
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel?.stream.listen(
        (message) {
          final decoded = json.decode(message);
          if (decoded is Map<String, dynamic>) {
            if ((decoded['type'] == 'hip4_snapshot' || decoded['type'] == 'hip4_update') && decoded['data'] is List) {
              _handleUpdate(decoded['data']);
            }
          }
        },
        onError: (e) => debugPrint('HIP4 WS error: $e'),
        onDone: () => debugPrint('HIP4 WS closed'),
      );
    } catch (e) {
      debugPrint('HIP4 WS connect error: $e');
    }
  }

  void _handleUpdate(List<dynamic> data) {
    _markets = data.map((m) => Hip4Market.fromJson(m)).toList();
    notifyListeners();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      fetchMarkets();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/ticker_model.dart';
import '../utils/app_exceptions.dart';

class HomeViewModel extends ChangeNotifier {
  List<TickerModel> _tickers = [];
  bool _isLoading = false;
  String _errorMessage = '';
  WebSocketChannel? _channel;

  String _selectedTab = 'HIP';
  String _selectedDex = 'All';
  List<String> _availableDexes = ['All'];
  
  String _selectedCryptoCategory = 'All';
  List<String> _cryptoCategories = ['All'];

  String _searchQuery = '';
  int _rowsPerPage = 10;
  int _currentPage = 1;

  List<TickerModel> get tickers => _tickers;
  String get selectedTab => _selectedTab;
  List<TickerModel> get filteredTickers {
    List<TickerModel> list = _tickers;
    
    // Dex Filter
    if (_selectedDex != 'All') {
      list = list.where((t) => t.dex == _selectedDex).toList();
    }
    
    // Search Filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((t) => 
        t.symbol.toLowerCase().contains(query) || 
        t.displayName.toLowerCase().contains(query)
      ).toList();
    }
    
    // Category Filter (only for Crypto tab)
    if (_selectedTab == 'CRYPTO' && _selectedCryptoCategory != 'All') {
      list = list.where((t) => t.cryptoCategory.toLowerCase() == _selectedCryptoCategory.toLowerCase().replaceAll(' ', '')).toList();
    }
    
    return list;
  }
  
  List<TickerModel> get paginatedTickers {
    final list = filteredTickers;
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    if (startIndex >= list.length) return [];
    
    final endIndex = (startIndex + _rowsPerPage > list.length) ? list.length : startIndex + _rowsPerPage;
    return list.sublist(startIndex, endIndex);
  }

  int get totalFilteredCount => filteredTickers.length;
  
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get selectedDex => _selectedDex;
  List<String> get availableDexes => _availableDexes;
  int get currentPage => _currentPage;
  int get rowsPerPage => _rowsPerPage;
  String get searchQuery => _searchQuery;
  String get selectedCryptoCategory => _selectedCryptoCategory;
  List<String> get cryptoCategories => _cryptoCategories;

  void setTab(String tab) {
    if (_selectedTab == tab) return;
    _selectedTab = tab;
    _currentPage = 1;
    _selectedDex = 'All';
    _selectedCryptoCategory = 'All';
    _searchQuery = '';
    fetchTickers();
  }

  Future<void> fetchTickers() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final baseUrl = dotenv.env['BASE_URL'] ?? 'http://localhost:4000';
      // HIP uses port 4000 (usually) and /hip3/all
      // PERPS and SPOT use port 4001
      final url = _selectedTab == 'HIP' 
          ? '$baseUrl/hip3/all' 
          : _selectedTab == 'PERPS'
              ? 'http://localhost:4001/perps'
              : _selectedTab == 'CRYPTO'
                  ? 'http://localhost:4001/crypto'
                  : 'http://localhost:4001/spot';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        List<dynamic> jsonList = [];
        
        if (decoded is List) {
          jsonList = decoded;
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['success'] == true && decoded['data'] != null) {
            jsonList = decoded['data'];
          } else {
            jsonList = decoded['data'] ?? [];
          }
        }

        debugPrint('Initial API data fetched successfully for $_selectedTab, count: ${jsonList.length}');
        _tickers = jsonList.map((json) => TickerModel.fromJson(json)).toList();
        _extractDexes();
        _extractCategories();
      } else {
        _errorMessage = 'Server Error (${response.statusCode}): Please try again later.';
      }
    } catch (e) {
      _errorMessage = AppException.fromError(e).message;
    } finally {
      _isLoading = false;
      notifyListeners();
      _connectWebSocket();
    }
  }

  void _connectWebSocket() {
    try {
      // Close existing connection if any
      _channel?.sink.close();

      final wsUrl = _selectedTab == 'HIP'
          ? (dotenv.env['WS_URL'] ?? 'ws://localhost:4000')
          : 'http://localhost:4001'.replaceFirst('http', 'ws'); // Fallback to ws version of rest url
      
      debugPrint('Connecting to WebSocket: $wsUrl for tab $_selectedTab');
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel?.stream.listen(
        (message) {
          try {
            final dynamic decoded = json.decode(message);
            bool updated = false;
            
            if (decoded is Map<String, dynamic>) {
              // Handle standard markets_update format
              if (decoded['type'] == 'markets_update' && decoded['data'] is List) {
                 final List dataList = decoded['data'];
                 for (var update in dataList) {
                    if (update is Map<String, dynamic>) {
                       if (_handleWsUpdate(update)) updated = true;
                    }
                 }
              } 
              // Handle flat map format or other types
              else {
                 if (_handleWsUpdate(decoded)) updated = true;
              }
            } else if (decoded is List) {
               for (var update in decoded) {
                  if (update is Map<String, dynamic>) {
                     if (_handleWsUpdate(update)) updated = true;
                  }
               }
            }

            if (updated) notifyListeners();
          } catch (e) {
            debugPrint("Data parsing error in WS: $e");
          }
        },
        onError: (error) {
          debugPrint('WebSocket ERROR ($wsUrl): $error');
        },
        onDone: () {
          debugPrint('WebSocket connection CLOSED ($wsUrl).');
        },
      );
    } catch (e) {
      debugPrint('Failed to connect to WebSocket: $e');
    }
  }

  bool _handleWsUpdate(Map<String, dynamic> updateData) {
    // Find ticker by _id or symbol
    final index = _tickers.indexWhere((t) => 
      (updateData['_id'] != null && t.id == updateData['_id']) ||
      (updateData['symbol'] != null && t.symbol == updateData['symbol'])
    );

    if (index != -1) {
      debugPrint('WS MATCH FOUND: ${updateData['symbol'] ?? updateData['_id']}');
      _tickers[index] = _tickers[index].copyWithPartial(updateData);
      return true;
    } else {
      // If it's a new ticker completely and has essential data
      if (updateData['symbol'] != null && (updateData['dex'] != null || updateData['marketType'] != null)) {
        _tickers.add(TickerModel.fromJson(updateData));
        _extractDexes();
        return true;
      }
    }
    return false;
  }

  void _extractDexes() {
    final Set<String> dexSet = {'All'};
    for (var ticker in _tickers) {
      if (ticker.dex.isNotEmpty) {
        dexSet.add(ticker.dex);
      }
    }
    _availableDexes = dexSet.toList();
  }
  
  void _extractCategories() {
    final Set<String> categorySet = {'All'};
    for (var ticker in _tickers) {
      if (ticker.cryptoCategory.isNotEmpty) {
        // Format to Title Case for UI (e.g., 'layer1' -> 'Layer 1', 'defi' -> 'Defi')
        String cat = ticker.cryptoCategory;
        if (cat == 'layer1') cat = 'Layer 1';
        if (cat == 'layer2') cat = 'Layer 2';
        if (cat == 'defi') cat = 'Defi';
        if (cat == 'ai') cat = 'AI';
        if (cat == 'gaming') cat = 'Gaming';
        if (cat == 'meme') cat = 'Meme';
        
        // Capitalize first letter if not specifically handled
        if (cat.length > 0 && cat == ticker.cryptoCategory) {
           cat = cat[0].toUpperCase() + cat.substring(1);
        }
        
        categorySet.add(cat);
      }
    }
    _cryptoCategories = categorySet.toList();
    
    // Sort to keep 'All' first then alphabetical
    _cryptoCategories.sort((a, b) {
      if (a == 'All') return -1;
      if (b == 'All') return 1;
      return a.compareTo(b);
    });
  }

  void setSelectedCryptoCategory(String category) {
    if (_cryptoCategories.contains(category)) {
      _selectedCryptoCategory = category;
      _currentPage = 1;
      notifyListeners();
    }
  }

  void setSelectedDex(String dex) {
    if (_availableDexes.contains(dex)) {
      _selectedDex = dex;
      _currentPage = 1; // Reset to first page
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _currentPage = 1; // Reset to first page
    notifyListeners();
  }

  void setRowsPerPage(int count) {
    _rowsPerPage = count;
    _currentPage = 1; // Reset to first page when changing page size
    notifyListeners();
  }

  void nextPage() {
    if (_currentPage * _rowsPerPage < totalFilteredCount) {
      _currentPage++;
      notifyListeners();
    }
  }

  void previousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }
}

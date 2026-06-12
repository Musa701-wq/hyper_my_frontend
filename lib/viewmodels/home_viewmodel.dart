import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/app_config.dart';
import '../models/ticker_model.dart';
import '../models/trader_distribution_model.dart';
import '../utils/app_exceptions.dart';

class HomeViewModel extends ChangeNotifier {
  List<TickerModel> _tickers = [];
  bool _isLoading = false;
  String _errorMessage = '';
  WebSocketChannel? _channel;

  // Per-tab cache to speed up switching
  final Map<String, List<TickerModel>> _tabCache = {};
  DateTime? _lastFetchTime;
  static const _cacheDuration = Duration(minutes: 2);

  String _selectedTab = 'ALL';
  String _selectedDex = 'All';
  List<String> _availableDexes = ['All'];
  
  String _selectedCryptoCategory = 'All';
  List<String> _cryptoCategories = ['All', 'xyz', 'flx', 'vntl', 'hyna', 'km', 'cash', 'para'];

  String _searchQuery = '';
  int _rowsPerPage = 10;
  int _currentPage = 1;
  
  TraderDistributionModel? _volumeDist;
  TraderDistributionModel? _valueDist;
  bool _isDistLoading = false;
  
  String _sortColumn = 'volume24hUSD';
  bool _isAscending = false;

  List<TickerModel> get tickers => _tickers;
  TraderDistributionModel? get volumeDist => _volumeDist;
  TraderDistributionModel? get valueDist => _valueDist;
  bool get isDistLoading => _isDistLoading;
  String get selectedTab => _selectedTab;

  // All tickers unfiltered
  List<TickerModel> get allTickers => _tickers;

  // Gainers/Losers helpers
  List<TickerModel> get gainers {
    final sorted = _tickers.where((t) => t.change24hPct > 0).toList()
      ..sort((a, b) => b.change24hPct.compareTo(a.change24hPct));
    return sorted;
  }

  List<TickerModel> get losers {
    final sorted = _tickers.where((t) => t.change24hPct < 0).toList()
      ..sort((a, b) => a.change24hPct.compareTo(b.change24hPct));
    return sorted;
  }

  int get gainersCount => _tickers.where((t) => t.change24hPct > 0).length;
  int get losersCount => _tickers.where((t) => t.change24hPct < 0).length;
  double get totalVolume =>
      _tickers.fold(0, (sum, t) => sum + t.volume24hUSD);

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
    
    // Category/Dex Filter
    if ((_selectedTab == 'CRYPTO' || _selectedTab == 'HIP-3') && _selectedCryptoCategory != 'All') {
      final query = _selectedCryptoCategory.toLowerCase().trim();
      list = list.where((t) {
        if (_selectedTab == 'HIP-3') {
          return t.dex.toLowerCase().contains(query);
        } else {
          return t.cryptoCategory.toLowerCase().contains(query);
        }
      }).toList();
    }
    
    // Sorting
    list.sort((a, b) {
      dynamic valA;
      dynamic valB;

      switch (_sortColumn) {
        case 'symbol':
          valA = a.symbol;
          valB = b.symbol;
          break;
        case 'lastPrice':
          valA = a.lastPrice;
          valB = b.lastPrice;
          break;
        case 'change24hPct':
          valA = a.change24hPct;
          valB = b.change24hPct;
          break;
        case 'funding8hPct':
          valA = a.funding8hPct;
          valB = b.funding8hPct;
          break;
        case 'volume24hUSD':
          valA = a.volume24hUSD;
          valB = b.volume24hUSD;
          break;
        case 'openInterestUSD':
          valA = a.openInterestUSD;
          valB = b.openInterestUSD;
          break;
        default:
          valA = a.volume24hUSD;
          valB = b.volume24hUSD;
      }

      int cmp;
      if (valA is String) {
        cmp = valA.compareTo(valB);
      } else {
        cmp = (valA as num).compareTo(valB as num);
      }

      return _isAscending ? cmp : -cmp;
    });

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
  String get sortColumn => _sortColumn;
  bool get isAscending => _isAscending;

  void setSortColumn(String column) {
    if (_sortColumn == column) {
      _isAscending = !_isAscending;
    } else {
      _sortColumn = column;
      _isAscending = false; // Default to descending for numbers
    }
    notifyListeners();
  }

  void setTab(String tab) {
    if (_selectedTab == tab) return;
    _selectedTab = tab;
    
    // Populate categories instantly (especially for HIP-3 hardcoded list)
    _extractCategories();
    
    _currentPage = 1;
    _selectedDex = 'All';
    _selectedCryptoCategory = 'All';
    _searchQuery = '';
    fetchTickers();
  }

  Future<void> fetchTickers({bool forceRefresh = false}) async {
    if (_isLoading) return;

    // Serve cache instantly if available and not expired
    final cached = _tabCache[_selectedTab];
    final isCacheValid = _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration;
    if (cached != null && !forceRefresh && isCacheValid) {
      _tickers = cached;
      _extractDexes();
      _extractCategories();
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    const maxAttempts = 3;
    const retryDelays = [Duration(seconds: 2), Duration(seconds: 4)];

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final baseUrl = AppConfig.baseUrl;
        final hipBaseUrl = AppConfig.hipBaseUrl;

        final url = _selectedTab == 'ALL'
            ? '$baseUrl/all'
            : _selectedTab == 'HIP-3'
                ? '$hipBaseUrl/hip3/all'
                : _selectedTab == 'PERPS'
                    ? '$baseUrl/perps'
                    : _selectedTab == 'CRYPTO'
                        ? '$baseUrl/crypto'
                        : _selectedTab == 'TRADFI'
                            ? '$baseUrl/tradfi'
                            : '$baseUrl/spot';

        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 15));

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

          debugPrint('API data fetched for $_selectedTab, count: ${jsonList.length}');
          if (_selectedTab == 'HIP-3' && jsonList.isNotEmpty) {
            debugPrint('DEBUG HIP-3 FIRST TICKER: ${jsonList[0]}');
          }
          _tickers = jsonList.map((json) => TickerModel.fromJson(json)).toList();
          _tabCache[_selectedTab] = _tickers;
          _lastFetchTime = DateTime.now();
          _extractDexes();
          _extractCategories();
          _errorMessage = '';
          break; // success — exit retry loop
        } else {
          _errorMessage = 'Server Error (${response.statusCode}): Please try again later.';
          // Don't retry on 4xx/5xx — it's a server issue not a network issue
          break;
        }
      } catch (e) {
        debugPrint('fetchTickers attempt ${attempt + 1} failed: $e');
        if (attempt < maxAttempts - 1) {
          // Wait before retry — network might not be ready yet
          await Future<void>.delayed(retryDelays[attempt]);
          continue;
        }
        _errorMessage = AppException.fromError(e).message;
      }
    }

    _isLoading = false;
    notifyListeners();
    _connectWebSocket();
    
    // Also fetch distributions
    if (_selectedTab == 'ALL' || _selectedTab == 'HIP-3') {
      fetchTraderDistribution();
    }
  }

  Future<void> fetchTraderDistribution({String period = 'allTime'}) async {
    if (_isDistLoading) return;
    _isDistLoading = true;
    notifyListeners();

    try {
      final hipBaseUrl = AppConfig.hipBaseUrl;
      
      // Fetch distributions independently so one failure doesn't block the other
      await Future.wait([
        _fetchVolumeDist(hipBaseUrl, period),
        _fetchValueDist(hipBaseUrl, period),
      ]);
    } catch (e) {
      debugPrint('Trader distributions fetch wrapper failed: $e');
    } finally {
      _isDistLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchVolumeDist(String baseUrl, String period) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/leaderboard/volume/distribution?period=$period')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        _volumeDist = TraderDistributionModel.fromJson(json.decode(response.body));
        debugPrint('Volume distribution loaded successfully');
      } else {
        debugPrint('Volume distribution API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Volume distribution fetch failed: $e');
    }
  }

  Future<void> _fetchValueDist(String baseUrl, String period) async {
    try {
      // CHART 1: Trader Distribution By Account Value
      final response = await http.get(Uri.parse('$baseUrl/leaderboard/traders/distribution')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        _valueDist = TraderDistributionModel.fromJson(json.decode(response.body));
        debugPrint('Trader (Value) distribution loaded successfully');
      } else {
        debugPrint('Trader (Value) distribution API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Trader (Value) distribution fetch failed: $e');
    }
  }

  void _connectWebSocket() {
    _channel?.sink.close();
    _scheduleWsConnect(attempt: 0);
  }

  static const _wsMaxRetries = 6;
  // Backoff: 2s, 4s, 8s, 16s, 30s, 30s
  static const _wsBackoff = [2, 4, 8, 16, 30, 30];

  void _scheduleWsConnect({required int attempt}) {
    final delay = attempt == 0
        ? Duration.zero
        : Duration(seconds: _wsBackoff[(attempt - 1).clamp(0, _wsBackoff.length - 1)]);

    Future.delayed(delay, () => _doWsConnect(attempt: attempt));
  }

  void _doWsConnect({required int attempt}) {
    // Guard against stale retry after tab switch or dispose
    if (_isLoading) return;

    try {
      String wsUrl = (_selectedTab == 'HIP-3')
          ? AppConfig.hipWsUrl
          : AppConfig.wsUrl;
      if (!wsUrl.endsWith('/')) wsUrl += '/';

      debugPrint('Connecting to WebSocket: $wsUrl for tab $_selectedTab (attempt ${attempt + 1})');
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel?.stream.listen(
        (message) {
          try {
            final dynamic decoded = json.decode(message);
            bool updated = false;

            if (decoded is Map<String, dynamic>) {
              if (decoded['channel'] == 'allMids' &&
                  decoded['data'] != null &&
                  decoded['data']['mids'] != null) {
                final Map<String, dynamic> mids = decoded['data']['mids'];
                mids.forEach((symbol, price) {
                  final idx = _tickers.indexWhere((t) => t.symbol == symbol);
                   if (idx != -1) {
                    final newPrice = double.tryParse(price.toString()) ?? 0.0;
                    double newChange = _tickers[idx].change24hPct;
                    
                    // Recalculate change percentage if we have previous day price
                    if (_tickers[idx].prevDayPx > 0) {
                      newChange = ((newPrice - _tickers[idx].prevDayPx) / _tickers[idx].prevDayPx) * 100;
                    }

                    _tickers[idx] = _tickers[idx].copyWithPartial({
                      'lastPrice': newPrice,
                      'change24hPct': newChange,
                    });
                    updated = true;
                  }
                });
              } else if (decoded['type'] == 'markets_update' && decoded['data'] is List) {
                final List dataList = decoded['data'];
                for (var update in dataList) {
                  if (update is Map<String, dynamic>) {
                    if (_handleWsUpdate(update)) updated = true;
                  }
                }
              } else {
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
            debugPrint('WS data parse error: $e');
          }
        },
        onError: (error) {
          debugPrint('WebSocket ERROR ($wsUrl): $error');
          _retryWsIfNeeded(attempt: attempt);
        },
        onDone: () {
          debugPrint('WebSocket CLOSED ($wsUrl).');
          // Auto-reconnect on unexpected close (not a manual dispose)
          _retryWsIfNeeded(attempt: attempt);
        },
        cancelOnError: true,
      );

      if (_selectedTab == 'HIP-3') {
        final subMessage = json.encode({
          "method": "subscribe",
          "subscription": {"type": "allMids"}
        });
        _channel?.sink.add(subMessage);
      }
    } catch (e) {
      // Catches synchronous errors from WebSocketChannel.connect() itself
      // (e.g. SocketException / DNS failure on connect)
      debugPrint('WebSocket connect threw synchronously: $e');
      _retryWsIfNeeded(attempt: attempt);
    }
  }

  void _retryWsIfNeeded({required int attempt}) {
    if (attempt >= _wsMaxRetries) {
      debugPrint('WebSocket: max retries reached, giving up.');
      return;
    }
    final nextDelay = _wsBackoff[attempt.clamp(0, _wsBackoff.length - 1)];
    debugPrint('WebSocket: retrying in ${nextDelay}s (attempt ${attempt + 2})');
    _scheduleWsConnect(attempt: attempt + 1);
  }

  bool _handleWsUpdate(Map<String, dynamic> updateData) {
    // Find ticker by _id or symbol
    final index = _tickers.indexWhere((t) => 
      (updateData['_id'] != null && t.id == updateData['_id']) ||
      (updateData['symbol'] != null && t.symbol == updateData['symbol'])
    );

    if (index != -1) {
      final oldTicker = _tickers[index];
      final Map<String, dynamic> mergedData = Map.from(updateData);
      
      // If price is updated but change isn't, recalculate change
      if (mergedData.containsKey('lastPrice') && !mergedData.containsKey('change24hPct')) {
        final newPrice = _toDouble(mergedData['lastPrice']);
        if (oldTicker.prevDayPx > 0) {
          mergedData['change24hPct'] = ((newPrice - oldTicker.prevDayPx) / oldTicker.prevDayPx) * 100;
        }
      }

      _tickers[index] = oldTicker.copyWithPartial(mergedData);
      _extractDexes();
      _extractCategories();
      return true;
    } else {
      // Logic for adding new tickers from WS:
      // Only add if it matches the current tab's characteristics
      bool shouldAdd = _selectedTab == 'ALL';
      if (_selectedTab == 'HIP-3' && updateData['dex'] != null) shouldAdd = true;
      if (_selectedTab == 'CRYPTO' && updateData['cryptoCategory'] != null) shouldAdd = true;
      
      if (shouldAdd && updateData['symbol'] != null) {
        _tickers.add(TickerModel.fromJson(updateData));
        _extractDexes();
        _extractCategories();
        return true;
      }
    }
    return false;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
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
    
    if (_selectedTab == 'HIP-3') {
      // For HIP-3, categories are actually in the 'dex' field
      // We start with the user's preferred list and add any new ones from the data
      categorySet.addAll(['xyz', 'flx', 'vntl', 'hyna', 'km', 'cash', 'para']);
      for (var ticker in _tickers) {
        if (ticker.dex.isNotEmpty && ticker.dex != 'hyperliquid') {
          categorySet.add(ticker.dex);
        }
      }
    } else {
      // Original logic for CRYPTO and others
      for (var ticker in _tickers) {
        if (ticker.cryptoCategory.isNotEmpty) {
          String cat = ticker.cryptoCategory;
          
          if (_selectedTab == 'CRYPTO') {
            if (cat == 'layer1') cat = 'Layer 1';
            if (cat == 'layer2') cat = 'Layer 2';
            if (cat == 'defi') cat = 'Defi';
            if (cat == 'ai') cat = 'AI';
            if (cat == 'gaming') cat = 'Gaming';
            if (cat == 'meme') cat = 'Meme';
            
            if (cat.length > 0 && cat == ticker.cryptoCategory) {
              cat = cat[0].toUpperCase() + cat.substring(1);
            }
          }
          categorySet.add(cat);
        }
      }
    }
    
    _cryptoCategories = categorySet.toList();
    
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

  void setPage(int page) {
    _currentPage = page;
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

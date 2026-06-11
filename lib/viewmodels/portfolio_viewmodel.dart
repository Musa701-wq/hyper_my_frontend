import 'dart:async';

import 'package:flutter/material.dart';
import '../models/portfolio_summary_model.dart';
import '../models/portfolio_history_model.dart';
import '../models/leaderboard_model.dart';
import '../services/portfolio_cache.dart';
import '../services/portfolio_service.dart';
import '../services/leaderboard_service.dart';

class AssetCompositionItem {
  final String coin;
  final double usdValue;
  final double percentage;
  final Color color;

  AssetCompositionItem({required this.coin, required this.usdValue, required this.percentage, required this.color});
}

class SymbolTradeSummary {
  final String symbol;
  int trades = 0;
  double volume = 0;
  double pnl = 0;
  int wins = 0;
  double best = -999999999;
  double worst = 999999999;
  double fees = 0;

  SymbolTradeSummary({required this.symbol});

  double get winRate => trades > 0 ? (wins / trades * 100) : 0;
}

class PerformanceMetrics {
  final double winRate;
  final int totalWins;
  final int totalTrades;
  final double profitFactor;
  final double avgWin;
  final double avgLoss;
  final double largestWin;
  final String largestWinCoin;
  final double largestLoss;
  final String largestLossCoin;
  final List<double> winSparkline;
  final List<double> lossSparkline;
  final double totalVolume;
  final double totalFees;

  PerformanceMetrics({
    this.winRate = 0,
    this.totalWins = 0,
    this.totalTrades = 0,
    this.profitFactor = 0,
    this.avgWin = 0,
    this.avgLoss = 0,
    this.largestWin = 0,
    this.largestWinCoin = '',
    this.largestLoss = 0,
    this.largestLossCoin = '',
    this.winSparkline = const [],
    this.lossSparkline = const [],
    this.totalVolume = 0,
    this.totalFees = 0,
  });
}

class RiskMetrics {
  final double leverageRisk;
  final double concentrationRisk;
  final double marginUsage;
  final double volatilityRisk;

  RiskMetrics({
    this.leverageRisk = 0,
    this.concentrationRisk = 0,
    this.marginUsage = 0,
    this.volatilityRisk = 0,
  });
}

enum PortfolioTimeRange { hour, day, week, month, year, all }

class PortfolioViewModel extends ChangeNotifier {
  final PortfolioService _service = PortfolioService();
  final LeaderboardService _leaderboardService = LeaderboardService();

  PortfolioSummaryModel? _summary;
  PortfolioHistoryModel? _history;
  List<SymbolTradeSummary> _symbolSummaries = [];

  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  Timer? _refreshTimer;
  DateTime? _lastFetchTime;

  static const _refreshInterval = Duration(seconds: 30);

  PortfolioSummaryModel? get summary => _summary;
  PortfolioHistoryModel? get history => _history;
  List<SymbolTradeSummary> get symbolSummaries => _symbolSummaries;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get hasData => _summary != null;
  String? get error => _error;
  DateTime? get lastFetchTime => _lastFetchTime;

  List<TraderSnapshot> _snapshots = [];
  List<TraderSnapshot> get snapshots => _snapshots;

  // Processed snapshot chart series
  List<double> _snapshotValueSeries = [];
  List<int> _snapshotTimestamps = [];
  List<double> get snapshotValueSeries => _snapshotValueSeries;
  List<int> get snapshotTimestamps => _snapshotTimestamps;

  List<double> _combinedPnlSeries = [];
  List<double> _perpPnlSeries = [];
  List<double> _accountValueSeries = [];
  List<int> _historyTimestamps = [];
  List<TradeFill> _historyFills = [];

  List<double> get combinedPnlSeries => _combinedPnlSeries;
  List<double> get perpPnlSeries => _perpPnlSeries;
  List<double> get accountValueSeries => _accountValueSeries;
  List<int> get historyTimestamps => _historyTimestamps;
  List<TradeFill> get historyFills => _historyFills;

  PortfolioTimeRange _selectedRange = PortfolioTimeRange.all;
  PortfolioTimeRange get selectedRange => _selectedRange;

  double _currentVolume = 0;
  double _allChange = 0;
  double get currentVolume => _currentVolume;
  double get allChange => _allChange;

  List<AssetCompositionItem> _assetComposition = [];
  List<AssetCompositionItem> get assetComposition => _assetComposition;

  PerformanceMetrics _performanceMetrics = PerformanceMetrics();
  PerformanceMetrics get performanceMetrics => _performanceMetrics;

  RiskMetrics _riskMetrics = RiskMetrics();
  RiskMetrics get riskMetrics => _riskMetrics;

  /// Cache-first load, then network refresh + 30s auto-refresh.
  Future<void> initializePortfolio(String wallet) async {
    await _loadFromCache(wallet);
    await fetchPortfolio(wallet);
    // Auto-retry once if first fetch failed and no cached data
    if (_error != null && !_hasData) {
      await Future.delayed(const Duration(seconds: 2));
      await fetchPortfolio(wallet, force: true);
    }
    _startAutoRefresh(wallet);
  }

  bool get _hasData => _summary != null;

  Future<void> _loadFromCache(String wallet) async {
    final cached = await PortfolioCache.load(wallet);
    if (cached == null) return;
    _summary = cached.summary;
    _history = cached.history;
    _error = null;
    _processHistory();
    notifyListeners();
  }

  void _startAutoRefresh(String wallet) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      fetchPortfolio(wallet, silent: true);
    });
  }

  void setTimeRange(PortfolioTimeRange range) {
    _selectedRange = range;
    _processHistory();
    notifyListeners();
  }

  Future<void> fetchPortfolio(String wallet, {bool silent = false, bool force = false}) async {
    // If not forced, check if we fetched within the last 5 minutes
    if (!force && _lastFetchTime != null && _summary != null) {
      final difference = DateTime.now().difference(_lastFetchTime!);
      if (difference.inMinutes < 5) {
        debugPrint('Using cached portfolio data (${difference.inMinutes}m old)');
        return;
      }
    }

    final hasData = _summary != null;

    if (!hasData) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    } else {
      _isRefreshing = true;
      notifyListeners();
    }

    try {
      final results = await Future.wait([
        _service.getPortfolioSummary(wallet),
        _service.getPortfolioHistory(wallet),
      ]);

      _summary = results[0] as PortfolioSummaryModel;
      _history = results[1] as PortfolioHistoryModel;
      _error = null;

      // Fallback calculation for withdrawable if API returns 0
      if (_summary!.withdrawable == 0 && _summary!.totalBalance > 0) {
        final double calculatedWithdrawable = (_summary!.totalBalance - _summary!.totalMarginUsed).clamp(0.0, double.infinity);
        debugPrint('⚠️ [PortfolioVM] API returned withdrawable=0, using fallback: $calculatedWithdrawable');
        
        // Re-create summary with calculated value
        _summary = PortfolioSummaryModel(
          walletAddress: _summary!.walletAddress,
          totalBalance: _summary!.totalBalance,
          perpAccountValue: _summary!.perpAccountValue,
          spotUSDValue: _summary!.spotUSDValue,
          unrealizedPnl: _summary!.unrealizedPnl,
          unrealizedPnlPct: _summary!.unrealizedPnlPct,
          buyingPower: calculatedWithdrawable, 
          withdrawable: calculatedWithdrawable,
          marginUsed: _summary!.marginUsed,
          totalMarginUsed: _summary!.totalMarginUsed,
          positions: _summary!.positions,
          spotBalances: _summary!.spotBalances,
          openOrders: _summary!.openOrders,
          fetchedAt: _summary!.fetchedAt,
          isStale: _summary!.isStale,
        );
      }

      await PortfolioCache.save(wallet: wallet, summary: _summary!, history: _history!);
      _processHistory();
      _lastFetchTime = DateTime.now();
    } catch (e) {
      if (!hasData) {
        if (e.toString().contains('Connection refused') || e.toString().contains('errno = 61')) {
          _error = 'Connection failed. Please ensure your data service is active and try again.';
        } else {
          _error = 'Unable to load portfolio data. Tap retry to refresh.';
        }
      }
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }

    // Fetch snapshots separately (non-blocking for portfolio)
    _fetchSnapshots(wallet);
  }

  List<TradeFill>? _lastSortedFills;
  PortfolioHistoryModel? _lastProcessedHistory;
  PortfolioTimeRange? _lastProcessedRange;

  void _processHistory() {
    if (_history == null || _summary == null) return;

    // Skip if nothing changed
    if (_history == _lastProcessedHistory && _selectedRange == _lastProcessedRange) {
      return;
    }

    final Map<String, SymbolTradeSummary> summaryMap = {};

    // Only sort if history object changed
    if (_history != _lastProcessedHistory) {
      _lastSortedFills = List<TradeFill>.from(_history!.fills)
        ..sort((a, b) => a.time.compareTo(b.time));
      _lastProcessedHistory = _history;
    }

    final allFills = _lastSortedFills ?? [];
    final now = DateTime.now().millisecondsSinceEpoch;
    final int rangeMs;
    switch (_selectedRange) {
      case PortfolioTimeRange.hour:
        rangeMs = 1 * 60 * 60 * 1000;
        break;
      case PortfolioTimeRange.day:
        rangeMs = 24 * 60 * 60 * 1000;
        break;
      case PortfolioTimeRange.week:
        rangeMs = 7 * 24 * 60 * 60 * 1000;
        break;
      case PortfolioTimeRange.month:
        rangeMs = 30 * 24 * 60 * 60 * 1000;
        break;
      case PortfolioTimeRange.year:
        rangeMs = 365 * 24 * 60 * 60 * 1000;
        break;
      case PortfolioTimeRange.all:
        rangeMs = double.maxFinite.toInt();
        break;
    }

    final filteredFills = allFills
        .where((f) => (_selectedRange == PortfolioTimeRange.all) || (now - f.time < rangeMs))
        .toList();
    _historyFills = List.from(filteredFills.reversed);

    double cumulativeCombined = 0;
    double cumulativePerp = 0;
    _currentVolume = 0;

    _combinedPnlSeries = [0];
    _perpPnlSeries = [0];

    final int startTs = filteredFills.isNotEmpty ? filteredFills.first.time : now - (rangeMs > 1e12 ? 86400000 : rangeMs);
    _historyTimestamps = [startTs];

    for (var fill in filteredFills) {
      final symbol = fill.coin;
      final bool isPerp = fill.dir.contains('Long') || fill.dir.contains('Short');

      summaryMap.putIfAbsent(symbol, () => SymbolTradeSummary(symbol: symbol));

      final s = summaryMap[symbol]!;
      s.trades++;
      final fillVol = fill.px * fill.sz;
      s.volume += fillVol;
      s.pnl += fill.closedPnl;
      s.fees += fill.fee;

      _currentVolume += fillVol;
      cumulativeCombined += fill.closedPnl;
      if (isPerp) cumulativePerp += fill.closedPnl;

      _combinedPnlSeries.add(cumulativeCombined);
      _perpPnlSeries.add(cumulativePerp);
      _historyTimestamps.add(fill.time);

      if (fill.closedPnl > 0) s.wins++;
      if (fill.closedPnl > s.best) s.best = fill.closedPnl;
      if (fill.closedPnl < s.worst) s.worst = fill.closedPnl;
    }

    // Account value series can be large, allocate once
    final int seriesLen = _combinedPnlSeries.length;
    _accountValueSeries = List.filled(seriesLen, 0);
    double currentVal = _summary!.totalBalance;
    if (seriesLen > 0) {
      _accountValueSeries[seriesLen - 1] = currentVal;
      for (int i = seriesLen - 2; i >= 0; i--) {
        final pnlChange = _combinedPnlSeries[i + 1] - _combinedPnlSeries[i];
        currentVal -= pnlChange;
        _accountValueSeries[i] = currentVal;
      }
    }

    _allChange = seriesLen > 1 ? (_combinedPnlSeries.last - _combinedPnlSeries.first) : 0;

    _symbolSummaries = summaryMap.values.toList();
    _symbolSummaries.sort((a, b) => b.volume.compareTo(a.volume));

    _lastProcessedRange = _selectedRange;
    _calculateAssetComposition();
    _calculatePerformanceMetrics(filteredFills);
    _calculateRiskMetrics();
  }

  void _calculatePerformanceMetrics(List<TradeFill> fills) {
    if (fills.isEmpty) {
      _performanceMetrics = PerformanceMetrics();
      return;
    }

    // Grouping into trades (simplified: 1 fill = 1 trade for now, or group by hash)
    final Map<String, List<TradeFill>> tradesByHash = {};
    for (var f in fills) {
      final key = f.hash.isNotEmpty ? f.hash : '${f.time}-${f.coin}';
      tradesByHash.putIfAbsent(key, () => []).add(f);
    }

    final List<_TradeGroup> trades = tradesByHash.values.map((group) {
      return _TradeGroup(
        coin: group.first.coin,
        time: group.first.time,
        pnl: group.fold(0.0, (sum, f) => sum + f.closedPnl),
        volume: group.fold(0.0, (sum, f) => sum + (f.px * f.sz)),
        fee: group.fold(0.0, (sum, f) => sum + f.fee),
      );
    }).toList();

    final wins = trades.where((t) => t.pnl > 0).toList();
    final losses = trades.where((t) => t.pnl < 0).toList();

    final grossProfit = wins.fold(0.0, (sum, t) => sum + t.pnl);
    final grossLoss = losses.fold(0.0, (sum, t) => sum + t.pnl.abs());
    
    double largestWin = 0;
    String largestWinCoin = '';
    double largestLoss = 0;
    String largestLossCoin = '';
    
    for (var t in trades) {
      if (t.pnl > largestWin) {
        largestWin = t.pnl;
        largestWinCoin = t.coin;
      }
      if (t.pnl < largestLoss) {
        largestLoss = t.pnl;
        largestLossCoin = t.coin;
      }
    }

    final totalVolume = trades.fold(0.0, (sum, t) => sum + t.volume);
    final totalFees = trades.fold(0.0, (sum, t) => sum + t.fee);

    _performanceMetrics = PerformanceMetrics(
      winRate: trades.isNotEmpty ? (wins.length / trades.length * 100) : 0,
      totalWins: wins.length,
      totalTrades: trades.length,
      profitFactor: grossLoss > 0 ? (grossProfit / grossLoss) : (grossProfit > 0 ? 999 : 0),
      avgWin: wins.isNotEmpty ? (grossProfit / wins.length) : 0,
      avgLoss: losses.isNotEmpty ? (grossLoss / losses.length) : 0,
      largestWin: largestWin,
      largestWinCoin: largestWinCoin,
      largestLoss: largestLoss,
      largestLossCoin: largestLossCoin,
      winSparkline: wins.reversed.take(10).map((t) => t.pnl).toList().reversed.toList(),
      lossSparkline: losses.reversed.take(10).map((t) => t.pnl.abs()).toList().reversed.toList(),
      totalVolume: totalVolume,
      totalFees: totalFees,
    );
  }

  void _calculateRiskMetrics() {
    if (_summary == null) return;
    
    final double balance = _summary!.totalBalance;
    final double marginUsed = _summary!.totalMarginUsed;
    final double withdrawable = _summary!.withdrawable;

    // Leverage Risk: normalized against 10x
    final double leverage = balance > 0 
        ? (marginUsed * 10 / balance).clamp(0.0, 50.0) 
        : 0.0;
    final leverageRisk = (leverage / 10 * 100).clamp(0.0, 100.0);

    // Concentration Risk: largest asset %
    double maxAssetPct = 0.0;
    if (_assetComposition.isNotEmpty) {
      maxAssetPct = _assetComposition.map((e) => e.percentage).reduce((a, b) => a > b ? a : b);
    }

    // Margin Usage
    final double marginUsagePct = withdrawable > 0 
        ? (1.0 - (withdrawable / balance)) * 100.0 
        : 100.0;

    // Volatility Risk: simple baseline
    double volRisk = 25.0; 
    if (_combinedPnlSeries.length > 5) {
      final returns = <double>[];
      for (int i = 1; i < _combinedPnlSeries.length; i++) {
        final r = _combinedPnlSeries[i] - _combinedPnlSeries[i-1];
        returns.add(r);
      }
      final mean = returns.reduce((a, b) => a + b) / returns.length;
      final variance = returns.map((r) => (r - mean) * (r - mean)).reduce((a, b) => a + b) / returns.length;
      final stdDev = variance > 0 ? (variance / (balance + 1.0) * 1000.0) : 0.0;
      volRisk = (stdDev * 10).clamp(10.0, 95.0);
    }

    _riskMetrics = RiskMetrics(
      leverageRisk: leverageRisk,
      concentrationRisk: maxAssetPct,
      marginUsage: marginUsagePct.clamp(0.0, 100.0),
      volatilityRisk: volRisk,
    );
  }

  void _calculateAssetComposition() {
    if (_summary == null) return;

    final Map<String, double> assetMap = {};

    for (var spot in _summary!.spotBalances) {
      if (spot.usdValue > 0) {
        assetMap[spot.coin] = (assetMap[spot.coin] ?? 0) + spot.usdValue;
      }
    }

    for (var pos in _summary!.positions) {
      final notional = pos.size * pos.markPx;
      if (notional > 0) {
        assetMap[pos.coin] = (assetMap[pos.coin] ?? 0) + notional;
      }
    }

    final totalValue = assetMap.values.fold<double>(0, (p, c) => p + c);
    if (totalValue == 0) {
      _assetComposition = [];
      return;
    }

    // Sort by value descending
    final sortedAssets = assetMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Multi-color palette matching the web app donut
    const List<Color> palette = [
      Color(0xFF0FB78E), // teal
      Color(0xFF3B82F6), // blue
      Color(0xFF6366F1), // indigo
      Color(0xFF8B5CF6), // violet
      Color(0xFFEC4899), // pink
      Color(0xFFF97316), // orange
    ];

    final List<AssetCompositionItem> items = [];
    double othersValue = 0;

    for (int i = 0; i < sortedAssets.length; i++) {
      if (i < palette.length) {
        items.add(AssetCompositionItem(
          coin: sortedAssets[i].key,
          usdValue: sortedAssets[i].value,
          percentage: (sortedAssets[i].value / totalValue) * 100,
          color: palette[i],
        ));
      } else {
        othersValue += sortedAssets[i].value;
      }
    }

    if (othersValue > 0) {
      items.add(AssetCompositionItem(
        coin: 'Others',
        usdValue: othersValue,
        percentage: (othersValue / totalValue) * 100,
        color: const Color(0xFFEAB308), // yellow
      ));
    }

    _assetComposition = items;
  }

  Future<void> _fetchSnapshots(String wallet) async {
    debugPrint('📊 [PortfolioVM] Fetching snapshots for $wallet');
    try {
      _snapshots = await _leaderboardService.getTraderSnapshots(wallet);
      debugPrint('📊 [PortfolioVM] Snapshots received: ${_snapshots.length} entries');
      _processSnapshots();
      notifyListeners();
    } catch (e) {
      debugPrint('📊 [PortfolioVM] Snapshots fetch failed (non-fatal): $e');
    }
  }

  void _processSnapshots() {
    debugPrint('📊 [PortfolioVM] Processing ${_snapshots.length} snapshots');
    if (_snapshots.isEmpty) {
      debugPrint('📊 [PortfolioVM] No snapshots to process, graph will not show');
      return;
    }

    final sorted = List<TraderSnapshot>.from(_snapshots)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    _snapshotTimestamps = sorted.map((s) => s.timestamp).toList();
    _snapshotValueSeries = sorted.map((s) => s.accountValue).toList();
    debugPrint('📊 [PortfolioVM] Snapshot series: ${_snapshotValueSeries.length} points, '
        'first: ${_snapshotValueSeries.isNotEmpty ? _snapshotValueSeries.first : "N/A"}, '
        'last: ${_snapshotValueSeries.isNotEmpty ? _snapshotValueSeries.last : "N/A"}');
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

class _TradeGroup {
  final String coin;
  final int time;
  final double pnl;
  final double volume;
  final double fee;

  _TradeGroup({required this.coin, required this.time, required this.pnl, required this.volume, required this.fee});
}

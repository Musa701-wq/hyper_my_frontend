import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:http/http.dart';
import '../services/defillama_service.dart';

enum ChartRange { daily, weekly, monthly, yearly }

extension ChartRangeExt on ChartRange {
  String get label {
    switch (this) {
      case ChartRange.daily:   return '1D';
      case ChartRange.weekly:  return '1W';
      case ChartRange.monthly: return '1M';
      case ChartRange.yearly:  return '1Y';
    }
  }
}

enum ChartScope { all, perps, spot, hlp }

extension ChartScopeExt on ChartScope {
  String get label {
    switch (this) {
      case ChartScope.all:   return 'All';
      case ChartScope.perps: return 'Perps';
      case ChartScope.spot:  return 'Spot';
      case ChartScope.hlp:   return 'HLP';
    }
  }
  String get param {
    switch (this) {
      case ChartScope.all:   return 'all';
      case ChartScope.perps: return 'perps';
      case ChartScope.spot:  return 'spot';
      case ChartScope.hlp:   return 'hlp';
    }
  }
  Color get color {
    switch (this) {
      case ChartScope.all:   return const Color(0xFF10B981);
      case ChartScope.perps: return const Color(0xFF0D9488);
      case ChartScope.spot:  return const Color(0xFF7C3AED);
      case ChartScope.hlp:   return const Color(0xFFD97706);
    }
  }
}

class DefiLlamaViewModel extends ChangeNotifier {
  final DefiLlamaService _service = DefiLlamaService();

  // ─── Loading / error ──────────────────────────────────────
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isChartLoading = false;
  bool get isChartLoading => _isChartLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  // ─── Toggles ──────────────────────────────────────────────
  String _tab = 'fees';
  String get tab => _tab;

  String _chartMode = 'bar';
  String get chartMode => _chartMode;

  ChartRange _chartRange = ChartRange.daily;
  ChartRange get chartRange => _chartRange;

  ChartScope _chartScope = ChartScope.all;
  ChartScope get chartScope => _chartScope;

  // ─── Raw API data ─────────────────────────────────────────
  Map<String, dynamic>? _summaryData;
  Map<String, dynamic>? _breakdownData;

  // ─── Scope cache (avoids re-fetching same scope) ──────────
  final Map<String, List<_RawPoint>> _scopeCache = {};

  // ─── Chart data (filtered + aggregated) ──────────────────
  List<FlSpot>   _chartSpots = [];
  List<DateTime> _chartDates = [];
  List<FlSpot>   get chartSpots => _chartSpots;
  List<DateTime> get chartDates => _chartDates;

  // ─── Period breakdown ─────────────────────────────────────
  Map<String, PeriodBreakdown> _periodBreakdowns = {};
  Map<String, PeriodBreakdown> get periodBreakdowns => _periodBreakdowns;

  static const List<String> periodKeys   = ['1 day', '7d', '30d', '365'];
  static const List<String> periodLabels = ['Day', 'Week', 'Month', 'Year'];

  // ─── Table pagination ─────────────────────────────────────
  int _tablePage = 1;
  int _tableRowsPerPage = 10;
  int get tablePage => _tablePage;
  int get tableRowsPerPage => _tableRowsPerPage;
  static const List<int> tableRowsOptions = [10, 20, 50, 100];

  int get tableTotalPages {
    if (_chartSpots.isEmpty) return 0;
    return (_chartSpots.length / _tableRowsPerPage).ceil();
  }

  List<({DateTime date, double value})> get paginatedTableRows {
    if (_chartSpots.isEmpty || _chartDates.isEmpty) return [];
    final start = (_tablePage - 1) * _tableRowsPerPage;
    final end   = (start + _tableRowsPerPage).clamp(0, _chartSpots.length);
    if (start >= _chartSpots.length) return [];
    return List.generate(end - start, (i) => (
      date:  _chartDates[start + i],
      value: _chartSpots[start + i].y,
    ));
  }

  // ─── Stat card values ─────────────────────────────────────
  double get stat24h     => (_summaryData?['total24h']      as num?)?.toDouble() ?? 0;
  double get statPrev24h => (_summaryData?['total48hto24h'] as num?)?.toDouble() ?? 0;
  double get stat7d      => (_summaryData?['total7d']       as num?)?.toDouble() ?? 0;
  double get stat30d     => (_summaryData?['total30d']      as num?)?.toDouble() ?? 0;
  double get stat1y      => (_summaryData?['total1y']       as num?)?.toDouble() ?? 0;
  double get statAllTime => (_summaryData?['totalAllTime']  as num?)?.toDouble() ?? 0;
  double get change1d    => (_summaryData?['change_1d']     as num?)?.toDouble() ?? 0;

  String get tabLabel => _tab == 'fees' ? 'Fees' : 'Revenue';

  // ─── Actions ──────────────────────────────────────────────
  void setTab(String t) {
    if (_tab == t) return;
    _tab = t;
    _scopeCache.clear();
    notifyListeners();
    fetchAll();
  }

  void setChartMode(String m) {
    if (_chartMode == m) return;
    _chartMode = m;
    notifyListeners();
  }

  void setChartRange(ChartRange r) {
    if (_chartRange == r) return;
    _chartRange = r;
    _applyRangeFilter();
    notifyListeners();
  }

  void setChartScope(ChartScope s) {
    if (_chartScope == s) return;
    _chartScope = s;
    notifyListeners();
    _loadScopeChart();
  }

  void setTablePage(int p) {
    if (p < 1 || p > tableTotalPages || p == _tablePage) return;
    _tablePage = p;
    notifyListeners();
  }

  void setTableRowsPerPage(int r) {
    if (r == _tableRowsPerPage) return;
    _tableRowsPerPage = r;
    _tablePage = 1;
    notifyListeners();
  }

  // ─── Main fetch ───────────────────────────────────────────
  Future<void> fetchAll() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      final results = await Future.wait([
        _tab == 'fees' ? _service.fetchFees()          : _service.fetchRevenue(),
        _tab == 'fees' ? _service.fetchFeesChart(scope: 'all')
                       : _service.fetchRevenueChart(scope: 'all'),
        _tab == 'fees' ? _service.fetchFeesBreakdown() : _service.fetchRevenueBreakdown(),
      ]);
      _summaryData   = results[0];
      _breakdownData = results[2];
      _cacheChartData('all', results[1]);
      _parseBreakdownTable();

      if (_chartScope == ChartScope.all) {
        _applyRangeFilter();
      } else {
        await _loadScopeChart();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = _getFriendlyErrorMessage(e);
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

  // ─── Load scope-specific chart (with cache) ───────────────
  Future<void> _loadScopeChart() async {
    final key = _chartScope.param;
    if (_scopeCache.containsKey(key)) {
      _applyRangeFilter();
      notifyListeners();
      return;
    }
    _isChartLoading = true;
    notifyListeners();
    try {
      final data = _tab == 'fees'
          ? await _service.fetchFeesChart(scope: key)
          : await _service.fetchRevenueChart(scope: key);
      _cacheChartData(key, data);
      _applyRangeFilter();
    } catch (_) {
      _chartSpots = [];
      _chartDates = [];
    }
    _isChartLoading = false;
    notifyListeners();
  }

  // ─── Cache raw points from API ────────────────────────────
  void _cacheChartData(String scope, Map<String, dynamic> data) {
    final raw = (data['totalDataChart'] ?? data['chart']) as List<dynamic>?;
    if (raw == null || raw.isEmpty) { _scopeCache[scope] = []; return; }
    _scopeCache[scope] = raw.map((e) {
      final list = e as List<dynamic>;
      return _RawPoint(
        ts:  (list[0] as num).toInt(),
        val: (list[1] as num).toDouble(),
      );
    }).toList();
  }

  // ─── Slice + aggregate ────────────────────────────────────
  // 1D → last 365 days, one bar per day
  // 1W → last 365 days, ~52 weekly totals
  // 1M → last 365 days, 12 monthly totals
  // 1Y → last 365 days, 1 bar (total)
  void _applyRangeFilter() {
    final raw = _scopeCache[_chartScope.param] ?? [];
    if (raw.isEmpty) {
      _chartSpots = [];
      _chartDates = [];
      _tablePage  = 1;
      return;
    }

    final cutoffTs = DateTime.now()
        .subtract(const Duration(days: 365))
        .millisecondsSinceEpoch ~/ 1000;
    final base = raw.where((p) => p.ts >= cutoffTs).toList();
    final src  = base.isEmpty ? raw : base;

    final List<_RawPoint> filtered;
    switch (_chartRange) {
      case ChartRange.daily:
        filtered = src;
        break;
      case ChartRange.weekly:
        filtered = _aggregateBy(src, _weekKey);
        break;
      case ChartRange.monthly:
        filtered = _aggregateBy(src, _monthKey);
        break;
      case ChartRange.yearly:
        if (src.isEmpty) {
          filtered = [];
        } else {
          final total = src.fold(0.0, (s, p) => s + p.val);
          filtered = [_RawPoint(ts: src.last.ts, val: total)];
        }
        break;
    }

    _chartSpots = List.generate(
      filtered.length, (i) => FlSpot(i.toDouble(), filtered[i].val),
    );
    _chartDates = filtered
        .map((p) => DateTime.fromMillisecondsSinceEpoch(p.ts * 1000))
        .toList();
    _tablePage = 1;
  }

  // ─── Aggregation helpers ──────────────────────────────────
  List<_RawPoint> _aggregateBy(
    List<_RawPoint> points,
    String Function(DateTime) keyFn,
  ) {
    final Map<String, ({int ts, double val})> map = {};
    for (final p in points) {
      final dt  = DateTime.fromMillisecondsSinceEpoch(p.ts * 1000);
      final key = keyFn(dt);
      if (map.containsKey(key)) {
        map[key] = (ts: map[key]!.ts, val: map[key]!.val + p.val);
      } else {
        map[key] = (ts: p.ts, val: p.val);
      }
    }
    return (map.values.map((e) => _RawPoint(ts: e.ts, val: e.val)).toList()
      ..sort((a, b) => a.ts.compareTo(b.ts)));
  }

  String _weekKey(DateTime dt) {
    final monday = dt.subtract(Duration(days: dt.weekday - 1));
    return '${monday.year}-${monday.month.toString().padLeft(2,'0')}'
           '-${monday.day.toString().padLeft(2,'0')}';
  }

  String _monthKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}';

  // ─── Parse period breakdown table ────────────────────────
  void _parseBreakdownTable() {
    final periods = _breakdownData?['periods'] as Map<String, dynamic>?;
    if (periods == null) { _periodBreakdowns = {}; return; }
    _periodBreakdowns = {};
    for (final key in periodKeys) {
      final pd = periods[key] as Map<String, dynamic>?;
      if (pd == null) continue;
      _periodBreakdowns[key] = PeriodBreakdown(
        perps: (pd['Perps'] as num?)?.toDouble() ?? 0,
        spot:  (pd['Spot']  as num?)?.toDouble() ?? 0,
        hlp:   (pd['HLP']   as num?)?.toDouble() ?? 0,
        total: (pd['total'] as num?)?.toDouble() ?? 0,
      );
    }
  }

  // ─── Date label for chart data table ─────────────────────
  String tableDateLabel(DateTime dt) {
    switch (_chartRange) {
      case ChartRange.daily:
        return '${_dd(dt.day)} ${_mmm(dt.month)} ${dt.year}';
      case ChartRange.weekly:
        // Removed 'Wk' and "'" - showing date properly
        return '${_dd(dt.day)} ${_mmm(dt.month)} ${dt.year}';
      case ChartRange.monthly:
        return '${_mmm(dt.month)} ${dt.year}';
      case ChartRange.yearly:
        return dt.year.toString();
    }
  }

  // ─── Formatting ───────────────────────────────────────────
  String fmtCompact(double n) {
    if (n == 0) return '\$0';
    if (n >= 1e9) return '\$${(n / 1e9).toStringAsFixed(2)}B';
    if (n >= 1e6) return '\$${(n / 1e6).toStringAsFixed(2)}M';
    if (n >= 1e3) return '\$${(n / 1e3).toStringAsFixed(1)}K';
    return '\$${n.toStringAsFixed(0)}';
  }

  String fmtPct(double n) {
    final sign = n >= 0 ? '+' : '';
    return '$sign${n.toStringAsFixed(2)}%';
  }

  String _mmm(int m) {
    const names = ['Jan','Feb','Mar','Apr','May','Jun',
                   'Jul','Aug','Sep','Oct','Nov','Dec'];
    return names[m - 1];
  }
  String _dd(int d) => d.toString().padLeft(2, '0');
}

// ─── Internal raw data point ─────────────────────────────────
class _RawPoint {
  final int    ts;
  final double val;
  const _RawPoint({required this.ts, required this.val});
}

// ─── Period breakdown model ───────────────────────────────────
class PeriodBreakdown {
  final double perps;
  final double spot;
  final double hlp;
  final double total;
  const PeriodBreakdown({
    required this.perps,
    required this.spot,
    required this.hlp,
    required this.total,
  });
}

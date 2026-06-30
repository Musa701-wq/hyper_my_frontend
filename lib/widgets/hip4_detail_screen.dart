import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import '../models/hip4_model.dart';
import '../utils/app_colors.dart';
import '../utils/common_widgets.dart';
import '../utils/responsive.dart';
import '../viewmodels/hip4_viewmodel.dart';
import '../services/orderbook_service.dart';
import '../models/orderbook_model.dart';
import 'orderbook_panel.dart';
import 'hip4_trades_panel.dart';

class Hip4DetailScreen extends StatefulWidget {
  final Hip4Market market;
  const Hip4DetailScreen({super.key, required this.market});

  @override
  State<Hip4DetailScreen> createState() => _Hip4DetailScreenState();
}

class _Hip4DetailScreenState extends State<Hip4DetailScreen>
    with TickerProviderStateMixin {
  Hip4AggregatedOi? _oi;
  List<Hip4Candle> _positiveCandles = [];
  List<Hip4Candle> _negativeCandles = [];
  bool _isLoading = true;
  bool _showPositive = true;
  bool _showOhlc = true;
  int? _selectedIdx; // tapped candle index
  int? _touchedBarIdx; // tapped volume bar index
  bool _descExpanded = false; // description expand state

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late TabController _tabController;

  OrderBookService? _orderBookService;
  OrderBookSnapshot? _orderBook;
  bool _orderBookLoading = false;
  String? _orderBookError;

  // fixed slot width per candle — gives scroll room
  static const double _slotW = 46.0;
  static const double _chartLeftPad = 44.0;

  static const List<Color> _palette = [
    Color(0xFF00C9A7), Color(0xFFF59E0B), Color(0xFF3B82F6),
    Color(0xFFF43F5E), Color(0xFF8B5CF6), Color(0xFF06B6D4),
    Color(0xFFEC4899), Color(0xFF84CC16),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadStats();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 1) {
      _startOrderBook();
    } else {
      _orderBookService?.dispose();
      _orderBookService = null;
      if (_tabController.index != 2) {
        setState(() {
          _orderBook = null;
          _orderBookLoading = false;
          _orderBookError = null;
        });
      }
    }
  }

  int get _activeSideIdx => _showPositive ? 0 : 1;

  Hip4Outcome? get _activeOutcome {
    final idx = _activeSideIdx;
    if (idx < widget.market.outcomes.length) {
      return widget.market.outcomes[idx];
    }
    return null;
  }

  void _startOrderBook() {
    _orderBookService?.dispose();
    _orderBookService = null;

    final outcome = _activeOutcome;
    if (outcome == null) {
      setState(() {
        _orderBookError = 'No outcome coin found for this side';
        _orderBookLoading = false;
      });
      return;
    }

    final coinName = outcome.coinName;
    if (coinName.isEmpty) {
      setState(() {
        _orderBookError = 'No coin name for order book';
        _orderBookLoading = false;
      });
      return;
    }

    setState(() {
      _orderBookLoading = true;
      _orderBookError = null;
      _orderBook = null;
    });

    _orderBookService = OrderBookService(
      symbol: coinName,
      isHip4: true,
      hip4MarketId: widget.market.id.toString(),
      hip4Side: _activeSideIdx,
    );

    _orderBookService!.startLive(
      onUpdate: (snapshot) {
        if (!mounted) return;
        setState(() {
          _orderBook = snapshot;
          _orderBookLoading = false;
          _orderBookError = null;
        });
      },
      onError: (e) {
        debugPrint('HIP4 Orderbook error ($coinName): $e');
        if (!mounted) return;
        setState(() {
          _orderBookLoading = false;
          _orderBookError = 'Error loading live orderbook: $e';
        });
      },
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _orderBookService?.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final vm = context.read<Hip4ViewModel>();
    final id = widget.market.id;
    final results = await Future.wait([
      vm.fetchOutcomeDetail(id),
      vm.fetchCandles(id, 'positive'),
      vm.fetchCandles(id, 'negative'),
    ]);
    if (!mounted) return;
    setState(() {
      _oi = results[0] as Hip4AggregatedOi?;
      _positiveCandles = _ensure(results[1] as List<Hip4Candle>, 0);
      _negativeCandles = _ensure(results[2] as List<Hip4Candle>, 1);
      _isLoading = false;
    });
  }

  List<Hip4Candle> _ensure(List<Hip4Candle> c, int sideIdx) {
    if (c.isNotEmpty) return c;
    final base = sideIdx < widget.market.outcomes.length
        ? widget.market.outcomes[sideIdx].probability / 100.0
        : 0.5;
    return _demoCandles(base);
  }

  List<Hip4Candle> _demoCandles(double basePrice) {
    final rng = Random(42);
    final now = DateTime.now();
    double price = basePrice;
    return List.generate(24, (i) {
      final change = (rng.nextDouble() - 0.48) * 0.008;
      final open = price;
      final close = (open + change).clamp(0.001, 0.999);
      final high = (max(open, close) + rng.nextDouble() * 0.005).clamp(0.001, 0.999);
      final low  = (min(open, close) - rng.nextDouble() * 0.005).clamp(0.001, 0.999);
      price = close;
      return Hip4Candle(
        timestamp: now.subtract(Duration(hours: 24 - i)),
        open: open, close: close, high: high, low: low,
        volume: 500 + rng.nextDouble() * 2500,
        quoteVolume: 0, tradeCount: 0,
      );
    });
  }

  List<Hip4Candle> get _candles =>
      _showPositive ? _positiveCandles : _negativeCandles;

  void _switchChart(bool toOhlc) {
    if (_showOhlc == toOhlc) return;
    _fadeCtrl.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _showOhlc = toOhlc;
        _selectedIdx = null;
        _touchedBarIdx = null;
      });
      _fadeCtrl.forward();
    });
  }

  /// Canvas width for both charts (scrollable when > screen width)
  double _canvasWidth(int n, double viewportW) {
    final full = _chartLeftPad + n * _slotW + 40.0;
    return full < viewportW ? viewportW : full;
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);
    final sorted = List<Hip4Outcome>.from(widget.market.outcomes)
      ..sort((a, b) => b.probability.compareTo(a.probability));
    final expiryStr = widget.market.expiry != null
        ? DateFormat('dd MMM yyyy · HH:mm').format(widget.market.expiry!.toLocal()) + ' UTC'
        : null;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _appBar(res),
        body: _isLoading
            ? _loader()
            : TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Page Details
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoChips(res, expiryStr),
                        const SizedBox(height: 10),

                        // Yes / No toggle
                        _sideToggle(res),
                        const SizedBox(height: 10),

                        // OHLC / Volume chart-type toggle
                        _chartTypeToggle(res),
                        const SizedBox(height: 8),

                        // The chart (full width, animated switch)
                        _chartCard(res),
                        const SizedBox(height: 8),

                        // OHLC last-candle values (only when OHLC tab)
                        if (_showOhlc) _ohlcValues(res),
                        if (_showOhlc) const SizedBox(height: 10),

                        // Open Interest card only
                        _statsCard(res),
                        const SizedBox(height: 12),

                        _outcomesHeader(res, sorted.length),
                        const SizedBox(height: 6),
                        ...sorted.asMap().entries.map(
                            (e) => _outcomeRow(e.value, e.key, res)),
                      ],
                    ),
                  ),

                  // Tab 2: Live Order Book
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          children: [
                            Text(
                              'Outcome: ',
                              style: GoogleFonts.jetBrainsMono(
                                color: AppColors.textSecondary,
                                fontSize: res.fontSize(11),
                              ),
                            ),
                            _sideToggle(res),
                          ],
                        ),
                      ),
                      const Divider(color: AppColors.surfaceBright, height: 1),
                      Expanded(
                        child: OrderBookPanel(
                          snapshot: _orderBook,
                          isLoading: _orderBookLoading,
                          errorMessage: _orderBookError,
                          sizeLabel: _activeOutcome?.coinName ?? 'Contracts',
                          bypassPaywall: true,
                        ),
                      ),
                    ],
                  ),

                  // Tab 3: Recent Trades
                  Builder(builder: (context) {
                    final outcome = _activeOutcome;
                    final coinSymbol = outcome?.coinName ?? '';
                    if (coinSymbol.isEmpty) {
                      return Center(
                        child: Text(
                          'No outcome coin available',
                          style: GoogleFonts.jetBrainsMono(color: Colors.white30, fontSize: res.fontSize(12)),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                          child: Row(
                            children: [
                              Text('Outcome: ',
                                  style: GoogleFonts.jetBrainsMono(
                                      color: AppColors.textSecondary, fontSize: res.fontSize(11))),
                              _sideToggle(res),
                            ],
                          ),
                        ),
                        const Divider(color: AppColors.surfaceBright, height: 1),
                        Expanded(
                          child: Hip4TradesPanel(
                            key: ValueKey('trades_${widget.market.id}_${_activeSideIdx}_$coinSymbol'),
                            marketId: widget.market.id.toString(),
                            side: _activeSideIdx,
                            coinSymbol: coinSymbol,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
      ),
    );
  }

  // ─── AppBar ────────────────────────────────────────────────────
  PreferredSizeWidget _appBar(Responsive res) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.arrow_back, color: AppColors.brandAccent),
      ),
      title: Text(
        widget.market.name,
        style: GoogleFonts.jetBrainsMono(
          color: AppColors.brandAccent,
          fontSize: res.fontSize(13),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.brandAccent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.brandAccent,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: GoogleFonts.jetBrainsMono(
          fontSize: res.fontSize(11),
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.jetBrainsMono(
          fontSize: res.fontSize(11),
        ),
        dividerColor: AppColors.surfaceBright.withValues(alpha: 0.4),
        tabs: const [
          Tab(text: 'Detail'),
          Tab(text: 'Order Book'),
          Tab(text: 'Trades'),
        ],
      ),
    );
  }

  Widget _loader() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1E222D),
      highlightColor: const Color(0xFF3A3F4E),
      period: const Duration(milliseconds: 1500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Chips skeleton
          Row(
            children: [
              _skeletonBar(width: 80, height: 18, radius: 4),
              const SizedBox(width: 8),
              _skeletonBar(width: 60, height: 18, radius: 4),
              const SizedBox(width: 8),
              _skeletonBar(width: 90, height: 18, radius: 4),
            ],
          ),
          const SizedBox(height: 12),
          
          // Description paragraph replacement skeleton
          _skeletonBar(width: double.infinity, height: 12, radius: 2),
          const SizedBox(height: 6),
          _skeletonBar(width: double.infinity, height: 12, radius: 2),
          const SizedBox(height: 6),
          _skeletonBar(width: 140, height: 12, radius: 2),
          const SizedBox(height: 20),
          
          // Yes/No switcher skeleton
          _skeletonBar(width: 120, height: 32, radius: 8),
          const SizedBox(height: 14),
          
          // Chart toggles skeleton
          _skeletonBar(width: 150, height: 26, radius: 6),
          const SizedBox(height: 12),
          
          // Chart Card skeleton
          _skeletonBar(width: double.infinity, height: 230, radius: 14),
          const SizedBox(height: 14),
          
          // OHLC details row skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _skeletonBar(width: 70, height: 38, radius: 8),
              _skeletonBar(width: 70, height: 38, radius: 8),
              _skeletonBar(width: 70, height: 38, radius: 8),
              _skeletonBar(width: 70, height: 38, radius: 8),
            ],
          ),
          const SizedBox(height: 14),
          
          // Open Interest stats card skeleton
          _skeletonBar(width: double.infinity, height: 80, radius: 14),
        ],
      ),
    );
  }

  Widget _skeletonBar({required double width, required double height, required double radius}) {
    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  // ─── Info chips ────────────────────────────────────────────────
  Widget _infoChips(Responsive res, String? expiryStr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBright.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _chip(widget.market.marketClass, _classColor(widget.market.marketClass)),
              if (widget.market.category.isNotEmpty)
                _chip(widget.market.category, Colors.white.withValues(alpha: 0.4)),
              if (expiryStr != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: res.fontSize(10),
                          color: AppColors.brandAccent.withValues(alpha: 0.8)),
                      const SizedBox(width: 4),
                      Text(
                        expiryStr,
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white70,
                          fontSize: res.fontSize(8.5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (widget.market.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _descExpanded = !_descExpanded),
              child: Text.rich(
                TextSpan(
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: res.fontSize(10),
                    height: 1.55,
                  ),
                  children: [
                    TextSpan(
                      text: _descExpanded
                          ? widget.market.description
                          : (widget.market.description.length > 120
                              ? '${widget.market.description.substring(0, 120)}...'
                              : widget.market.description),
                    ),
                    if (widget.market.description.length > 120)
                      TextSpan(
                        text: _descExpanded ? '  Show Less' : '  See More',
                        style: TextStyle(
                          color: AppColors.brandAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Yes / No toggle ──────────────────────────────────────────
  Widget _sideToggle(Responsive res) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBright),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _sidePill('Yes', _showPositive, AppColors.trendGreen,
            () => setState(() {
                  _showPositive = true;
                  _selectedIdx = null;
                  _touchedBarIdx = null;
                  if (_tabController.index == 1) {
                    _startOrderBook();
                  }
                })),
        const SizedBox(width: 4),
        _sidePill('No', !_showPositive, const Color(0xFFB886FF),
            () => setState(() {
                  _showPositive = false;
                  _selectedIdx = null;
                  _touchedBarIdx = null;
                  if (_tabController.index == 1) {
                    _startOrderBook();
                  }
                })),
      ]),
    );
  }

  Widget _sidePill(
      String label, bool active, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.surfaceBright : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: active ? color : Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ─── Chart-type toggle (OHLC / Volume) ────────────────────────
  Widget _chartTypeToggle(Responsive res) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBright),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _chartPill(Icons.candlestick_chart_outlined, 'OHLC', _showOhlc,
            () => _switchChart(true)),
        const SizedBox(width: 3),
        _chartPill(Icons.bar_chart_rounded, 'VOLUME', !_showOhlc,
            () => _switchChart(false)),
      ]),
    );
  }

  Widget _chartPill(
      IconData icon, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.surfaceBright : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 13,
              color: active
                  ? AppColors.brandAccent
                  : AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.jetBrainsMono(
                color: active
                    ? AppColors.brandAccent
                    : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              )),
        ]),
      ),
    );
  }

  // ─── Chart card (full-width) ───────────────────────────────────
  Widget _chartCard(Responsive res) {
    return AppCard(
      borderRadius: 14,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 3, height: 14,
            decoration: BoxDecoration(
              color: _showOhlc
                  ? (_showPositive ? AppColors.trendGreen : AppColors.trendRed)
                  : (_showPositive ? AppColors.trendGreen : const Color(0xFFB886FF)),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _showOhlc
                ? 'OHLC · ${_showPositive ? "YES" : "NO"}'
                : 'VOLUME · ${_showPositive ? "YES" : "NO"}',
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white54, fontSize: 9,
              fontWeight: FontWeight.bold, letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          Text('scroll →',
              style: GoogleFonts.jetBrainsMono(
                  color: Colors.white.withValues(alpha: 0.20), fontSize: 7.5)),
        ]),
        const SizedBox(height: 10),
        FadeTransition(
          opacity: _fadeAnim,
          child: SizedBox(
            height: 320,
            child: _showOhlc ? _candleChart() : _volumeBarChart(),
          ),
        ),
      ]),
    );
  }

  // ─── Candlestick chart — horizontally scrollable + tap tooltip ─
  Widget _candleChart() {
    final candles = _candles;
    if (candles.isEmpty) return _emptyLabel('No candle data');

    return LayoutBuilder(builder: (context, constraints) {
      final viewW    = constraints.maxWidth;
      final canvasW  = _canvasWidth(candles.length, viewW);
      const chartH   = 320.0;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true, // latest candles on right
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            // find tapped candle index
            final localX = details.localPosition.dx;
            final relX = localX - _chartLeftPad;
            if (relX < 0) return;
            final idx = (relX / _slotW).floor().clamp(0, candles.length - 1);
            setState(() => _selectedIdx = _selectedIdx == idx ? null : idx);
          },
          child: CustomPaint(
            size: Size(canvasW, chartH),
            painter: _CandlePainter(
              candles: candles,
              green: AppColors.trendGreen,
              red: AppColors.trendRed,
              gridColor: AppColors.surfaceBright,
              selectedIdx: _selectedIdx,
              slotW: _slotW,
              leftPad: _chartLeftPad,
              currencySymbol: _oi?.currency.toUpperCase() ?? 'USDC',
            ),
          ),
        ),
      );
    });
  }


  // ─── Volume bar chart — scrollable, IQR Y-axis ─────────────────
  Widget _volumeBarChart() {
    final candles = _candles;
    if (candles.isEmpty) return _emptyLabel('No volume data');

    final vols = candles.map((c) => c.volume).toList()..sort();
    final absMax = vols.last;
    if (absMax <= 0) return _emptyLabel('No volume');

    // Y-axis: use the actual max so bars never overflow the card.
    // Add 15% headroom for the inline labels.
    final chartMax = absMax * 1.15;

    final barColor = _showPositive ? AppColors.trendGreen : const Color(0xFFB886FF);
    const rodW     = 13.0; // fixed width — chart is scrollable

    return LayoutBuilder(builder: (context, constraints) {
      final viewW   = constraints.maxWidth;
      final canvasW = _canvasWidth(candles.length, viewW);

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: ClipRect(
          child: SizedBox(
            width: canvasW,
            child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: chartMax,
              minY: 0,
              barTouchData: BarTouchData(
                enabled: true,
                touchCallback: (FlTouchEvent event, barTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        barTouchResponse == null ||
                        barTouchResponse.spot == null) {
                      _touchedBarIdx = null;
                      return;
                    }
                    _touchedBarIdx = barTouchResponse.spot!.touchedBarGroupIndex;
                  });
                },
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => group.x.toInt() == _touchedBarIdx
                      ? AppColors.surfaceBright
                      : Colors.transparent,
                  tooltipPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  tooltipMargin: 3,
                  getTooltipItem: (group, rodIndex, rod, xIndex) {
                    final i = group.x.toInt();
                    if (i < 0 || i >= candles.length) return null;
                    final c = candles[i];
                    final isTouched = (i == _touchedBarIdx);
                    final unit = _oi?.currency ?? 'USDC';
                    if (isTouched) {
                      return BarTooltipItem(
                        '${NumberFormat('#,##0').format(c.volume.toInt())} ${unit.toUpperCase()}',
                        GoogleFonts.jetBrainsMono(
                            color: barColor, fontSize: 9.5,
                            fontWeight: FontWeight.bold),
                      );
                    } else {
                      return BarTooltipItem(
                        _shortNum(c.volume.toInt()),
                        GoogleFonts.jetBrainsMono(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 7.5,
                            fontWeight: FontWeight.bold),
                      );
                    }
                  },
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value <= 0 || value == meta.max) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(_shortNum(value.toInt()),
                            style: GoogleFonts.jetBrainsMono(
                                color: Colors.white.withValues(alpha: 0.55), fontSize: 8.0)),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 18,
                    interval: max(1, (candles.length / 6)).toDouble(),
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= candles.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          DateFormat('HH:mm').format(candles[i].timestamp.toLocal()),
                          style: GoogleFonts.jetBrainsMono(
                              color: Colors.white.withValues(alpha: 0.55), fontSize: 8.0)),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true, drawVerticalLine: false,
                horizontalInterval: chartMax / 4,
                getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withValues(alpha: 0.05), strokeWidth: 0.5),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(candles.length, (i) {
                return BarChartGroupData(
                  x: i,
                  showingTooltipIndicators: [0],
                  barRods: [
                    BarChartRodData(
                      toY: candles[i].volume.clamp(0, chartMax),
                      color: barColor.withValues(alpha: 0.75),
                      width: rodW,
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(3),
                          topRight: Radius.circular(3)),
                    ),
                  ],
                );
              }),
            ),
            duration: const Duration(milliseconds: 200),
          ),
        ),
        ),
      );
    });
  }

  Widget _emptyLabel(String msg) => Center(
        child: Text(msg,
            style: GoogleFonts.jetBrainsMono(
                color: Colors.white24, fontSize: 11)),
      );

  // ─── OHLC values (selected candle or last candle) ──────────────
  Widget _ohlcValues(Responsive res) {
    if (_candles.isEmpty) return const SizedBox();
    
    final idx = (_selectedIdx != null && _selectedIdx! >= 0 && _selectedIdx! < _candles.length)
        ? _selectedIdx!
        : null;

    final c     = idx != null ? _candles[idx] : _candles.last;
    final isUp  = c.close >= c.open;
    final label = idx != null
        ? DateFormat('dd MMM · HH:mm').format(c.timestamp.toLocal())
        : 'Latest candle';

    return AppCard(
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // timestamp label
        Row(children: [
          Icon(Icons.access_time_rounded, size: 10, color: Colors.white24),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.jetBrainsMono(
                  color: Colors.white30, fontSize: 8.5)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceBright.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Vol  ${NumberFormat('#,##0').format(c.volume.toInt())}',
              style: GoogleFonts.jetBrainsMono(
                  color: AppColors.brandAccent,
                  fontSize: 9,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _ohlItem('Open', c.open, Colors.white60, res),
          _vDivider(),
          _ohlItem('Close', c.close, isUp ? AppColors.trendGreen : AppColors.trendRed, res),
          _vDivider(),
          _ohlItem('High', c.high, AppColors.trendGreen, res),
          _vDivider(),
          _ohlItem('Low', c.low, AppColors.trendRed, res),
        ]),
      ]),
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 28, color: AppColors.surfaceBright,
          margin: const EdgeInsets.symmetric(horizontal: 4));

  Widget _ohlItem(String label, double val, Color color, Responsive res) {
    return Expanded(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(label,
            style: GoogleFonts.jetBrainsMono(
                color: Colors.white30,
                fontSize: res.fontSize(8),
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
        const SizedBox(height: 4),
        FittedBox(
          child: Text(val.toStringAsFixed(4),
              style: GoogleFonts.jetBrainsMono(
                  color: color,
                  fontSize: res.fontSize(12),
                  fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  // ─── Stats card — Open Interest only ──────────────────────────
  Widget _statsCard(Responsive res) {
    final oiYes = _oi?.side0OpenInterestContracts ?? 0;
    final oiNo  = _oi?.side1OpenInterestContracts ?? 0;
    final oiTotal = oiYes + oiNo;
    final hasOi = _oi != null && oiTotal > 0;
    if (!hasOi) return const SizedBox();

    return AppCard(
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _statsHeader('OPEN INTEREST', _oi!.currency, res),
        const SizedBox(height: 12),
        _statRow('Yes', oiYes, oiTotal, AppColors.trendGreen, res),
        const SizedBox(height: 8),
        _statRow('No', oiNo, oiTotal, const Color(0xFFB886FF), res),
        const SizedBox(height: 8),
        Text(
          'Total: ${NumberFormat('#,##0').format(oiTotal)} Contracts',
          style: GoogleFonts.jetBrainsMono(
              color: Colors.white30, fontSize: res.fontSize(9)),
        ),
      ]),
    );
  }

  Widget _statsHeader(String label, String unit, Responsive res) {
    return Row(children: [
      Text(label,
          style: GoogleFonts.jetBrainsMono(
              color: Colors.white30,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2)),
      const Spacer(),
      Text(unit,
          style: GoogleFonts.jetBrainsMono(
              color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _statRow(
      String label, int value, int total, Color color, Responsive res) {
    final pct = total > 0 ? (value / total * 100) : 0.0;
    return Row(children: [
      Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      SizedBox(
        width: 28,
        child: Text(label,
            style: GoogleFonts.jetBrainsMono(
                color: Colors.white.withValues(alpha: 0.5), fontSize: res.fontSize(10))),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Container(
          height: 5,
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(3)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: pct / 100,
            child: Container(
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(3)),
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      SizedBox(
        width: 60,
        child: Text(NumberFormat('#,##0').format(value),
            textAlign: TextAlign.right,
            style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontSize: res.fontSize(11),
                fontWeight: FontWeight.bold)),
      ),
      const SizedBox(width: 6),
      SizedBox(
        width: 42,
        child: Text('${pct.toStringAsFixed(1)}%',
            textAlign: TextAlign.right,
            style: GoogleFonts.jetBrainsMono(
                color: color,
                fontSize: res.fontSize(9),
                fontWeight: FontWeight.bold)),
      ),
    ]);
  }

  // ─── Outcomes ─────────────────────────────────────────────────
  Widget _outcomesHeader(Responsive res, int count) {
    return Row(children: [
      Text('OUTCOMES',
          style: GoogleFonts.jetBrainsMono(
              color: Colors.white30,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
            color: AppColors.surfaceBright,
            borderRadius: BorderRadius.circular(20)),
        child: Text('$count',
            style: GoogleFonts.jetBrainsMono(
                color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
      ),
      const Spacer(),
      Text('sorted by probability',
          style: GoogleFonts.jetBrainsMono(
              color: Colors.white.withValues(alpha: 0.20), fontSize: 8)),
    ]);
  }

  Widget _outcomeRow(Hip4Outcome outcome, int idx, Responsive res) {
    final color = _outcomeColor(outcome, idx);
    final isTop = idx == 0;
    final pct = outcome.probability.clamp(0.0, 100.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isTop
            ? color.withValues(alpha: 0.07)
            : AppColors.surfaceBright.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isTop
                ? color.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.05),
            width: 1),
      ),
      child: Row(children: [
        Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        Expanded(
          child: Text(outcome.label,
              style: GoogleFonts.jetBrainsMono(
                  color: isTop ? color : Colors.white70,
                  fontSize: res.fontSize(11),
                  fontWeight: isTop ? FontWeight.bold : FontWeight.normal),
              overflow: TextOverflow.ellipsis),
        ),
        Text('${pct.toStringAsFixed(1)}%',
            style: GoogleFonts.jetBrainsMono(
                color: color,
                fontSize: res.fontSize(11),
                fontWeight: FontWeight.bold)),
      ]),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────
  Widget _chip(String label, Color borderColor) {
    if (label.isEmpty) return const SizedBox();
    
    // Capitalize first character (e.g. sports -> Sports, custom -> Custom)
    final capitalized = label.trim().isNotEmpty
        ? label.trim()[0].toUpperCase() + label.trim().substring(1)
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: borderColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor.withValues(alpha: 0.22), width: 1),
      ),
      child: Text(
        capitalized,
        style: GoogleFonts.jetBrainsMono(
          color: borderColor.opacity < 0.3 ? Colors.white60 : borderColor,
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _shortNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  Color _outcomeColor(Hip4Outcome o, int idx) {
    if (o.label.toLowerCase() == 'yes') return AppColors.trendGreen;
    if (o.label.toLowerCase() == 'no') return const Color(0xFFB886FF);
    return _palette[idx % _palette.length];
  }

  Color _classColor(String cls) {
    switch (cls) {
      case 'priceBinary': return const Color(0xFF2EE2BA);
      case 'priceBucket': return const Color(0xFF4299E1);
      case 'question':    return const Color(0xFFED8936);
      default:            return const Color(0xFF718096);
    }
  }
}

// ══════════════════════════════════════════════════════════════════
//  Candlestick Painter  —  IQR-clipped Y axis, scroll & tap aware
// ══════════════════════════════════════════════════════════════════
class _CandlePainter extends CustomPainter {
  final List<Hip4Candle> candles;
  final Color green, red, gridColor;
  final int? selectedIdx;
  final double slotW;
  final double leftPad;
  final String currencySymbol;

  _CandlePainter({
    required this.candles,
    required this.green,
    required this.red,
    required this.gridColor,
    required this.selectedIdx,
    required this.slotW,
    required this.leftPad,
    required this.currencySymbol,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    const rightPad  = 6.0;
    const topPad    = 6.0;
    const bottomPad = 20.0;
    final chartW = size.width  - leftPad - rightPad;
    final chartH = size.height - topPad  - bottomPad;

    // ── IQR-fenced Y range — outliers clipped, visible candles fill chart ──
    final allPx = candles
        .expand((c) => [c.open, c.close, c.high, c.low])
        .toList()
      ..sort();
    final q1  = allPx[(allPx.length * 0.25).floor()];
    final q3  = allPx[(allPx.length * 0.75).floor()];
    final iqr = (q3 - q1).clamp(0.0001, double.infinity);

    // Standard box-plot fence: anything outside q1-2×IQR … q3+2×IQR is an outlier
    final lowerFence = q1 - iqr * 2.0;
    final upperFence = q3 + iqr * 2.0;

    // Build visible range from in-fence prices only
    double minP = double.infinity;
    double maxP = -double.infinity;
    for (final c in candles) {
      for (final px in [c.open, c.close, c.high, c.low]) {
        if (px >= lowerFence && px <= upperFence) {
          if (px < minP) minP = px;
          if (px > maxP) maxP = px;
        }
      }
    }
    // Fallback: if all values were outliers, use raw extremes
    if (minP == double.infinity || maxP == -double.infinity) {
      minP = allPx.first;
      maxP = allPx.last;
    }

    // Guarantee a visible range
    if (maxP - minP < 0.0005) {
      final mid = (maxP + minP) / 2;
      minP = mid - 0.005;
      maxP = mid + 0.005;
    }
    // Tight 10% padding so candles fill most of the chart height
    final pad = (maxP - minP) * 0.10;
    minP -= pad;
    maxP += pad;
    final range = (maxP - minP).clamp(0.0001, double.infinity);

    // Clamp price to visible range before converting to Y coordinate
    double toY(double price) =>
        topPad + ((maxP - price.clamp(minP, maxP)) / range * chartH);

    // ── Grid ──
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.25)
      ..strokeWidth = 0.5;
    const gridLines = 4;
    for (int i = 0; i <= gridLines; i++) {
      final y = topPad + chartH / gridLines * i;
      canvas.drawLine(
          Offset(leftPad, y), Offset(leftPad + chartW, y), gridPaint);
    }

    // ── Y labels (Pinned to the left, but we can draw them on top of the leftPad offset) ──
    final labelStyle = TextStyle(
        color: Colors.white.withValues(alpha: 0.55), fontSize: 8.5, fontFamily: 'JetBrainsMono');
    for (int i = 0; i <= gridLines; i++) {
      final y   = topPad + chartH / gridLines * i;
      final val = maxP - (range / gridLines) * i;
      final tp  = TextPainter(
        text: TextSpan(text: val.toStringAsFixed(3), style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      // Draw nicely in the left margin area
      tp.paint(canvas, Offset(6, y - tp.height / 2));
    }

    // ── Candle bodies + wicks ──
    final n    = candles.length;
    final barW = (slotW * 0.50).clamp(6.0, 20.0);

    // If there is a selected index, draw a selection guide line
    if (selectedIdx != null && selectedIdx! >= 0 && selectedIdx! < n) {
      final cx = leftPad + slotW * selectedIdx! + slotW / 2;
      final guidePaint = Paint()
        ..color = AppColors.brandAccent.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      // Draw vertical dashed guide line
      double currentY = topPad;
      const dashH = 4.0;
      const spaceH = 4.0;
      while (currentY < size.height - bottomPad) {
        canvas.drawLine(
          Offset(cx, currentY),
          Offset(cx, min(currentY + dashH, size.height - bottomPad)),
          guidePaint,
        );
        currentY += dashH + spaceH;
      }
    }

    for (int i = 0; i < n; i++) {
      final c    = candles[i];
      final isUp = c.close >= c.open;
      final isSelected = (i == selectedIdx);
      Color col  = isUp ? green : red;
      
      // If selected, highlight or give a white border
      final cx   = leftPad + slotW * i + slotW / 2;

      final yHigh  = toY(c.high.clamp(minP, maxP));
      final yLow   = toY(c.low .clamp(minP, maxP));
      final yOpen  = toY(c.open .clamp(minP, maxP));
      final yClose = toY(c.close.clamp(minP, maxP));

      // wick
      canvas.drawLine(
          Offset(cx, yHigh), Offset(cx, yLow),
          Paint()..color = col.withValues(alpha: isSelected ? 0.9 : 0.45)..strokeWidth = 1.25);

      // body
      final isDoji = (c.open - c.close).abs() < 0.000001;
      final bodyTop = min(yOpen, yClose);
      // Doji: show as thin 2px horizontal dash. Normal: clamp body to max half-chart-height.
      final bodyH   = isDoji ? 2.0 : (yOpen - yClose).abs().clamp(3.0, chartH * 0.98);
      
      if (isSelected) {
        // Draw selection halo/glow
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(cx - barW / 2 - 2, bodyTop - 2, barW + 4, bodyH + 4),
              const Radius.circular(2.5)),
          Paint()..color = Colors.white.withValues(alpha: 0.3)..style = PaintingStyle.fill,
        );
      }

      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - barW / 2, bodyTop, barW, bodyH),
            const Radius.circular(1.5)),
        Paint()..color = col..style = PaintingStyle.fill,
      );

      // Close price sticker label above every candle (no overlap since slotW is 34.0)
      final priceStr = c.close.toStringAsFixed(3);
      final tpPrice = TextPainter(
        text: TextSpan(
          text: priceStr,
          style: TextStyle(
            color: Colors.white.withValues(alpha: isSelected ? 0.9 : 0.55),
            fontSize: 7.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'JetBrainsMono',
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tpPrice.paint(canvas, Offset(cx - tpPrice.width / 2, yHigh - tpPrice.height - 4));
    }

    // ── X labels (every step) ──
    final tsStyle = TextStyle(
        color: Colors.white.withValues(alpha: 0.55), fontSize: 8.0, fontFamily: 'JetBrainsMono');
    // Decide label step based on slot size to avoid overcrowding labels
    final step = (70.0 / slotW).ceil().clamp(1, 10);
    for (int i = 0; i < n; i++) {
      if (i % step != 0) continue;
      final cx    = leftPad + slotW * i + slotW / 2;
      final label = DateFormat('HH:mm')
          .format(candles[i].timestamp.toLocal());
      final tp = TextPainter(
        text: TextSpan(text: label, style: tsStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(cx - tp.width / 2, size.height - bottomPad + 4));
    }

    // ── Floating canvas-rendered tooltip box ──
    if (selectedIdx != null && selectedIdx! >= 0 && selectedIdx! < n) {
      final c     = candles[selectedIdx!];
      final cx    = leftPad + slotW * selectedIdx! + slotW / 2;
      final yHigh = toY(c.high.clamp(minP, maxP));

      const tooltipW = 126.0;
      const tooltipH = 58.0;

      // Position tooltip above the candle high, but clamp coordinates to viewport
      double tx = cx - tooltipW / 2;
      double ty = yHigh - tooltipH - 8;

      if (tx < leftPad + 2) tx = leftPad + 2;
      if (tx + tooltipW > size.width - rightPad - 2) {
        tx = size.width - rightPad - 2 - tooltipW;
      }
      if (ty < topPad + 2) {
        ty = yHigh + 8; // flip Below if too close to top
      }

      final rect  = Rect.fromLTWH(tx, ty, tooltipW, tooltipH);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(5));

      // Draw shadow
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );

      // Draw background box
      canvas.drawRRect(
        rrect,
        Paint()..color = const Color(0xFF1E222D)..style = PaintingStyle.fill,
      );

      // Draw boundary stroke border
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = AppColors.brandAccent.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );

      // Prepare text values
      final timeStr = DateFormat('dd MMM · HH:mm').format(c.timestamp.toLocal());
      final ohlcStr = 'O:${c.open.toStringAsFixed(3)} H:${c.high.toStringAsFixed(3)}\n'
                      'L:${c.low.toStringAsFixed(3)} C:${c.close.toStringAsFixed(3)}';
      final volStr  = 'Vol: ${NumberFormat('#,##0').format(c.volume.toInt())} $currencySymbol';

      final tpTime = TextPainter(
        text: TextSpan(
          text: timeStr,
          style: const TextStyle(color: Colors.white38, fontSize: 7, fontFamily: 'JetBrainsMono'),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      final tpOhlc = TextPainter(
        text: TextSpan(
          text: ohlcStr,
          style: const TextStyle(color: Colors.white70, fontSize: 7.5, height: 1.3, fontFamily: 'JetBrainsMono'),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      final tpVol = TextPainter(
        text: TextSpan(
          text: volStr,
          style: const TextStyle(color: AppColors.brandAccent, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'JetBrainsMono'),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      // Draw texts inside the box
      tpTime.paint(canvas, Offset(tx + 6, ty + 5));
      tpOhlc.paint(canvas, Offset(tx + 6, ty + 15));
      tpVol.paint(canvas, Offset(tx + 6, ty + 42));
    }
  }

  @override
  bool shouldRepaint(covariant _CandlePainter old) =>
      old.candles != candles || old.green != green || old.selectedIdx != selectedIdx;
}


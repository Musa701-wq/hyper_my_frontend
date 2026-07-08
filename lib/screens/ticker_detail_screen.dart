import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

import '../models/orderbook_model.dart';
import '../models/ticker_model.dart';
import '../services/orderbook_service.dart';
import '../services/candles_service.dart';
import '../models/hip4_model.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import '../widgets/orderbook_panel.dart';
import '../widgets/ticker_info_tab.dart';
import 'recent_trades_screen.dart';
import '../analytics/analytics_service.dart';
import '../utils/ticker_formatters.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import '../models/funding_history_model.dart';
import '../services/funding_history_service.dart';
import '../widgets/predicted_funding_card.dart';

class TickerDetailScreen extends StatefulWidget {
  final TickerModel ticker;

  const TickerDetailScreen({super.key, required this.ticker});

  @override
  State<TickerDetailScreen> createState() => _TickerDetailScreenState();
}

class _TickerDetailScreenState extends State<TickerDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  OrderBookService? _orderBookService;
  OrderBookSnapshot? _orderBook;
  bool _orderBookLoading = false;
  String? _orderBookError;
  bool _orderBookStarted = false;

  // Zoom & Dual-Axis Scroll Parameters
  late ScrollController _scrollController;
  late ScrollController _verticalScrollController;
  double _slotW = 20.0;
  double _baseSlotW = 20.0;
  double _lastFocalX = 0.0;
  double _lastFocalY = 0.0;
  int _lastPointerCount = 0;

  // Candles Data State
  List<Hip4Candle> _candles = [];
  bool _candlesLoading = true;
  String? _candlesError;
  Timer? _candlesTimer;
  int? _selectedCandleIdx;

  String get _orderBookSymbol => widget.ticker.orderBookSymbol;
  String? get _orderBookDex => widget.ticker.orderBookDex;
  String get _orderBookLabel => widget.ticker.orderBookLabel;

  String get _sizeLabel {
    final name = widget.ticker.displayName.isNotEmpty ? widget.ticker.displayName : widget.ticker.symbol;
    final afterColon = name.contains(':') ? name.split(':').last : name;
    return afterColon.split('-').first;
  }

  @override
  void initState() {
    super.initState();
    final int tabLength = widget.ticker.marketType == 'spot' ? 2 : 3;
    _tabController = TabController(length: tabLength, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController = ScrollController();
    _verticalScrollController = ScrollController();
    
    // Register scroll event listener to dynamically update the Y-axis as the user scrolls
    _scrollController.addListener(_onScrollUpdated);

    // Initial fetch of candlesticks
    _fetchCandleData();
    // Regular polling every 12 seconds for realtime updates
    _candlesTimer = Timer.periodic(const Duration(seconds: 12), (_) => _fetchCandleData());
  }

  void _onScrollUpdated() {
    // Triggers rebuild to update visible Y scale ticks
    if (mounted) {
      setState(() {});
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 1) {
      AnalyticsService.logOrderBookAccess(widget.ticker.symbol);
      if (!_orderBookStarted) {
        _startOrderBook();
      }
    }
  }

  Future<void> _fetchCandleData() async {
    try {
      final data = await CandlesService.fetchCandles(
        coin: widget.ticker.symbol,
        interval: '1h',
        daysBack: 1,
      );
      if (mounted) {
        setState(() {
          _candles = data;
          _candlesLoading = false;
          _candlesError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _candlesLoading = false;
          _candlesError = e.toString();
        });
      }
    }
  }

  Future<void> _startOrderBook() async {
    if (_orderBookSymbol.isEmpty) {
      setState(() => _orderBookError = 'No symbol for order book');
      return;
    }

    _orderBookStarted = true;
    setState(() {
      _orderBookLoading = true;
      _orderBookError = null;
    });

    _orderBookService = OrderBookService(symbol: _orderBookSymbol, dex: _orderBookDex);

    await _orderBookService!.startLive(
      onUpdate: (snapshot) {
        if (!mounted) return;
        setState(() {
          _orderBook = snapshot;
          _orderBookLoading = false;
          _orderBookError = null;
        });
      },
      onError: (e) => debugPrint('Order book error ($_orderBookLabel): $e'),
    );

    if (!mounted) return;
    if (_orderBook == null) {
      await Future<void>.delayed(const Duration(seconds: 6));
      if (!mounted || _orderBook != null) return;
      final String displayName = widget.ticker.displayName.isNotEmpty 
          ? widget.ticker.displayName.split(':').last.split('-').first 
          : widget.ticker.symbol;
          
      setState(() {
        _orderBookLoading = false;
        _orderBookError =
            'We can\'t load the order book for $displayName right now. It might be too new or there isn\'t much trading happening yet. Please check back later!';
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.removeListener(_onScrollUpdated);
    _scrollController.dispose();
    _verticalScrollController.dispose();
    _orderBookService?.dispose();
    _candlesTimer?.cancel();
    super.dispose();
  }

  // Width of scrollable drawing surface
  double _canvasWidth(int count, double minW) {
    const double rightPad = 80.0; // breathing room for the latest candle on the right
    final needed = count * _slotW + rightPad;
    return needed > minW ? needed : minW;
  }

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0C0D0E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.brandAccent, size: res.fontSize(20)),
        ),
        titleSpacing: 0,
        title: Text(
          widget.ticker.displaySymbol,
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.brandAccent,
            fontSize: res.fontSize(16),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  AnalyticsService.logTickerRecentActivity(widget.ticker.symbol);
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => RecentTradesScreen(
                        symbol: widget.ticker.symbol,
                        dex: widget.ticker.dex,
                        iconUrl: widget.ticker.iconUrl,
                      ),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                      transitionsBuilder: (_, __, ___, child) => child,
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: res.spacing(8),
                    vertical: res.spacing(4),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.brandAccent.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history,
                        color: AppColors.brandAccent,
                        size: res.fontSize(10),
                      ),
                      SizedBox(width: res.spacing(4)),
                      Text(
                        'RECENTS',
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.brandAccent,
                          fontSize: res.fontSize(9),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            height: 38,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.surfaceBright.withOpacity(0.1)),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.brandAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: AppColors.brandAccent.withOpacity(0.4), width: 1.2),
              ),
              dividerColor: Colors.transparent,
              labelColor: AppColors.brandAccent,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: GoogleFonts.jetBrainsMono(
                fontSize: res.fontSize(10),
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: GoogleFonts.jetBrainsMono(
                fontSize: res.fontSize(10),
              ),
              padding: EdgeInsets.zero,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: widget.ticker.marketType == 'spot'
                  ? const [
                      Tab(text: 'Info'),
                      Tab(text: 'Order Book'),
                    ]
                  : const [
                      Tab(text: 'Info'),
                      Tab(text: 'Order Book'),
                      Tab(text: 'Funding'),
                    ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Info Screen with Candlestick Chart + Details below
          SingleChildScrollView(
            controller: _verticalScrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                _buildCandleChartSection(res),
                const SizedBox(height: 8),
                TickerInfoTab(ticker: widget.ticker),
              ],
            ),
          ),
          // Tab 2: Order Book View
          OrderBookPanel(
            snapshot: _orderBook,
            isLoading: _orderBookLoading,
            errorMessage: _orderBookError,
            sizeLabel: _sizeLabel,
          ),
          // Tab 3: Funding History View (omitted for spot coins)
          if (widget.ticker.marketType != 'spot')
            _FundingHistoryContent(
              res: res,
              initialCoin: widget.ticker.symbol,
              showHeaderSelectors: false,
            ),
        ],
      ),
    );
  }

  Widget _buildCandleChartSection(Responsive res) {
    if (_candlesLoading) {
      return Container(
        height: 240,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF060708),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF161A22)),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandAccent),
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_candles.isEmpty) {
      return Container(
        height: 240,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF060708),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF161A22)),
        ),
        child: Center(
          child: Text(
            'No candle data available',
            style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 12),
          ),
        ),
      );
    }

    const double chartH = 175.0;
    final borderSide = BorderSide(color: const Color(0xFF161A22), width: 1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Candle Header: selected or latest values
          _buildOhlcValuesWidget(res),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final viewportW = constraints.maxWidth; // Full width — labels overlaid inside
              final canvasW = _canvasWidth(_candles.length, viewportW);

              // ── Compute Visible Indexes from Scroll Offset to dynamically auto-scale Y ──
              int startIdx = 0;
              int endIdx = _candles.length;
              if (_scrollController.hasClients) {
                final offset = _scrollController.offset;
                final viewportLeft = (canvasW - viewportW - offset).clamp(0.0, canvasW);
                startIdx = (viewportLeft / _slotW).floor().clamp(0, _candles.length);
                final visibleCount = (viewportW / _slotW).ceil() + 1;
                endIdx = (startIdx + visibleCount).clamp(0, _candles.length);
              } else {
                // Initial load default visible list slice: last 15 candles (rightmost) to ensure high vertical zoom
                startIdx = (_candles.length - 15).clamp(0, _candles.length);
                endIdx = _candles.length;
              }

              final visibleCandles = _candles.sublist(startIdx, endIdx);

              // Calculate stable min/max scale values based on visible candles for a zoomed in view
              double minP = double.infinity;
              double maxP = -double.infinity;
              final allPx = visibleCandles.expand((c) => [c.open, c.close, c.high, c.low]).toList()..sort();
              
              if (allPx.isNotEmpty) {
                final q1 = allPx[(allPx.length * 0.25).floor()];
                final q3 = allPx[(allPx.length * 0.75).floor()];
                final iqr = (q3 - q1).clamp(0.0001, double.infinity);
                final lowerFence = q1 - iqr * 2.0;
                final upperFence = q3 + iqr * 2.0;

                for (final c in visibleCandles) {
                  for (final px in [c.open, c.close, c.high, c.low]) {
                    if (px >= lowerFence && px <= upperFence) {
                      if (px < minP) minP = px;
                      if (px > maxP) maxP = px;
                    }
                  }
                }
                if (minP == double.infinity || maxP == -double.infinity) {
                  minP = allPx.first;
                  maxP = allPx.last;
                }
              }

              if (minP == double.infinity || maxP == -double.infinity) {
                minP = 0.0;
                maxP = 1.0;
              }

              if (maxP - minP < 0.0005) {
                final mid = (maxP + minP) / 2;
                minP = mid - 0.005;
                maxP = mid + 0.005;
              }
              final pad = (maxP - minP) * 0.10;
              minP -= pad;
              maxP += pad;

              // Direct NaN/Infinity guards
              if (minP.isNaN || minP.isInfinite) minP = 0.0;
              if (maxP.isNaN || maxP.isInfinite) maxP = 1.0;

              // Calculate Y-axis parameters
              final int? activePriceIdx = _selectedCandleIdx ?? (_candles.isNotEmpty ? _candles.length - 1 : null);
              final double? highlightPrice = activePriceIdx != null ? _candles[activePriceIdx].close : null;
              final bool isPriceUp = activePriceIdx != null ? _candles[activePriceIdx].close >= _candles[activePriceIdx].open : true;

              // Single chart card — labels overlaid INSIDE using Stack
              return Container(
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFF060708),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderSide.color, width: borderSide.width),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // ── Layer 1: Scrollable Candlestick canvas ──
                      Positioned.fill(
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (details) {
                              // reverse:true mirrors the X axis. localPosition.dx=0 is the rightmost (latest) candle.
                              // Real canvas X = canvasW - scrollOffset - localX
                              final scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
                              final realX = (canvasW - scrollOffset - details.localPosition.dx).clamp(0.0, canvasW - 1);
                              final idx = (realX / _slotW).floor().clamp(0, _candles.length - 1);
                              setState(() => _selectedCandleIdx = _selectedCandleIdx == idx ? null : idx);
                            },
                            child: CustomPaint(
                              size: Size(canvasW, chartH),
                              painter: _CandlePainter(
                                candles: _candles,
                                minP: minP,
                                maxP: maxP,
                                green: AppColors.trendGreen,
                                red: AppColors.trendRed,
                                gridColor: const Color(0xFF161A22),
                                selectedIdx: _selectedCandleIdx,
                                slotW: _slotW,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ── Layer 2: Y-axis price labels overlaid on right side ──
                      Positioned(
                        top: 0,
                        bottom: 0,
                        right: 0,
                        width: 68,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  const Color(0xFF060708).withOpacity(0.0),
                                  const Color(0xFF060708).withOpacity(0.82),
                                  const Color(0xFF060708).withOpacity(0.95),
                                ],
                              ),
                            ),
                            child: LayoutBuilder(
                              builder: (ctx, yc) {
                                const double topPad = 12.0;
                                const double botPad = 18.0;
                                final double h = yc.maxHeight - topPad - botPad;
                                final double range = (maxP - minP).clamp(0.0001, double.infinity);

                                return Stack(
                                  children: [
                                    // 5 price ticks
                                    for (int i = 0; i <= 4; i++)
                                      Positioned(
                                        right: 6,
                                        top: (topPad + h * (i / 4.0) - 6).clamp(0, yc.maxHeight - 14.0),
                                        child: Text(
                                          _fmtPxRaw(maxP - range * (i / 4.0)),
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),

                                    // Highlight price badge
                                    if (highlightPrice != null)
                                      Positioned(
                                        right: 4,
                                        top: (topPad + ((maxP - highlightPrice.clamp(minP, maxP)) / range * h) - 9)
                                            .clamp(0, yc.maxHeight - 18.0),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isPriceUp ? AppColors.trendGreen : AppColors.trendRed,
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            _fmtPxRaw(highlightPrice),
                                            style: const TextStyle(
                                              color: Color(0xFF060708),
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOhlcValuesWidget(Responsive res) {
    final idx = (_selectedCandleIdx != null && _selectedCandleIdx! >= 0 && _selectedCandleIdx! < _candles.length)
        ? _selectedCandleIdx!
        : null;

    final c = idx != null ? _candles[idx] : _candles.last;
    final isUp = c.close >= c.open;
    final label = idx != null
        ? DateFormat('dd MMM · HH:mm').format(c.timestamp.toLocal())
        : 'Latest 1H candle';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF060708),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF161A22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRect(
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 10, color: Colors.white30),
                const SizedBox(width: 4),
                Text(label, style: GoogleFonts.jetBrainsMono(color: Colors.white30, fontSize: 8.5)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.brandAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Vol ${NumberFormat('#,##0').format(c.volume.toInt())}',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.brandAccent,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _ohlcItem('Open', c.open, Colors.white70, res),
              _verticalDivider(),
              _ohlcItem('Close', c.close, isUp ? AppColors.trendGreen : AppColors.trendRed, res),
              _verticalDivider(),
              _ohlcItem('High', c.high, AppColors.trendGreen, res),
              _verticalDivider(),
              _ohlcItem('Low', c.low, AppColors.trendRed, res),
            ],
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() => Container(
        width: 1, 
        height: 24, 
        color: const Color(0xFF161A22),
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );

  Widget _ohlcItem(String label, double val, Color color, Responsive res) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white30,
              fontSize: res.fontSize(7.5),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            child: Text(
              fmtPx(val),
              style: GoogleFonts.jetBrainsMono(
                color: color,
                fontSize: res.fontSize(11),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _YAxisPainter extends CustomPainter {
  final double minP;
  final double maxP;
  final int gridLines;
  final double? selectedPrice;
  final bool isPriceUp;

  _YAxisPainter({
    required this.minP,
    required this.maxP,
    required this.gridLines,
    this.selectedPrice,
    this.isPriceUp = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    try {
      if (size.height < 5.0 || size.width < 5.0) return;

      const topPad = 6.0;
      const bottomPad = 16.0;
      final chartH = size.height - topPad - bottomPad;
      final range = (maxP - minP).clamp(0.0001, double.infinity);

      final tickStyle = const TextStyle(
        color: Colors.white,
        fontSize: 8.0,
        fontWeight: FontWeight.w600,
        fontFamily: 'JetBrainsMono',
      );

      // ── Grid price ticks (left-aligned inside clean margins) ──
      for (int i = 0; i <= gridLines; i++) {
        final y = topPad + chartH / gridLines * i;
        final val = maxP - (range / gridLines) * i;
        final tp = TextPainter(
          text: TextSpan(text: _fmtPxRaw(val), style: tickStyle),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(8.0, y - tp.height / 2));
      }

      // ── Selected price Tag badge on static Y axis ──
      if (selectedPrice != null) {
        final ySel = topPad + ((maxP - selectedPrice!.clamp(minP, maxP)) / range * chartH);
        final text = _fmtPxRaw(selectedPrice!);
        final tp = TextPainter(
          text: TextSpan(
            text: text,
            style: const TextStyle(
              color: Color(0xFF111417),
              fontSize: 8.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'JetBrainsMono',
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();

        final badgeW = size.width - 4.0;
        final badgeH = tp.height + 4.0;

        final badgePaint = Paint()..color = isPriceUp ? AppColors.trendGreen : AppColors.trendRed;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(2.0, ySel - badgeH / 2, badgeW, badgeH),
            const Radius.circular(3),
          ),
          badgePaint,
        );

        tp.paint(canvas, Offset(2.0 + (badgeW - tp.width) / 2, ySel - tp.height / 2));
      }
    } catch (e, st) {
      debugPrint('Error in YAxis paint: $e\n$st');
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CandlePainter extends CustomPainter {
  final List<Hip4Candle> candles;
  final double minP;
  final double maxP;
  final Color green, red, gridColor;
  final int? selectedIdx;
  final double slotW;

  _CandlePainter({
    required this.candles,
    required this.minP,
    required this.maxP,
    required this.green,
    required this.red,
    required this.gridColor,
    required this.selectedIdx,
    required this.slotW,
  });

  @override
  void paint(Canvas canvas, Size size) {
    try {
      if (candles.isEmpty) return;
      if (size.height < 5.0 || size.width < 5.0) return;

      const topPad = 6.0;
      const bottomPad = 16.0;
      final chartW = size.width;
      final chartH = size.height - topPad - bottomPad;
      final range = (maxP - minP).clamp(0.0001, double.infinity);

      double toY(double price) => topPad + ((maxP - price.clamp(minP, maxP)) / range * chartH);

      // ── Horizontal Grid Lines ──
      final gridPaint = Paint()
        ..color = gridColor.withOpacity(0.08)
        ..strokeWidth = 0.5;
      const gridLines = 4;
      for (int i = 0; i <= gridLines; i++) {
        final y = topPad + chartH / gridLines * i;
        canvas.drawLine(Offset(0, y), Offset(chartW, y), gridPaint);
      }

      // ── Draw horizontal guide line for latest price if nothing is selected ──
      if (selectedIdx == null && candles.isNotEmpty) {
        final lastC = candles.last;
        final yLatest = toY(lastC.close);
        final currentPricePaint = Paint()
          ..color = (lastC.close >= lastC.open ? green : red).withOpacity(0.35)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke;
        
        double currentX = 0;
        const dashH = 4.0;
        const spaceH = 4.0;
        while (currentX < chartW) {
          canvas.drawLine(Offset(currentX, yLatest), Offset(currentX + dashH, yLatest), currentPricePaint);
          currentX += dashH + spaceH;
        }
      }

      // ── X-Axis Time Labels (Drawn at the bottom) ──
      final xLabelStyle = TextStyle(
        color: Colors.white.withOpacity(0.40),
        fontSize: 8.0,
        fontFamily: 'JetBrainsMono',
        fontWeight: FontWeight.w500,
      );

      final int tickInterval = (candles.length / 4).floor().clamp(3, 15);
      for (int i = 0; i < candles.length; i++) {
        if (i % tickInterval == 0 || i == candles.length - 1) {
          final c = candles[i];
          final x = i * slotW + slotW / 2;
          final timeLabel = i == 0 || c.timestamp.toLocal().hour == 0
              ? DateFormat('dd MMM').format(c.timestamp.toLocal())
              : DateFormat('HH:mm').format(c.timestamp.toLocal());

          final tp = TextPainter(
            text: TextSpan(text: timeLabel, style: xLabelStyle),
            textDirection: ui.TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(x - tp.width / 2, topPad + chartH + 2.0));
        }
      }

      // ── Draw Candles ──
      for (int i = 0; i < candles.length; i++) {
        final c = candles[i];
        final x = i * slotW + slotW / 2;
        final yOpen = toY(c.open);
        final yClose = toY(c.close);
        final yHigh = toY(c.high);
        final yLow = toY(c.low);

        final isUp = c.close >= c.open;
        final color = isUp ? green : red;

        final bodyPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        final linePaint = Paint()
          ..color = color
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

        // wick
        canvas.drawLine(Offset(x, yHigh), Offset(x, yLow), linePaint);

        // body
        final bodyTop = yOpen < yClose ? yOpen : yClose;
        final bodyBottom = yOpen < yClose ? yClose : yOpen;
        final bodyH = (bodyBottom - bodyTop).clamp(1.0, double.infinity);
        final candleW = (slotW * 0.65).clamp(2.0, 24.0);

        canvas.drawRect(
          Rect.fromLTWH(x - candleW / 2, bodyTop, candleW, bodyH),
          bodyPaint,
        );

        // focus crosshair lines & time tooltip
        if (selectedIdx == i) {
          final selectorPaint = Paint()
            ..color = AppColors.brandAccent.withOpacity(0.5)
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke;

          // Vertical dotted line
          double currentY = topPad;
          const dashH = 4.0;
          const spaceH = 4.0;
          while (currentY < topPad + chartH) {
            canvas.drawLine(Offset(x, currentY), Offset(x, currentY + dashH), selectorPaint);
            currentY += dashH + spaceH;
          }

          // Horizontal dotted line
          final ySel = toY(c.close);
          double currentX = 0;
          while (currentX < chartW) {
            canvas.drawLine(Offset(currentX, ySel), Offset(currentX + dashH, ySel), selectorPaint);
            currentX += dashH + spaceH;
          }

          // Draw time label at bottom of vertical crosshair line
          final timeText = DateFormat('dd MMM HH:mm').format(c.timestamp.toLocal());
          final tpTime = TextPainter(
            text: TextSpan(
              text: timeText, 
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 8.0, 
                fontFamily: 'JetBrainsMono',
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: ui.TextDirection.ltr,
          )..layout();
          
          final timeBadgeW = tpTime.width + 8.0;
          final timeBadgeH = tpTime.height + 4.0;
          
          final timeBgPaint = Paint()..color = AppColors.surfaceBright;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x - timeBadgeW / 2, topPad + chartH + 2.0, timeBadgeW, timeBadgeH),
              const Radius.circular(3),
            ),
            timeBgPaint,
          );
          tpTime.paint(canvas, Offset(x - tpTime.width / 2, topPad + chartH + 2.0 + 2.0));
        }
      }
    } catch (e, st) {
      debugPrint('Error in Candle paint: $e\n$st');
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

String _fmtPxRaw(double v) {
  if (v.isNaN || v.isInfinite) return '—';
  if (v <= 0) return '—';
  if (v >= 1000) return v.toStringAsFixed(2);
  if (v >= 1) return v.toStringAsFixed(4);
  return v.toStringAsFixed(6);
}

// ── Funding History View Content ──────────────────────────────────────────
class _FundingHistoryContent extends StatefulWidget {
  final Responsive res;
  final String initialCoin;
  final bool showHeaderSelectors;
  const _FundingHistoryContent({required this.res, required this.initialCoin, required this.showHeaderSelectors});

  @override
  State<_FundingHistoryContent> createState() => _FundingHistoryContentState();
}

class _FundingHistoryContentState extends State<_FundingHistoryContent> {
  late String _selectedCoin;
  int _selectedDays = 7;
  String _selectedView = 'Line'; // 'Line', 'Candle', 'Table'
  List<FundingHistoryEntry> _data = [];
  bool _isLoading = false;
  String _error = '';
  int? _selectedCandleIdx;
  int? _selectedLineIdx;

  final _coinSearchController = TextEditingController();
  final _candleScrollController = ScrollController();
  final _lineScrollController = ScrollController();
  final _service = FundingHistoryService();

  @override
  void initState() {
    super.initState();
    _selectedCoin = widget.initialCoin;
    _coinSearchController.text = _selectedCoin;
    _fetchData();
  }

  @override
  void dispose() {
    _coinSearchController.dispose();
    _candleScrollController.dispose();
    _lineScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final startTimeMs = DateTime.now().millisecondsSinceEpoch - (_selectedDays * 24 * 60 * 60 * 1000);
      final list = await _service.fetchFundingHistory(_selectedCoin.trim(), startTimeMs);
      setState(() {
        _data = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic>? _computeStats() {
    if (_data.isEmpty) return null;
    final rates = _data.map((e) => e.fundingRate).toList();
    final avg = rates.reduce((s, r) => s + r) / rates.length;
    final max = rates.reduce((a, b) => a > b ? a : b);
    final min = rates.reduce((a, b) => a < b ? a : b);
    final posCount = rates.where((r) => r > 0).length;
    final negCount = rates.where((r) => r < 0).length;
    final annualAPR = avg * 8760 * 100;
    final cumulative = rates.reduce((s, r) => s + r) * 100;

    String sentiment = 'Neutral';
    if (avg > 0.00001) sentiment = 'Bullish';
    if (avg < -0.00001) sentiment = 'Bearish';

    return {
      'avg': avg,
      'avgPct': avg * 100,
      'max': max,
      'min': min,
      'annualAPR': annualAPR,
      'cumulative': cumulative,
      'posCount': posCount,
      'negCount': negCount,
      'sentiment': sentiment,
    };
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.res;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeaderSelectors)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildAssetSelector(res),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeframeSelector(res),
              _buildViewToggle(res),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _isLoading
              ? _buildShimmerBody(res)
              : _error.isNotEmpty
                  ? _buildErrorView(res)
                  : _buildDataResult(res),
        ),
      ],
    );
  }

  Widget _buildAssetSelector(Responsive res) {
    final popular = ['BTC', 'ETH', 'SOL', 'HYPE', 'SUIL'];
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: popular.map((coin) {
                final isSelected = coin == _selectedCoin.toUpperCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCoin = coin;
                        _coinSearchController.text = coin;
                      });
                      _fetchData();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.brandAccent.withOpacity(0.12) : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.brandAccent : AppColors.surfaceBright.withOpacity(0.4),
                          width: isSelected ? 1.0 : 0.8,
                        ),
                      ),
                      child: Text(
                        coin,
                        style: GoogleFonts.jetBrainsMono(
                          color: isSelected ? AppColors.brandAccent : Colors.white,
                          fontSize: res.fontSize(11),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 90,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.surfaceBright.withOpacity(0.4), width: 0.8),
          ),
          child: TextField(
            controller: _coinSearchController,
            style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: res.fontSize(11)),
            decoration: InputDecoration(
              hintText: 'Other...',
              hintStyle: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(10)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              isDense: true,
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                setState(() {
                  _selectedCoin = value.trim().toUpperCase();
                });
                _fetchData();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeframeSelector(Responsive res) {
    final periods = [
      (1, '24 Hours'),
      (7, '7 Days'),
      (30, '30 Days'),
      (90, '90 Days'),
    ];

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBright.withOpacity(0.4), width: 0.8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedDays,
          dropdownColor: const Color(0xFF0F1115),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 16),
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white,
            fontSize: res.fontSize(10),
            fontWeight: FontWeight.bold,
          ),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedDays = val;
              });
              _fetchData();
            }
          },
          items: periods.map((p) {
            return DropdownMenuItem<int>(
              value: p.$1,
              child: Text(p.$2),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildViewToggle(Responsive res) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBright.withOpacity(0.4), width: 0.8),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _viewPill('Line', Icons.show_chart, _selectedView == 'Line', res),
          _viewPill('Candle', Icons.candlestick_chart, _selectedView == 'Candle', res),
          _viewPill('Table', Icons.table_rows_rounded, _selectedView == 'Table', res),
        ],
      ),
    );
  }

  Widget _viewPill(String label, IconData icon, bool active, Responsive res) {
    return GestureDetector(
      onTap: () => setState(() => _selectedView = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.brandAccent.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? AppColors.brandAccent.withOpacity(0.3) : Colors.transparent,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: active ? AppColors.brandAccent : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.jetBrainsMono(
                color: active ? AppColors.brandAccent : AppColors.textSecondary,
                fontSize: res.fontSize(9),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBody(Responsive res) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1E222D),
      highlightColor: const Color(0xFF2A2F3A),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Container(height: 80, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
            const SizedBox(height: 16),
            Row(
              children: List.generate(3, (index) => Expanded(child: Container(height: 80, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))))),
            ),
            const SizedBox(height: 20),
            Expanded(child: Container(width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(Responsive res) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.trendRed, size: 40),
          const SizedBox(height: 12),
          Text(
            'Failed to fetch funding history',
            style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(11)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchData,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandAccent.withOpacity(0.12), foregroundColor: AppColors.brandAccent),
            child: Text('Retry', style: GoogleFonts.jetBrainsMono(fontSize: res.fontSize(11))),
          ),
        ],
      ),
    );
  }

  Widget _buildDataResult(Responsive res) {
    final stats = _computeStats();
    if (stats == null) {
      return Center(
        child: Text('No entries found.', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(11))),
      );
    }

    final double avgPct = stats['avgPct'];
    final double apr = stats['annualAPR'];
    final double cumulative = stats['cumulative'];
    final int posCount = stats['posCount'];
    final int negCount = stats['negCount'];

    Widget alertWidget;
    if (apr.abs() > 15) {
      alertWidget = Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (apr > 0 ? AppColors.trendRed : AppColors.trendGreen).withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: (apr > 0 ? AppColors.trendRed : AppColors.trendGreen).withOpacity(0.3), width: 0.8),
        ),
        child: Row(
          children: [
            Icon(Icons.gavel_rounded, color: apr > 0 ? AppColors.trendRed : AppColors.trendGreen, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                apr > 0
                    ? 'Extreme leverage bias! Longs pay Shorts ${apr.toStringAsFixed(1)}% APR. High funding cost scenario.'
                    : 'Strong Shorts pay leverage bias! Shorts pay Longs ${apr.abs().toStringAsFixed(1)}% APR.',
                style: GoogleFonts.inter(color: Colors.white, fontSize: res.fontSize(10), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    } else {
      alertWidget = Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceBright.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surfaceBright.withOpacity(0.3), width: 0.8),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.brandAccent, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Balanced market context. $_selectedCoin index funding is stable at ${apr.toStringAsFixed(2)}% APR. Rate counts: $posCount positive / $negCount negative hours.',
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: res.fontSize(10)),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PredictedFundingCard(coin: _selectedCoin),
        alertWidget,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: _statsCard(
                  title: 'AVG HOURLY',
                  value: '${avgPct >= 0 ? '+' : ''}${avgPct.toStringAsFixed(5)}%',
                  subText: 'rate per hour',
                  valueColor: avgPct >= 0 ? AppColors.trendGreen : AppColors.trendRed,
                  res: res,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statsCard(
                  title: 'ANNUAL EST',
                  value: '${apr >= 0 ? '+' : ''}${apr.toStringAsFixed(1)}%',
                  subText: 'apr yield',
                  valueColor: apr >= 0 ? AppColors.trendGreen : AppColors.trendRed,
                  res: res,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statsCard(
                  title: 'CUMULATIVE',
                  value: '${cumulative >= 0 ? '+' : ''}${cumulative.toStringAsFixed(3)}%',
                  subText: 'total cost %',
                  valueColor: cumulative >= 0 ? AppColors.trendGreen : AppColors.trendRed,
                  res: res,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _selectedView == 'Table'
            ? Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildTableWidget(res),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 220,
                  child: _selectedView == 'Candle'
                      ? _buildCandlesChart(res)
                      : _buildLineChart(res),
                ),
              ),
      ],
    );
  }

  Widget _statsCard({required String title, required String value, required String subText, required Color valueColor, required Responsive res}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBright.withOpacity(0.3), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: res.fontSize(8), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: GoogleFonts.jetBrainsMono(color: valueColor, fontSize: res.fontSize(14), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          Text(subText, style: GoogleFonts.inter(color: AppColors.textSecondary.withOpacity(0.5), fontSize: res.fontSize(8))),
        ],
      ),
    );
  }

  Widget _buildLineChart(Responsive res) {
    if (_data.isEmpty) {
      return Center(child: Text('No historical data found.', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary)));
    }

    final spots = _data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.fundingRate * 100);
    }).toList();

    final rates = _data.map((e) => e.fundingRate * 100).toList();
    final double minY = rates.reduce((a, b) => a < b ? a : b) * 1.15;
    final double maxY = rates.reduce((a, b) => a > b ? a : b) * 1.15;
    final double minVal = minY == 0 && maxY == 0 ? -0.05 : minY;
    final double maxVal = minY == 0 && maxY == 0 ? 0.05 : maxY;

    final double viewportW = MediaQuery.of(context).size.width - 32 - 52.0;
    final double chartW = (spots.length * 8.0).clamp(viewportW, 1200.0);

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF060708),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBright.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 220,
            color: const Color(0xFF060708),
            child: CustomPaint(
              painter: _FundingYAxisPainter(
                minVal: minVal,
                maxVal: maxVal,
                gridColor: AppColors.surfaceBright,
                topPad: 12.0,
                bottomPad: 30.0,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              child: SingleChildScrollView(
                controller: _lineScrollController,
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    final scrollOffset = _lineScrollController.hasClients ? _lineScrollController.offset : 0.0;
                    // The line is drawn starting exactly from x = 0 to x = chartW - 12 (due to right padding)
                    final realX = (chartW - scrollOffset - details.localPosition.dx).clamp(0.0, chartW);
                    final double stepW = (chartW - 12.0) / (spots.length - 1 > 0 ? spots.length - 1 : 1);
                    final idx = (realX / stepW).round().clamp(0, spots.length - 1);
                    setState(() {
                      _selectedLineIdx = _selectedLineIdx == idx ? null : idx;
                    });
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: chartW,
                        height: 220,
                        padding: const EdgeInsets.only(right: 12, top: 12, bottom: 8),
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: (maxVal - minVal) / 4 > 0 ? (maxVal - minVal) / 4 : 0.01,
                              getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withOpacity(0.04), strokeWidth: 0.8),
                            ),
                            titlesData: FlTitlesData(
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 22,
                                  interval: spots.length > 1 ? (spots.length / 5).toDouble() : 1.0,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 || index >= _data.length) return const SizedBox.shrink();
                                    final date = DateTime.fromMillisecondsSinceEpoch(_data[index].time);
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        DateFormat(_selectedDays == 1 ? 'HH:mm' : 'MM/dd').format(date),
                                        style: GoogleFonts.inter(color: AppColors.textSecondary.withOpacity(0.6), fontSize: res.fontSize(8)),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: (spots.length - 1).toDouble(),
                            minY: minVal,
                            maxY: maxVal,
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: AppColors.brandAccent,
                                barWidth: 1.5,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [AppColors.brandAccent.withOpacity(0.12), AppColors.brandAccent.withOpacity(0.0)],
                                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                            extraLinesData: ExtraLinesData(
                              horizontalLines: [
                                HorizontalLine(y: 0, color: Colors.white.withOpacity(0.2), strokeWidth: 1, dashArray: [4, 4]),
                              ],
                            ),
                            lineTouchData: const LineTouchData(
                              enabled: false,
                            ),
                          ),
                        ),
                      ),
                      if (_selectedLineIdx != null)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _LineTooltipOverlayPainter(
                                data: _data,
                                selectedIdx: _selectedLineIdx!,
                                chartW: chartW,
                                viewportW: viewportW,
                                scrollOffset: _lineScrollController.hasClients ? _lineScrollController.offset : 0.0,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandlesChart(Responsive res) {
    final candles = _buildFundingCandles(_data, _selectedDays);
    if (candles.isEmpty) {
      return Center(child: Text('No historical values found.', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary)));
    }

    const double chartH = 220.0;
    const double slotW = 28.0;
    final double viewportW = MediaQuery.of(context).size.width - 32 - 52.0;
    final double canvasW = (candles.length * slotW + 56.0).clamp(viewportW, 1200.0);

    final rates = candles.expand((c) => [c.open, c.close, c.high, c.low]).toList()..sort();
    final double minY = rates.isEmpty ? -0.05 : rates.first * 1.15;
    final double maxY = rates.isEmpty ? 0.05 : rates.last * 1.15;
    final double minVal = minY == 0 && maxY == 0 ? -0.05 : minY;
    final double maxVal = minY == 0 && maxY == 0 ? 0.05 : maxY;

    return Container(
      height: chartH,
      decoration: BoxDecoration(
        color: const Color(0xFF060708),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBright.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 220,
            color: const Color(0xFF060708),
            child: CustomPaint(
              painter: _FundingYAxisPainter(
                minVal: minVal,
                maxVal: maxVal,
                gridColor: AppColors.surfaceBright,
                topPad: 12.0,
                bottomPad: 18.0,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              child: SingleChildScrollView(
                controller: _candleScrollController,
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    final scrollOffset = _candleScrollController.hasClients ? _candleScrollController.offset : 0.0;
                    final realX = (canvasW - scrollOffset - details.localPosition.dx).clamp(0.0, canvasW - 1);
                    final idx = (realX / slotW).floor().clamp(0, candles.length - 1);
                    setState(() {
                      _selectedCandleIdx = _selectedCandleIdx == idx ? null : idx;
                    });
                  },
                  child: CustomPaint(
                    size: Size(canvasW, chartH),
                    painter: _FundingCandlePainter(
                      candles: candles,
                      minVal: minVal,
                      maxVal: maxVal,
                      green: AppColors.trendGreen,
                      red: AppColors.trendRed,
                      gridColor: AppColors.surfaceBright,
                      slotW: slotW,
                      leftPad: 0.0,
                      selectedIdx: _selectedCandleIdx,
                      viewportW: viewportW,
                      scrollOffset: _candleScrollController.hasClients ? _candleScrollController.offset : 0.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableWidget(Responsive res) {
    if (_data.isEmpty) {
      return Center(child: Text('No historical records available.', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary)));
    }
    
    final reversed = _data.reversed.toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Text('TIME', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(9), fontWeight: FontWeight.bold)),
              ),
              Expanded(
                flex: 1,
                child: Text('FUNDING RATE', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(9), fontWeight: FontWeight.bold), textAlign: TextAlign.right),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: reversed.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final item = reversed[index];
              final date = DateTime.fromMillisecondsSinceEpoch(item.time);
              final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(date);
              final pctRate = item.fundingRate * 100;
              final isPositive = pctRate >= 0;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF14171C), width: 0.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(dateStr, style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: res.fontSize(10))),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${isPositive ? '+' : ''}${pctRate.toStringAsFixed(5)}%',
                        style: GoogleFonts.jetBrainsMono(
                          color: isPositive ? AppColors.trendGreen : AppColors.trendRed,
                          fontSize: res.fontSize(10),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FundingCandle {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;

  _FundingCandle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });
}

List<_FundingCandle> _buildFundingCandles(List<FundingHistoryEntry> entries, int selectedDays) {
  if (entries.isEmpty) return [];
  final sorted = List<FundingHistoryEntry>.from(entries)
    ..sort((a, b) => a.time.compareTo(b.time));

  Duration interval;
  if (selectedDays == 1) {
    interval = const Duration(hours: 1);
  } else if (selectedDays == 7) {
    interval = const Duration(hours: 6);
  } else {
    interval = const Duration(hours: 24);
  }

  final List<_FundingCandle> candles = [];
  DateTime currentStart = DateTime.fromMillisecondsSinceEpoch(sorted.first.time);
  
  if (selectedDays == 30) {
    currentStart = DateTime(currentStart.year, currentStart.month, currentStart.day);
  } else if (selectedDays == 7) {
    int hour = (currentStart.hour ~/ 6) * 6;
    currentStart = DateTime(currentStart.year, currentStart.month, currentStart.day, hour);
  } else {
    currentStart = DateTime(currentStart.year, currentStart.month, currentStart.day, currentStart.hour);
  }

  List<FundingHistoryEntry> currentGroup = [];

  for (final entry in sorted) {
    final entryTime = DateTime.fromMillisecondsSinceEpoch(entry.time);
    if (entryTime.difference(currentStart) < interval) {
      currentGroup.add(entry);
    } else {
      if (currentGroup.isNotEmpty) {
        candles.add(_createCandleFromGroup(currentStart, currentGroup));
      }
      final diffMs = entryTime.difference(currentStart).inMilliseconds;
      final steps = diffMs ~/ interval.inMilliseconds;
      currentStart = currentStart.add(interval * (steps > 0 ? steps : 1));
      currentGroup = [entry];
    }
  }

  if (currentGroup.isNotEmpty) {
    candles.add(_createCandleFromGroup(currentStart, currentGroup));
  }

  return candles;
}

_FundingCandle _createCandleFromGroup(DateTime time, List<FundingHistoryEntry> group) {
  final rates = group.map((e) => e.fundingRate * 100).toList();
  final open = group.first.fundingRate * 100;
  final close = group.last.fundingRate * 100;
  final high = rates.reduce((a, b) => a > b ? a : b);
  final low = rates.reduce((a, b) => a < b ? a : b);
  return _FundingCandle(
    time: time,
    open: open,
    high: high,
    low: low,
    close: close,
  );
}

class _FundingYAxisPainter extends CustomPainter {
  final double minVal;
  final double maxVal;
  final Color gridColor;
  final double topPad;
  final double bottomPad;

  _FundingYAxisPainter({
    required this.minVal,
    required this.maxVal,
    required this.gridColor,
    required this.topPad,
    required this.bottomPad,
  });

  @override
  void paint(Canvas canvas, Size size) {
    try {
      if (size.height < 5.0 || size.width < 5.0) return;

      final chartH = size.height - topPad - bottomPad;
      final range = (maxVal - minVal).clamp(0.0001, double.infinity);

      const gridLines = 4;
      for (int i = 0; i <= gridLines; i++) {
        final y = topPad + chartH / gridLines * i;
        final value = maxVal - range / gridLines * i;

        final tp = TextPainter(
          text: TextSpan(
            text: '${value >= 0 ? '+' : ''}${value.toStringAsFixed(4)}%',
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 7.5,
              fontFamily: 'JetBrainsMono',
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(size.width - tp.width - 6.0, y - tp.height / 2));
      }
    } catch (e) {
      debugPrint('Error painting fixed YAxis: $e');
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _FundingCandlePainter extends CustomPainter {
  final List<_FundingCandle> candles;
  final double minVal;
  final double maxVal;
  final Color green;
  final Color red;
  final Color gridColor;
  final double slotW;
  final double leftPad;
  final int? selectedIdx;
  final double viewportW;
  final double scrollOffset;

  _FundingCandlePainter({
    required this.candles,
    required this.minVal,
    required this.maxVal,
    required this.green,
    required this.red,
    required this.gridColor,
    required this.slotW,
    required this.leftPad,
    required this.selectedIdx,
    required this.viewportW,
    required this.scrollOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    try {
      if (candles.isEmpty) return;
      if (size.height < 5.0 || size.width < 5.0) return;

      const topPad = 12.0;
      const bottomPad = 18.0;
      final chartW = size.width;
      final chartH = size.height - topPad - bottomPad;
      final range = (maxVal - minVal).clamp(0.0001, double.infinity);

      double toY(double val) => topPad + ((maxVal - val.clamp(minVal, maxVal)) / range * chartH);

      final gridPaint = Paint()
        ..color = gridColor.withOpacity(0.04)
        ..strokeWidth = 0.5;

      const gridLines = 4;
      for (int i = 0; i <= gridLines; i++) {
        final y = topPad + chartH / gridLines * i;
        canvas.drawLine(Offset(leftPad, y), Offset(chartW, y), gridPaint);
      }

      final baselinePaint = Paint()
        ..color = Colors.white.withOpacity(0.12)
        ..strokeWidth = 0.8;
      final yZero = toY(0.0);
      canvas.drawLine(Offset(leftPad, yZero), Offset(chartW, yZero), baselinePaint);

      final xLabelStyle = TextStyle(
        color: Colors.white.withOpacity(0.35),
        fontSize: 7.5,
        fontFamily: 'JetBrainsMono',
      );
      final int step = (candles.length / 5).floor().clamp(1, 15);
      for (int i = 0; i < candles.length; i++) {
        if (i % step == 0 || i == candles.length - 1) {
          final c = candles[i];
          final x = leftPad + i * slotW + slotW / 2;
          final timeStr = DateFormat('MM/dd HH:mm').format(c.time);
          final tp = TextPainter(
            text: TextSpan(text: timeStr, style: xLabelStyle),
            textDirection: ui.TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(x - tp.width / 2, size.height - bottomPad + 4.0));
        }
      }

      for (int i = 0; i < candles.length; i++) {
        final c = candles[i];
        final x = leftPad + i * slotW + slotW / 2;
        final yOpen = toY(c.open);
        final yClose = toY(c.close);
        final yHigh = toY(c.high);
        final yLow = toY(c.low);

        final isUp = c.close >= c.open;
        final color = isUp ? green : red;

        final bodyPaint = Paint()
          ..color = color.withOpacity(0.85)
          ..style = PaintingStyle.fill;
        final linePaint = Paint()
          ..color = color
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

        canvas.drawLine(Offset(x, yHigh), Offset(x, yLow), linePaint);

        final bodyTop = yOpen < yClose ? yOpen : yClose;
        final bodyBottom = yOpen < yClose ? yClose : yOpen;
        final bodyH = (bodyBottom - bodyTop).clamp(1.5, double.infinity);
        final candleW = (slotW * 0.55).clamp(2.0, 14.0);

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x - candleW / 2, bodyTop, candleW, bodyH),
            const Radius.circular(1),
          ),
          bodyPaint,
        );
      }

      // Interactive focus guide & floating tooltip drawn on top of all candles/wicks
      if (selectedIdx != null && selectedIdx! >= 0 && selectedIdx! < candles.length) {
        final c = candles[selectedIdx!];
        final x = leftPad + selectedIdx! * slotW + slotW / 2;

        final selectorPaint = Paint()
          ..color = AppColors.brandAccent.withOpacity(0.5)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

        // Vertical dotted guide line
        double currentY = topPad;
        const dashH = 4.0;
        const spaceH = 4.0;
        while (currentY < topPad + chartH) {
          canvas.drawLine(Offset(x, currentY), Offset(x, currentY + dashH), selectorPaint);
          currentY += dashH + spaceH;
        }

        // Horizontal dotted guide line
        final ySel = toY(c.close);
        double currentX = 0;
        while (currentX < chartW) {
          canvas.drawLine(Offset(currentX, ySel), Offset(currentX + dashH, ySel), selectorPaint);
          currentX += dashH + spaceH;
        }

        // Generate detailed tooltip text block
        final textSpan = TextSpan(
          style: const TextStyle(color: Colors.white, fontSize: 8.0, fontFamily: 'JetBrainsMono'),
          children: [
            TextSpan(text: 'Time: ${DateFormat('MM/dd HH:mm').format(c.time)}\n', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: 'Open:  ${c.open >= 0 ? '+' : ''}${c.open.toStringAsFixed(5)}%\n', style: TextStyle(color: c.open >= 0 ? green : red)),
            TextSpan(text: 'Close: ${c.close >= 0 ? '+' : ''}${c.close.toStringAsFixed(5)}%\n', style: TextStyle(color: c.close >= 0 ? green : red)),
            TextSpan(text: 'High:  ${c.high >= 0 ? '+' : ''}${c.high.toStringAsFixed(5)}%\n'),
            TextSpan(text: 'Low:   ${c.low >= 0 ? '+' : ''}${c.low.toStringAsFixed(5)}%'),
          ],
        );
        final tpTooltip = TextPainter(
          text: textSpan,
          textDirection: ui.TextDirection.ltr,
        )..layout();

        const padW = 8.0;
        const padH = 6.0;
        final boxW = tpTooltip.width + padW * 2;
        final boxH = tpTooltip.height + padH * 2;

        // Calculate center of visible screen content
        final double centerX = (chartW - scrollOffset - viewportW / 2).clamp(0.0, chartW);
        final double centerY = topPad + chartH / 2;

        final double leftLimit = chartW - scrollOffset - viewportW;
        final double rightLimit = chartW - scrollOffset;

        // Center the box horizontally and vertically on screen
        double boxX = centerX - boxW / 2;
        boxX = boxX.clamp(leftLimit + 4.0, rightLimit - boxW - 4.0);

        double boxY = centerY - boxH / 2;
        boxY = boxY.clamp(topPad, topPad + chartH - boxH);

        final bgPaint = Paint()
          ..color = const Color(0xFF0F1115)
          ..style = PaintingStyle.fill;
        final borderPaint = Paint()
          ..color = AppColors.brandAccent.withOpacity(0.45)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke;

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(boxX, boxY, boxW, boxH),
            const Radius.circular(6),
          ),
          bgPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(boxX, boxY, boxW, boxH),
            const Radius.circular(6),
          ),
          borderPaint,
        );

        tpTooltip.paint(canvas, Offset(boxX + padW, boxY + padH));
      }
    } catch (e, st) {
      debugPrint('Error painting funding candles: $e\n$st');
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LineTooltipOverlayPainter extends CustomPainter {
  final List<FundingHistoryEntry> data;
  final int selectedIdx;
  final double chartW;
  final double viewportW;
  final double scrollOffset;

  _LineTooltipOverlayPainter({
    required this.data,
    required this.selectedIdx,
    required this.chartW,
    required this.viewportW,
    required this.scrollOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    try {
      if (data.isEmpty) return;
      if (selectedIdx < 0 || selectedIdx >= data.length) return;

      const topPad = 12.0;
      const bottomPad = 30.0;
      final chartH = size.height - topPad - bottomPad;

      final item = data[selectedIdx];
      // Calculate X coordinate: line start is x=0 to x=chartW-12 (right pad)
      final double stepW = (chartW - 12.0) / (data.length - 1 > 0 ? data.length - 1 : 1);
      final double x = selectedIdx * stepW;

      final selectorPaint = Paint()
        ..color = AppColors.brandAccent.withOpacity(0.5)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      // Vertical dotted guide line
      double currentY = topPad;
      const dashH = 4.0;
      const spaceH = 4.0;
      while (currentY < topPad + chartH) {
        canvas.drawLine(Offset(x, currentY), Offset(x, currentY + dashH), selectorPaint);
        currentY += dashH + spaceH;
      }

      // Generate detailed tooltip text block
      final date = DateTime.fromMillisecondsSinceEpoch(item.time);
      final displayDate = DateFormat('yyyy-MM-dd HH:mm').format(date);
      final rate = item.fundingRate * 100;

      final textSpan = TextSpan(
        style: const TextStyle(color: Colors.white, fontSize: 8.0, fontFamily: 'JetBrainsMono'),
        children: [
          TextSpan(text: '${item.coin}\n', style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(
            text: 'Rate: ${rate >= 0 ? '+' : ''}${rate.toStringAsFixed(5)}%\n',
            style: TextStyle(color: rate >= 0 ? AppColors.trendGreen : AppColors.trendRed),
          ),
          TextSpan(text: 'Time: $displayDate', style: const TextStyle(color: Colors.white70)),
        ],
      );
      final tpTooltip = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      )..layout();

      const padW = 8.0;
      const padH = 6.0;
      final boxW = tpTooltip.width + padW * 2;
      final boxH = tpTooltip.height + padH * 2;

      // Calculate center of visible screen content
      final double centerX = (chartW - scrollOffset - viewportW / 2).clamp(0.0, chartW);
      final double centerY = topPad + chartH / 2;

      final double leftLimit = chartW - scrollOffset - viewportW;
      final double rightLimit = chartW - scrollOffset;

      // Center the box horizontally and vertically on screen
      double boxX = centerX - boxW / 2;
      boxX = boxX.clamp(leftLimit + 4.0, rightLimit - boxW - 4.0);

      double boxY = centerY - boxH / 2;
      boxY = boxY.clamp(topPad, topPad + chartH - boxH);

      final bgPaint = Paint()
        ..color = const Color(0xFF0F1115) // Solid opaque dark background
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = AppColors.brandAccent.withOpacity(0.45)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(boxX, boxY, boxW, boxH),
          const Radius.circular(6),
        ),
        bgPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(boxX, boxY, boxW, boxH),
          const Radius.circular(6),
        ),
        borderPaint,
      );

      tpTooltip.paint(canvas, Offset(boxX + padW, boxY + padH));
    } catch (e, st) {
      debugPrint('Error painting line tooltip: $e\n$st');
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

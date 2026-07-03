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
    _tabController = TabController(length: 2, vsync: this);
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.brandAccent,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: AppColors.brandAccent,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: GoogleFonts.jetBrainsMono(
            fontSize: res.fontSize(12), 
            fontWeight: FontWeight.bold
          ),
          unselectedLabelStyle: GoogleFonts.jetBrainsMono(
            fontSize: res.fontSize(12)
          ),
          dividerColor: AppColors.surfaceBright.withOpacity(0.4),
          tabs: const [
            Tab(text: 'Info'),
            Tab(text: 'Order Book'),
          ],
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

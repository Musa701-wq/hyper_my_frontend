import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/orderbook_model.dart';
import '../models/ticker_model.dart';
import '../services/orderbook_service.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import 'orderbook_panel.dart';
import 'ticker_info_tab.dart';
import '../screens/recent_trades_screen.dart';
import '../analytics/analytics_service.dart';

class TickerDetailDialog extends StatefulWidget {
  final TickerModel ticker;

  const TickerDetailDialog({super.key, required this.ticker});

  @override
  State<TickerDetailDialog> createState() => _TickerDetailDialogState();
}

class _TickerDetailDialogState extends State<TickerDetailDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  OrderBookService? _orderBookService;
  OrderBookSnapshot? _orderBook;
  bool _orderBookLoading = false;
  String? _orderBookError;
  bool _orderBookStarted = false;

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
    _orderBookService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: res.spacing(16), 
        vertical: res.spacing(24)
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: res.value(mobile: res.width * 0.95, tablet: 650.0, desktop: 800.0), 
          maxHeight: (res.isMobile ? 600.0 : (res.isTablet ? 650.0 : 800.0))
              .clamp(0.0, res.height * 0.9)
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF161A22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBright.withValues(alpha: 0.6)),
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(ticker: widget.ticker),
            TabBar(
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
              dividerColor: AppColors.surfaceBright.withValues(alpha: 0.4),
              tabs: const [
                Tab(text: 'Info'),
                Tab(text: 'Order Book'),
              ],
            ),

            const SizedBox(height: 12), // Added margin to prevent content from touching tabs
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(child: TickerInfoTab(ticker: widget.ticker)),
                  OrderBookPanel(
                    snapshot: _orderBook,
                    isLoading: _orderBookLoading,
                    errorMessage: _orderBookError,
                    sizeLabel: _sizeLabel,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  final TickerModel ticker;

  const _DialogHeader({required this.ticker});

  String get _subtitle {
    final name = ticker.displayName.isNotEmpty ? ticker.displayName : ticker.symbol;
    final afterColon = name.contains(':') ? name.split(':').last : name;
    return afterColon.split('-').first;
  }

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);
    final title = ticker.displayName.isNotEmpty ? ticker.displayName : ticker.symbol;
    final typeLabel = ticker.marketType.toUpperCase();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        res.spacing(16), 
        res.spacing(16), 
        res.spacing(10), 
        res.spacing(8)
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _TickerIcon(ticker: ticker, size: res.fontSize(40)),
          SizedBox(width: res.spacing(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ticker.displaySymbol,
                          style: GoogleFonts.jetBrainsMono(
                            color: AppColors.textPrimary,
                            fontSize: res.fontSize(15),
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        _buildMarketBadges(ticker, res),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      AnalyticsService.logRecentTradesAccess(ticker.symbol);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecentTradesScreen(
                            symbol: ticker.symbol,
                            dex: ticker.dex,
                            iconUrl: ticker.iconUrl,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: res.spacing(8),
                        vertical: res.spacing(4),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.brandAccent.withValues(alpha: 0.5)),
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
                            'TRADES',
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
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  Text(_subtitle,
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.textSecondary, 
                        fontSize: res.fontSize(12)
                      )),
                  if (ticker.isDelisted) ...[
                    SizedBox(width: res.spacing(6)),
                    _BadgeChip(label: 'DELISTED', color: AppColors.trendRed, res: res),
                  ],
                ]),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: AppColors.textSecondary, size: res.fontSize(20)),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(
              minWidth: res.spacing(32), 
              minHeight: res.spacing(32)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketBadges(TickerModel ticker, Responsive res) {
    // 0. Special case for HIP-3 (Revert to original style)
    if (ticker.marketType == 'hip-3') {
      return Text(
        'HYPERLIQUID • HIP-3',
        style: GoogleFonts.jetBrainsMono(
          color: AppColors.textSecondary.withValues(alpha: 0.6),
          fontSize: res.fontSize(9),
        ),
      );
    }

    String? categoryLabel;

    if (ticker.dex.isNotEmpty && ticker.dex.toLowerCase() != 'hyperliquid') {
      categoryLabel = ticker.dex.toUpperCase();
    } else if (ticker.cryptoCategory.isNotEmpty) {
      final standardCategories = ['layer1', 'layer2', 'defi', 'ai', 'gaming', 'meme'];
      if (!standardCategories.contains(ticker.cryptoCategory.toLowerCase().trim())) {
        categoryLabel = ticker.cryptoCategory.toUpperCase();
      }
    }




    final List<Widget> badges = [];

    
    // 1. Check for SPOT
    if (ticker.marketType == 'spot') {
      badges.add(
        _Badge(
          label: 'SPOT',
          res: res,
          bgColor: const Color(0xFF0D2D2A),
          textColor: const Color(0xFF5EEAD4),
        ),
      );
    }

    // 2. Category badge (if identified above)
    if (categoryLabel != null) {
      if (badges.isNotEmpty) badges.add(const SizedBox(width: 4));
      badges.add(
        _Badge(
          label: categoryLabel,
          res: res,
          bgColor: const Color(0xFF0D2D2A),
          textColor: const Color(0xFF5EEAD4),
        ),
      );
    }



    // 3. Leverage Badge (for everything except SPOT, if > 0)
    if (ticker.marketType != 'spot' && ticker.maxLeverage > 0) {
      if (badges.isNotEmpty) badges.add(const SizedBox(width: 4));
      badges.add(
        _Badge(
          label: '${ticker.maxLeverage}x',
          res: res,
          bgColor: const Color(0xFF0D2D2A),
          textColor: const Color(0xFF5EEAD4),
        ),
      );
    }






    if (badges.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: badges,
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Responsive res;
  final Color bgColor;
  final Color textColor;

  const _Badge({
    required this.label,
    required this.res,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          color: textColor,
          fontSize: res.fontSize(9),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}


class _TickerIcon extends StatelessWidget {
  final TickerModel ticker;
  final double size;

  const _TickerIcon({required this.ticker, required this.size});

  @override
  Widget build(BuildContext context) {
    if (ticker.iconUrl.isEmpty) return _placeholder(size);
    final isSvg = ticker.iconUrl.toLowerCase().contains('.svg');
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: AppColors.surfaceBright, shape: BoxShape.circle),
      child: ClipOval(
        child: isSvg
            ? SvgPicture.network(
                ticker.iconUrl,
                fit: BoxFit.cover,
                placeholderBuilder: (_) => _placeholder(size),
                errorBuilder: (context, error, stackTrace) => _placeholder(size),
              )
            : Image.network(
                ticker.iconUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _placeholder(size),
              ),
      ),
    );
  }

  Widget _placeholder(double size) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: AppColors.surfaceBright, shape: BoxShape.circle),
        child: Icon(Icons.image_outlined, size: size * 0.5, color: AppColors.textSecondary),
      );
}

class _BadgeChip extends StatelessWidget {
  final String label;
  final Color color;
  final Responsive res;

  const _BadgeChip({required this.label, required this.color, required this.res});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: res.spacing(5), 
        vertical: res.spacing(2)
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          color: color, 
          fontSize: res.fontSize(8), 
          letterSpacing: 0.5
        ),
      ),
    );
  }
}


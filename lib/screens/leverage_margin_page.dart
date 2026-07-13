import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/ticker_model.dart';
import '../services/margin_service.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import '../utils/common_widgets.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/error_state_widget.dart';

class LeverageMarginPage extends StatefulWidget {
  const LeverageMarginPage({super.key});

  @override
  State<LeverageMarginPage> createState() => _LeverageMarginPageState();
}

class _LeverageMarginPageState extends State<LeverageMarginPage> {
  final _service = MarginService();
  List<TickerModel> _allTickers = [];
  List<TickerModel> _filteredTickers = [];
  bool _loading = true;
  String? _error;
  Timer? _refreshTimer;

  // Search & Sort State
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'symbol'; // 'symbol', 'leverage_desc', 'leverage_asc', 'table_id'

  @override
  void initState() {
    super.initState();
    _load();
    // 10s auto-refresh
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _load(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && _allTickers.isEmpty) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final markets = await _service.getPerpMarkets();
      
      // Filter out spot if any
      final perpsOnly = markets.where((m) => m.marketType == 'perp').toList();

      if (mounted) {
        setState(() {
          _allTickers = perpsOnly;
          _applyFilterAndSort();
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted && _allTickers.isEmpty) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _applyFilterAndSort() {
    var list = [..._allTickers];

    // Filter
    if (_searchQuery.isNotEmpty) {
      list = list.where((m) => m.symbol.toUpperCase().contains(_searchQuery.toUpperCase())).toList();
    }

    // Sort
    if (_sortBy == 'symbol') {
      list.sort((a, b) => a.symbol.compareTo(b.symbol));
    } else if (_sortBy == 'leverage_desc') {
      list.sort((a, b) => b.maxLeverage.compareTo(a.maxLeverage));
    } else if (_sortBy == 'leverage_asc') {
      list.sort((a, b) => a.maxLeverage.compareTo(b.maxLeverage));
    } else if (_sortBy == 'table_id') {
      list.sort((a, b) {
        final aid = a.marginTableId ?? 0;
        final bid = b.marginTableId ?? 0;
        return aid.compareTo(bid);
      });
    }

    _filteredTickers = list;
  }

  double _calculateMmRate(int maxLeverage) {
    if (maxLeverage <= 0) return 0.0;
    return 100.0 / (2 * maxLeverage);
  }

  String _formatPrice(double price) {
    if (price >= 1000) return '\$${price.toStringAsFixed(1)}';
    if (price >= 1) return '\$${price.toStringAsFixed(3)}';
    return '\$${price.toStringAsFixed(6)}';
  }

  void _showDetailDialog(TickerModel ticker) {
    final res = Responsive(context);
    final isWide = res.width > 600;
    final mmRate = _calculateMmRate(ticker.maxLeverage);
    final imRate = ticker.maxLeverage > 0 ? (100.0 / ticker.maxLeverage) : 0.0;

    // Generate Standard Tiers
    final List<Map<String, dynamic>> tiers = [];
    if (ticker.maxLeverage >= 50) {
      tiers.addAll([
        {'range': '\$0 - \$50K', 'mm': '${mmRate.toStringAsFixed(2)}%', 'lev': '${ticker.maxLeverage}x'},
        {'range': '\$50K - \$100K', 'mm': '${(mmRate * 1.25).toStringAsFixed(2)}%', 'lev': '${(ticker.maxLeverage * 0.8).toInt()}x'},
        {'range': '\$100K - \$250K', 'mm': '${(mmRate * 2.5).toStringAsFixed(2)}%', 'lev': '20x'},
        {'range': '\$250K - \$500K', 'mm': '5.00%', 'lev': '10x'},
        {'range': '>\$500K', 'mm': '10.00%', 'lev': '5x'},
      ]);
    } else if (ticker.maxLeverage >= 20) {
      tiers.addAll([
        {'range': '\$0 - \$20K', 'mm': '${mmRate.toStringAsFixed(2)}%', 'lev': '${ticker.maxLeverage}x'},
        {'range': '\$20K - \$50K', 'mm': '5.00%', 'lev': '10x'},
        {'range': '>\$50K', 'mm': '10.00%', 'lev': '5x'},
      ]);
    } else {
      tiers.addAll([
        {'range': '\$0 - \$10K', 'mm': '${mmRate.toStringAsFixed(2)}%', 'lev': '${ticker.maxLeverage}x'},
        {'range': '>\$10K', 'mm': '10.00%', 'lev': '5x'},
      ]);
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.surfaceBright.withOpacity(0.4), width: 0.8),
          ),
          child: Container(
            width: isWide ? 420 : double.infinity,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    if (ticker.iconUrl.isNotEmpty)
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: ticker.iconUrl.toLowerCase().contains('.svg')
                            ? SvgPicture.network(
                                ticker.iconUrl,
                                fit: BoxFit.cover,
                                placeholderBuilder: (context) => const Icon(Icons.token, size: 32, color: AppColors.textSecondary),
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.token, size: 32, color: AppColors.textSecondary),
                              )
                            : Image.network(
                                ticker.iconUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.token, size: 32, color: AppColors.textSecondary),
                              ),
                      )
                    else
                      const Icon(Icons.token, color: AppColors.textSecondary, size: 32),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ticker.symbol}-PERP',
                          style: GoogleFonts.jetBrainsMono(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Mark: ${_formatPrice(ticker.markPx)}',
                          style: GoogleFonts.jetBrainsMono(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white38),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white10),
                const SizedBox(height: 10),

                // Core Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDialogStat('Max Leverage', '${ticker.maxLeverage}x'),
                    _buildDialogStat('Margin Table', 'Table ${ticker.marginTableId ?? "—"}'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDialogStat('Initial Margin', '${imRate.toStringAsFixed(2)}%'),
                    _buildDialogStat('Maint. Margin (Base)', '${mmRate.toStringAsFixed(2)}%'),
                  ],
                ),
                const SizedBox(height: 20),

                // Tiers Title
                Text(
                  'Size-Based Margin Tiers',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Tiers Table
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.surfaceBright.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      // Header Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        color: AppColors.surfaceBright.withOpacity(0.3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Position Value (USD)',
                                style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: Text(
                                'Maint. Margin',
                                textAlign: TextAlign.right,
                                style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: Text(
                                'Max Lev',
                                textAlign: TextAlign.right,
                                style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Tiers rows
                      ...tiers.map((tier) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: AppColors.surfaceBright.withOpacity(0.3))),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  tier['range'],
                                  style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: 10),
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  tier['mm'],
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.jetBrainsMono(color: AppColors.brandAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              SizedBox(
                                width: 60,
                                child: Text(
                                  tier['lev'],
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Disclaimer
                Text(
                  '* Note: Standard Hyperliquid margin rules apply. Account limits may be reduced in high volatility or growth mode. Maintenance margin is calculated as 1 / (2 * active_leverage).',
                  style: GoogleFonts.inter(
                    color: Colors.white24,
                    fontSize: 8.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getFriendlyErrorMessage(String error) {
    if (error.contains('SocketException') ||
        error.contains('Failed host lookup') ||
        error.contains('HttpException') ||
        error.contains('Connection refused') ||
        error.contains('errno = 61')) {
      return 'Connection error. Please check your internet connection or backend server status and try again.';
    }
    return 'Failed to load markets. Please try again later.';
  }

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.brandAccent, size: res.fontSize(20)),
          ),
          title: Text(
            'LEVERAGE & MARGIN',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.brandAccent,
              fontSize: res.fontSize(16),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
      body: Column(
        children: [
          // Filter Search & Sorting Control Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Search Input
                Expanded(
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.surfaceBright.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(Icons.search, size: 16, color: Colors.white38),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 12),
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val.trim();
                                _applyFilterAndSort();
                              });
                            },
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'SEARCH COIN: e.g. BTC',
                              hintStyle: GoogleFonts.jetBrainsMono(color: Colors.white24, fontSize: 11),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close, size: 14, color: Colors.white38),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _applyFilterAndSort();
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Sort Dropdown Button
                PopupMenuButton<String>(
                  offset: const Offset(0, 36),
                  elevation: 12,
                  shadowColor: Colors.black54,
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.surfaceBright.withOpacity(0.4)),
                  ),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _sortBy != 'symbol' ? AppColors.brandAccent.withOpacity(0.12) : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _sortBy != 'symbol' ? AppColors.brandAccent.withOpacity(0.4) : AppColors.surfaceBright.withOpacity(0.3),
                        width: _sortBy != 'symbol' ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sort_rounded,
                          size: 14,
                          color: _sortBy != 'symbol' ? AppColors.brandAccent : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _sortBy == 'symbol'
                              ? 'SORT'
                              : _sortBy == 'leverage_desc'
                                  ? 'LEV HIGH'
                                  : _sortBy == 'leverage_asc'
                                      ? 'LEV LOW'
                                      : 'TABLE',
                          style: GoogleFonts.jetBrainsMono(
                            color: _sortBy != 'symbol' ? AppColors.brandAccent : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.unfold_more_rounded, color: Colors.white54, size: 14),
                      ],
                    ),
                  ),
                  onSelected: (val) {
                    setState(() {
                      _sortBy = val;
                      _applyFilterAndSort();
                    });
                  },
                  itemBuilder: (context) => [
                    _buildPopupItem('symbol', 'Sort by Name (A-Z)'),
                    _buildPopupItem('leverage_desc', 'Sort by Leverage (High-Low)'),
                    _buildPopupItem('leverage_asc', 'Sort by Leverage (Low-High)'),
                    _buildPopupItem('table_id', 'Sort by Margin Table'),
                  ],
                ),
                const SizedBox(width: 8),

                // Refresh Button
                GestureDetector(
                  onTap: () => _load(),
                  child: Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.surfaceBright.withOpacity(0.3)),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.refresh, size: 16, color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),

          // Headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'ASSET',
                    style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(11), fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'MARK PRICE',
                      style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(11), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'MAX LEV',
                      style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(11), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'BASE MM',
                      style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(11), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main body list
          Expanded(child: _buildBody(res)),
        ],
      ),
    ),
  );
  }

  Widget _buildBody(Responsive res) {
    if (_loading && _allTickers.isEmpty) {
      return _buildShimmerLoading(res);
    }
    if (_error != null && _allTickers.isEmpty) {
      return ErrorStateWidget(
        errorMessage: _getFriendlyErrorMessage(_error!),
        onRetry: () => _load(),
      );
    }

    if (_filteredTickers.isEmpty) {
      return Center(
        child: Text(
          'No perpetual markets found.',
          style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 12),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _filteredTickers.length,
      itemBuilder: (context, i) => _buildTickerRow(_filteredTickers[i], i + 1, res),
    );
  }

  Widget _buildShimmerLoading(Responsive res) {
    return ShimmerSkeleton(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: 8,
        itemBuilder: (context, i) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      ShimmerSkeleton.box(8, 10, radius: 2),
                      const SizedBox(width: 8),
                      ShimmerSkeleton.box(res.fontSize(28), res.fontSize(28), radius: res.fontSize(28) / 2),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ShimmerSkeleton.box(40, 10, radius: 3),
                            const SizedBox(height: 6),
                            ShimmerSkeleton.box(25, 8, radius: 2),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ShimmerSkeleton.box(50, 10, radius: 3),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ShimmerSkeleton.box(30, 10, radius: 3),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ShimmerSkeleton.box(40, 10, radius: 3),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTickerRow(TickerModel ticker, int rank, Responsive res) {
    final mmRate = _calculateMmRate(ticker.maxLeverage);
    final displaySymbol = ticker.symbol.toUpperCase();

    return GestureDetector(
      onTap: () => _showDetailDialog(ticker),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
        ),
        child: Row(
          children: [
            // Asset Info
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Text(
                      rank.toString(),
                      style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(9)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: res.fontSize(28),
                    height: res.fontSize(28),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceBright.withOpacity(0.3),
                    ),
                    child: ClipOval(
                      child: ticker.iconUrl.isEmpty
                          ? Icon(Icons.token, color: AppColors.textSecondary, size: res.fontSize(16))
                          : ticker.iconUrl.toLowerCase().contains('.svg')
                              ? SvgPicture.network(
                                  ticker.iconUrl,
                                  fit: BoxFit.cover,
                                  placeholderBuilder: (context) => Icon(Icons.token, size: res.fontSize(16), color: AppColors.textSecondary),
                                  errorBuilder: (context, error, stackTrace) => Icon(Icons.token, size: res.fontSize(16), color: AppColors.textSecondary),
                                )
                              : Image.network(
                                  ticker.iconUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Icon(Icons.token, size: res.fontSize(16), color: AppColors.textSecondary),
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(child: CircularProgressIndicator(strokeWidth: 1, valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandAccent.withOpacity(0.3))));
                                  },
                                ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displaySymbol,
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white,
                          fontSize: res.fontSize(11),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Table ${ticker.marginTableId ?? "—"}',
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.textSecondary,
                          fontSize: res.fontSize(9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Mark Price
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _formatPrice(ticker.markPx),
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white,
                    fontSize: res.fontSize(11),
                  ),
                ),
              ),
            ),

            // Max Leverage Badge
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.brandAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.brandAccent.withOpacity(0.2), width: 0.5),
                  ),
                  child: Text(
                    '${ticker.maxLeverage}x',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.brandAccent,
                      fontSize: res.fontSize(11),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // Base MM Rate
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${mmRate.toStringAsFixed(2)}%',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white70,
                    fontSize: res.fontSize(11),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, String label) {
    final active = _sortBy == value;
    return PopupMenuItem<String>(
      value: value,
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.brandAccent.withOpacity(0.08) : Colors.transparent,
        ),
        child: Row(
          children: [
            if (active)
              const Icon(Icons.check_circle_rounded, color: AppColors.brandAccent, size: 14)
            else
              const Icon(Icons.circle_outlined, color: Colors.white24, size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.jetBrainsMono(
                  color: active ? AppColors.brandAccent : Colors.white70,
                  fontSize: 11,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/borrow_lend_model.dart';
import '../viewmodels/borrow_lend_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import '../utils/common_widgets.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/error_state_widget.dart';

class BorrowLendPage extends StatefulWidget {
  const BorrowLendPage({super.key});

  @override
  State<BorrowLendPage> createState() => _BorrowLendPageState();
}

class _BorrowLendPageState extends State<BorrowLendPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<BorrowLendViewModel>();
      vm.fetchPools();
      vm.startAutoRefresh();
    });
  }

  @override
  void dispose() {
    // Stop auto refresh when leaving screen
    try {
      context.read<BorrowLendViewModel>().stopAutoRefresh();
    } catch (_) {}
    _searchController.dispose();
    super.dispose();
  }

  String _formatUsd(double value) {
    if (value >= 1e9) {
      return '\$${(value / 1e9).toStringAsFixed(2)}B';
    } else if (value >= 1e6) {
      return '\$${(value / 1e6).toStringAsFixed(2)}M';
    } else if (value >= 1e3) {
      return '\$${(value / 1e3).toStringAsFixed(1)}K';
    } else {
      return '\$${value.toStringAsFixed(2)}';
    }
  }

  String _formatPercent(double value) {
    return '${(value * 100).toStringAsFixed(2)}%';
  }

  String _formatTokenShort(double value) {
    if (value >= 1e9) {
      return '${(value / 1e9).toStringAsFixed(2)}B';
    } else if (value >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(2)}M';
    } else if (value >= 1e3) {
      return '${(value / 1e3).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(2);
    }
  }

  String _formatPrice(double value) {
    if (value == 0) return '\$0.00';
    if (value < 1.0) {
      return '\$${value.toStringAsFixed(4)}';
    }
    final parts = value.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedInteger = integerPart.replaceAllMapped(reg, (Match m) => '${m[1]},');
    return '\$$formattedInteger.$decimalPart';
  }

  String _findIconUrl(String tokenName) {
    try {
      final tickers = context.read<HomeViewModel>().allTickers;
      for (final t in tickers) {
        if (t.symbol.toUpperCase() == tokenName.toUpperCase() ||
            t.displayName.toUpperCase().contains(tokenName.toUpperCase())) {
          return t.iconUrl;
        }
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  void _showDetailDialog(BorrowLendModel pool) {
    final res = Responsive(context);
    final isWide = res.width > 600;
    final iconUrl = _findIconUrl(pool.tokenName);

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
                    if (iconUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          iconUrl,
                          width: 32,
                          height: 32,
                          errorBuilder: (ctx, err, stack) => const Icon(Icons.token, color: AppColors.textSecondary, size: 32),
                        ),
                      )
                    else
                      const Icon(Icons.token, color: AppColors.textSecondary, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${pool.tokenName} Pool Details',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.jetBrainsMono(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Oracle Price: ${_formatPrice(pool.oraclePx)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.jetBrainsMono(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white38),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white10),
                const SizedBox(height: 10),

                // Core Stats Grid
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(4),
                    1: FlexColumnWidth(6),
                  },
                  children: [
                    _buildRow('Supply APR', _formatPercent(pool.supplyYearlyRate), valueColor: AppColors.trendGreen, isBoldValue: true),
                    _buildRow('Borrow APR', _formatPercent(pool.borrowYearlyRate), valueColor: AppColors.trendRed, isBoldValue: true),
                    _buildRow('Pool Utilization', pool.utilization.toStringAsFixed(4), valueColor: AppColors.brandAccent),
                    _buildRow('Total Supplied', '${pool.totalSupplied.toStringAsFixed(2)} ${pool.tokenName} (${_formatUsd(pool.totalSupplied * pool.oraclePx)})'),
                    _buildRow('Total Borrowed', '${pool.totalBorrowed.toStringAsFixed(2)} ${pool.tokenName} (${_formatUsd(pool.totalBorrowed * pool.oraclePx)})'),
                    _buildRow('Available Balance', '${pool.balance.toStringAsFixed(2)} ${pool.tokenName} (${_formatUsd(pool.balance * pool.oraclePx)})'),
                    _buildRow(
                      'Max LTV',
                      pool.ltv != null ? '${(pool.ltv! * 100).toStringAsFixed(0)}%' : 'N/A',
                      valueColor: pool.ltv != null && pool.ltv! > 0 ? AppColors.brandAccent : Colors.white60,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Disclaimer
                Text(
                  '* Values fluctuate dynamically based on Hyperliquid pool supply/borrow utilization. Interest models adjust rates automatically according to deposit availability.',
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

  TableRow _buildRow(String label, String value, {Color valueColor = Colors.white70, bool isBoldValue = false}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Text(
            label,
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.jetBrainsMono(
              color: valueColor,
              fontSize: 11,
              fontWeight: isBoldValue ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
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
            '🏛️ BORROW & LEND POOLS',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.brandAccent,
              fontSize: res.fontSize(16),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        body: Consumer<BorrowLendViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading && viewModel.pools.isEmpty) {
              return _buildShimmerLoading(res);
            }

            if (viewModel.error.isNotEmpty && viewModel.pools.isEmpty) {
              return ErrorStateWidget(
                errorMessage: viewModel.error,
                onRetry: () => viewModel.fetchPools(),
              );
            }

            // Filter pools based on query
            final list = viewModel.pools.where((p) {
              if (_searchQuery.isEmpty) return true;
              return p.tokenName.toUpperCase().contains(_searchQuery.toUpperCase());
            }).toList();

            // Computations for top indicators
            double totalSuppliedUsd = 0.0;
            double sumUtilization = 0.0;
            double topYieldRate = 0.0;
            String topYieldToken = 'N/A';

            for (var p in viewModel.pools) {
              totalSuppliedUsd += p.totalSupplied * p.oraclePx;
              sumUtilization += p.utilization;
              if (p.supplyYearlyRate > topYieldRate) {
                topYieldRate = p.supplyYearlyRate;
                topYieldToken = p.tokenName;
              }
            }

            final avgUtil = viewModel.pools.isNotEmpty ? (sumUtilization / viewModel.pools.length) : 0.0;

            return Column(
              children: [
                // Overview stats cards
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'TOTAL DEPOSITS',
                          _formatUsd(totalSuppliedUsd),
                          'supplied in pools',
                          AppColors.trendGreen,
                          res,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryCard(
                          'AVG UTILIZATION',
                          '${(avgUtil * 100).toStringAsFixed(1)}%',
                          'active borrowed',
                          AppColors.brandAccent,
                          res,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryCard(
                          'BEST YIELD',
                          '${(topYieldRate * 100).toStringAsFixed(1)}%',
                          'pool: $topYieldToken',
                          AppColors.trendGreen,
                          res,
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar & controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
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
                                    });
                                  },
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: 'SEARCH POOLS: USDC, HYPE...',
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
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => viewModel.fetchPools(),
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

                // Sticky Left Column & Scrollable Right Column Table Layout
                Expanded(
                  child: list.isEmpty
                      ? Center(
                          child: Text(
                            'No pools match your search.',
                            style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Static left side (POOL)
                              SizedBox(
                                width: res.columnWidth(110),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // POOL Header
                                    Container(
                                      height: 40,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'POOL',
                                        style: GoogleFonts.jetBrainsMono(
                                          color: AppColors.textSecondary,
                                          fontSize: res.fontSize(9),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // POOL Data Rows
                                    ...list.map((pool) {
                                      return GestureDetector(
                                        onTap: () => _showDetailDialog(pool),
                                        behavior: HitTestBehavior.opaque,
                                        child: Container(
                                          height: res.value(mobile: 52.0, tablet: 60.0),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                          decoration: const BoxDecoration(
                                            border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
                                          ),
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            pool.tokenName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.jetBrainsMono(
                                              color: Colors.white,
                                              fontSize: res.fontSize(10.5),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              // 2. Scrollable right side
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width: res.columnWidth(375) + 8,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header Row for Scrollable Part
                                        Container(
                                          height: 40,
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: res.columnWidth(85),
                                                child: Center(
                                                  child: Text(
                                                    'PRICE',
                                                    style: GoogleFonts.jetBrainsMono(
                                                      color: AppColors.textSecondary,
                                                      fontSize: res.fontSize(9),
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: res.columnWidth(100),
                                                child: Center(
                                                  child: Text(
                                                    'AVAILABLE (QTY)',
                                                    style: GoogleFonts.jetBrainsMono(
                                                      color: AppColors.textSecondary,
                                                      fontSize: res.fontSize(8.5),
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: res.columnWidth(65),
                                                child: Center(
                                                  child: Text(
                                                    'SUPPLY',
                                                    style: GoogleFonts.jetBrainsMono(
                                                      color: AppColors.textSecondary,
                                                      fontSize: res.fontSize(9),
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: res.columnWidth(65),
                                                child: Center(
                                                  child: Text(
                                                    'BORROW',
                                                    style: GoogleFonts.jetBrainsMono(
                                                      color: AppColors.textSecondary,
                                                      fontSize: res.fontSize(9),
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: res.columnWidth(60),
                                                child: Center(
                                                  child: Text(
                                                    'UTIL',
                                                    style: GoogleFonts.jetBrainsMono(
                                                      color: AppColors.textSecondary,
                                                      fontSize: res.fontSize(9),
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        // Scrollable Data Rows
                                        ...list.map((pool) {
                                          return GestureDetector(
                                            onTap: () => _showDetailDialog(pool),
                                            behavior: HitTestBehavior.opaque,
                                            child: Container(
                                              height: res.value(mobile: 52.0, tablet: 60.0),
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                                              decoration: const BoxDecoration(
                                                border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
                                              ),
                                              child: Row(
                                                children: [
                                                  SizedBox(
                                                    width: res.columnWidth(85),
                                                    child: Center(
                                                      child: Text(
                                                        _formatPrice(pool.oraclePx),
                                                        maxLines: 1,
                                                        style: GoogleFonts.jetBrainsMono(
                                                          color: Colors.white70,
                                                          fontSize: res.fontSize(10.5),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: res.columnWidth(100),
                                                    child: Center(
                                                      child: Text(
                                                        _formatTokenShort(pool.balance),
                                                        maxLines: 1,
                                                        style: GoogleFonts.jetBrainsMono(
                                                          color: Colors.white,
                                                          fontSize: res.fontSize(10.5),
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: res.columnWidth(65),
                                                    child: Center(
                                                      child: Text(
                                                        _formatPercent(pool.supplyYearlyRate),
                                                        maxLines: 1,
                                                        style: GoogleFonts.jetBrainsMono(
                                                          color: AppColors.trendGreen,
                                                          fontSize: res.fontSize(10.5),
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: res.columnWidth(65),
                                                    child: Center(
                                                      child: Text(
                                                        _formatPercent(pool.borrowYearlyRate),
                                                        maxLines: 1,
                                                        style: GoogleFonts.jetBrainsMono(
                                                          color: AppColors.trendRed,
                                                          fontSize: res.fontSize(10.5),
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: res.columnWidth(60),
                                                    child: Center(
                                                      child: Text(
                                                        pool.utilization.toStringAsFixed(4),
                                                        maxLines: 1,
                                                        style: GoogleFonts.jetBrainsMono(
                                                          color: Colors.white70,
                                                          fontSize: res.fontSize(10.5),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, String subtitle, Color valueColor, Responsive res) {
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
          Text(subtitle, style: GoogleFonts.inter(color: AppColors.textSecondary.withOpacity(0.5), fontSize: res.fontSize(8))),
        ],
      ),
    );
  }
  Widget _buildShimmerLoading(Responsive res) {
    return ShimmerSkeleton(
      child: Column(
        children: [
          // Overview stats cards shimmer
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(child: ShimmerSkeleton.box(double.infinity, 80, radius: 12)),
                const SizedBox(width: 8),
                Expanded(child: ShimmerSkeleton.box(double.infinity, 80, radius: 12)),
                const SizedBox(width: 8),
                Expanded(child: ShimmerSkeleton.box(double.infinity, 80, radius: 12)),
              ],
            ),
          ),
          // Search & refresh shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Expanded(child: ShimmerSkeleton.box(double.infinity, 38, radius: 10)),
                const SizedBox(width: 8),
                ShimmerSkeleton.box(38, 38, radius: 10),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Table layout skeleton rows
          Expanded(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              itemBuilder: (context, i) {
                return Container(
                  height: res.value(mobile: 52.0, tablet: 60.0),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      ShimmerSkeleton.box(60, 12, radius: 3),
                      const Spacer(),
                      ShimmerSkeleton.box(50, 12, radius: 3),
                      const SizedBox(width: 24),
                      ShimmerSkeleton.box(40, 12, radius: 3),
                      const SizedBox(width: 24),
                      ShimmerSkeleton.box(40, 12, radius: 3),
                      const SizedBox(width: 8),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


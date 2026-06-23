import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../viewmodels/portfolio_viewmodel.dart';
import '../models/leaderboard_model.dart';
import '../utils/app_colors.dart';
import '../viewmodels/wallet_viewmodel.dart';

import '../utils/responsive.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/shimmer_skeleton.dart';

class ProfileScreen extends StatefulWidget {
  final String walletAddress;

  const ProfileScreen({
    super.key,
    required this.walletAddress,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _hideValue = false;
  int _selectedChartTabIndex = 2; // only Acct Value (0/1 Combined/Perp commented out)
  int _selectedOhlcChartType = 0; // 0: candlestick, 1: bar, 2: area
  int _selectedDetailedTabIndex = 0;
  int _positionsPage = 1;
  int _recentPage = 1;
  int _fillsPage = 1;
  int _ordersPage = 1;
  int _spotPage = 1;
  OhlcSnapshot? _selectedCandle;
  final TransformationController _chartTransformCtrl = TransformationController();
  static const int _positionsPerPage = 5;
  static const int _recentPerPage = 10;
  static const int _fillsPerPage = 10;
  static const int _ordersPerPage = 10;
  static const int _spotPerPage = 10;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PortfolioViewModel>().initializePortfolio(widget.walletAddress);
    });
  }

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);
    
    return Consumer<PortfolioViewModel>(
      builder: (context, vm, _) {
        final wallet = widget.walletAddress;
        final walletVm = context.read<WalletViewModel>();
        final bool isMe = walletVm.isConnected && walletVm.address?.toLowerCase() == wallet.toLowerCase();
        
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            leading: (vm.hasData && !isMe) 
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null,
            centerTitle: false,
            titleSpacing: (vm.hasData && !isMe) ? 0 : 16,
            title: vm.hasData 
              ? Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.purpleAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          wallet.length > 2 ? wallet[2].toUpperCase() : 'W',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isMe ? 'Welcome back,' : 'Trader Profile,',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '0x${wallet.substring(2, 6)}...${wallet.substring(wallet.length - 4)}',
                          style: GoogleFonts.jetBrainsMono(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : const SizedBox.shrink(),
            actions: [
              _headerIconButton(
                _hideValue ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                onTap: () => setState(() => _hideValue = !_hideValue),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: (vm.isLoading || !vm.hasData) && vm.error == null
              ? _buildPortfolioShimmer(res)
              : vm.error != null && !vm.hasData
                  ? ErrorStateWidget(
                      errorMessage: vm.error!,
                      onRetry: () => vm.fetchPortfolio(widget.walletAddress, force: true),
                    )
                  : RefreshIndicator(
                          color: AppColors.brandAccent,
                          onRefresh: () => vm.fetchPortfolio(widget.walletAddress, force: true),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                              horizontal: res.horizontalPadding(16),
                              vertical: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (vm.isRefreshing) ...[
                                  Row(
                                    children: [
                                      const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.brandAccent),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Updating…',
                                        style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                _buildSummaryCards(res, vm.summary!),
                                const Divider(color: Colors.white10, height: 1, thickness: 0.5),
                                const SizedBox(height: 8),
                                _buildChartsSection(res, vm.summary!, vm),
                                const SizedBox(height: 24),
                                _buildStatsCards(res, vm.summary!, vm),
                                const SizedBox(height: 24),
                                _buildPortfolioTabsSection(res, vm.summary!, vm),
                                const SizedBox(height: 24),
                                _buildRecentlyTradedSection(res, vm),
                                const SizedBox(height: 32),
                                _buildPerformanceAnalyticsSection(res, vm),
                                const SizedBox(height: 32),
                                _buildDisclaimerSection(res),
                                const SizedBox(height: 60),
                              ],
                            ),
                          ),
                        ),
        );
      },
    );
  }

  Widget _buildPortfolioShimmer(Responsive res) {
    return ShimmerSkeleton(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: res.horizontalPadding(16), vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              ShimmerSkeleton.box(48, 48, radius: 24),
              const SizedBox(width: 12),
              Expanded(child: ShimmerSkeleton.pill(double.infinity, 16)),
            ]),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: ShimmerSkeleton.box(double.infinity, 88, radius: 12)),
              const SizedBox(width: 12),
              Expanded(child: ShimmerSkeleton.box(double.infinity, 88, radius: 12)),
            ]),
            const SizedBox(height: 12),
            ShimmerSkeleton.box(double.infinity, 88, radius: 12),
            const SizedBox(height: 32),
            ShimmerSkeleton.box(double.infinity, 220, radius: 16),
            const SizedBox(height: 24),
            ShimmerSkeleton.box(double.infinity, 160, radius: 16),
            const SizedBox(height: 24),
            ShimmerSkeleton.box(double.infinity, 48, radius: 8),
            const SizedBox(height: 8),
            ...List.generate(
              8,
              (_) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(children: [
                  ShimmerSkeleton.pill(80, 12),
                  const SizedBox(width: 12),
                  Expanded(child: ShimmerSkeleton.pill(double.infinity, 12)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _headerIconButton(IconData icon, {bool hasDot = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceBright.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          if (hasDot)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: AppColors.trendRed, shape: BoxShape.circle, border: Border.all(color: AppColors.background, width: 2)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Responsive res, dynamic s) {
    final double withdrawablePct = s.totalBalance > 0 ? (s.withdrawable / s.totalBalance * 100) : 0.0;
    
    return GridView.count(
      crossAxisCount: res.gridColumnCount(mobile: 2, tablet: 2, desktop: 4),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: res.value(mobile: 1.5, tablet: 2.2, desktop: 1.5),
      children: [
        _buildDesignCard('ACCOUNT VALUE', s.totalBalance, '', Icons.account_balance_wallet, AppColors.brandAccent),
        _buildDesignCard('WITHDRAWABLE', s.withdrawable, '${withdrawablePct.toStringAsFixed(2)}% of account', Icons.account_balance, AppColors.brandAccent, showProgress: true, progressValue: withdrawablePct / 100),
        _buildDesignCard('UNREALIZED PNL', s.unrealizedPnl, '${s.unrealizedPnlPct.toStringAsFixed(2)}%', Icons.show_chart, AppColors.trendRed),
        _buildDesignCard('WALLET', s.walletAddress, 'Live', Icons.qr_code_scanner, Colors.purpleAccent, isWallet: true),
      ],
    );
  }

  String _formatVolume(double value) {
    if (value >= 1e9) {
      return '${(value / 1e9).toStringAsFixed(1)}B';
    } else if (value >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(1)}M';
    } else if (value >= 1e3) {
      return '${(value / 1e3).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }

  void _showPerformanceDisclaimer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceBright,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Information', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _disclaimerItem('Calculation Basis', 'All trade analytics (win rate, PnL, volume, performance metrics) are calculated from the last 500 fills — the maximum available from Hyperliquid\'s API per request.'),
              const SizedBox(height: 16),
              _disclaimerItem('Data Sources', 'Data sourced using ASXN\'s node, Hyperliquid, DEX, Coingecko and Hyperscan and is updated every 30 seconds.'),
              const SizedBox(height: 16),
              _disclaimerItem('Informational Purpose', 'ASXN Dashboards are purely for informational purposes only. They are not intended to and should not be interpreted as investment or financial advice.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Dismiss', style: GoogleFonts.inter(color: AppColors.brandAccent)),
          ),
        ],
      ),
    );
  }

  Widget _disclaimerItem(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(body, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
      ],
    );
  }

  Widget _buildDisclaimerSection(Responsive res) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            'All trade analytics (win rate, PnL, volume, performance metrics) are calculated from the last 500 fills — the maximum available from Hyperliquid\'s API per request.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white24, fontSize: 10),
          ),
          const SizedBox(height: 8),
          Text(
            'Data sourced using ASXN\'s node, Hyperliquid, DEX, Coingecko and Hyperscan and is updated every 30 seconds.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white24, fontSize: 10),
          ),
          const SizedBox(height: 8),
          Text(
            'ASXN Dashboards are purely for informational purposes only. They are not intended to and should not be interpreted as investment or financial advice.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white24, fontSize: 10, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  String _fmtNum(double val) {
    if (val.abs() >= 1000000) return '${(val / 1000000).toStringAsFixed(2)}M';
    if (val.abs() >= 1000) return '${(val / 1000).toStringAsFixed(2)}K';
    if (val.abs() >= 100) return val.toStringAsFixed(2);
    if (val.abs() >= 10) return val.toStringAsFixed(3);
    return val.toStringAsFixed(4);
  }

  Widget _buildPerformanceAnalyticsSection(Responsive res, PortfolioViewModel vm) {
    final m = vm.performanceMetrics;

    // No trade data — hide entire section
    if (m.totalTrades == 0) return const SizedBox.shrink();

    final bool hasRecentActivity = vm.historyFills.isNotEmpty;
    final bool hasTradingActivity = m.totalTrades > 0;
    final bool hasRiskData = vm.summary != null && vm.summary!.totalBalance > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Performance Analytics',
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textPrimary,
                fontSize: res.fontSize(18),
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(Icons.info_outline, color: AppColors.textSecondary.withOpacity(0.5), size: 18),
              onPressed: () => _showPerformanceDisclaimer(context),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildPerformanceCard(
                'WIN RATE', 
                '${m.winRate.toStringAsFixed(1)}%', 
                '${m.totalWins} Wins / ${m.totalTrades} Trades',
                color: AppColors.trendGreen,
                progress: m.winRate / 100,
              ),
              _buildPerformanceCard(
                'PROFIT FACTOR', 
                m.profitFactor.toStringAsFixed(2), 
                'Gross Profit / Gross Loss',
                sparkline: m.winSparkline.take(5).toList(),
              ),
              _buildPerformanceCard(
                'AVG WIN', 
                '+\$${m.avgWin.toStringAsFixed(2)}', 
                'Average Winning Trade',
                color: AppColors.trendGreen,
                sparkline: m.winSparkline,
              ),
              _buildPerformanceCard(
                'AVG LOSS', 
                '-\$${m.avgLoss.toStringAsFixed(2)}', 
                'Average Losing Trade',
                color: AppColors.trendRed,
                sparkline: m.lossSparkline,
              ),
              _buildPerformanceCard(
                'LARGEST WIN', 
                '+\$${m.largestWin.toStringAsFixed(2)}', 
                m.largestWinCoin,
                color: AppColors.trendGreen,
              ),
              _buildPerformanceCard(
                'LARGEST LOSS', 
                '-\$${m.largestLoss.abs().toStringAsFixed(2)}', 
                m.largestLossCoin,
                color: AppColors.trendRed,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        if (res.isMobile) ...[
          if (hasRecentActivity) ...[
            _buildRecentActivitySection(res, vm),
            const SizedBox(height: 24),
          ],
          if (hasTradingActivity) ...[
            _buildTradingActivityDashboard(res, vm),
            const SizedBox(height: 24),
          ],
          if (hasRiskData)
            _buildRiskOverviewDashboard(res, vm),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasRecentActivity) ...[
                Expanded(child: _buildRecentActivitySection(res, vm)),
                const SizedBox(width: 16),
              ],
              if (hasTradingActivity) ...[
                Expanded(child: _buildTradingActivityDashboard(res, vm)),
                const SizedBox(width: 16),
              ],
              if (hasRiskData)
                Expanded(child: _buildRiskOverviewDashboard(res, vm)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPerformanceCard(String title, String value, String sub, {Color? color, double? progress, List<double>? sparkline}) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBright.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
              if (progress != null)
                SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 2,
                    backgroundColor: AppColors.surfaceBright.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.trendGreen),
                  ),
                ),
            ],
          ),
          Text(value, style: GoogleFonts.jetBrainsMono(color: color ?? Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(sub, style: GoogleFonts.inter(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 8), overflow: TextOverflow.ellipsis),
              ),
              if (sparkline != null && sparkline.isNotEmpty)
                SizedBox(
                  width: 30, height: 12,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: sparkline.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                          isCurved: true,
                          color: color ?? AppColors.brandAccent,
                          barWidth: 1,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(Responsive res, PortfolioViewModel vm) {
    final recent = vm.historyFills.take(5).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBright.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Activity', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...recent.map((f) {
            final isBuy = f.side.toLowerCase() == 'buy';
            final timeStr = _formatTimeAgo(f.time);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: isBuy ? AppColors.trendGreen : AppColors.trendRed, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${f.dir} ${f.sz} ${f.coin}', style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
                        Text(timeStr, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text(
                    f.closedPnl != 0 
                      ? '${f.closedPnl > 0 ? '+' : ''}${f.closedPnl.toStringAsFixed(4)}'
                      : '${f.px.toStringAsFixed(4)} px',
                    style: GoogleFonts.jetBrainsMono(
                      color: f.closedPnl > 0 ? AppColors.trendGreen : (f.closedPnl < 0 ? AppColors.trendRed : AppColors.textPrimary),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatTimeAgo(int timestamp) {
    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp));
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Widget _buildTradingActivityDashboard(Responsive res, PortfolioViewModel vm) {
    final m = vm.performanceMetrics;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBright.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Trading Activity', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTradingStat('TOTAL TRADES', m.totalTrades.toString()),
                    _buildTradingStat('TOTAL VOLUME', '\$${_formatVolume(m.totalVolume)}'),
                    _buildTradingStat('WINNING TRADES', '${m.totalWins} (${m.winRate.toStringAsFixed(1)}%)', color: AppColors.trendGreen),
                    _buildTradingStat('LOSING TRADES', '${m.totalTrades - m.totalWins} (${(100 - m.winRate).toStringAsFixed(1)}%)', color: AppColors.trendRed),
                    _buildTradingStat('TOTAL FEES', '\$${m.totalFees.toStringAsFixed(2)}'),
                  ],
                ),
              ),
              SizedBox(
                width: 100, height: 100,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 30,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        color: AppColors.trendGreen,
                        value: m.totalWins.toDouble(),
                        radius: 8,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        color: AppColors.trendRed,
                        value: (m.totalTrades - m.totalWins).toDouble(),
                        radius: 8,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chartLegend('Wins', AppColors.trendGreen),
              const SizedBox(width: 16),
              _chartLegend('Losses', AppColors.trendRed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTradingStat(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
          Text(value, style: GoogleFonts.jetBrainsMono(color: color ?? Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _chartLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _buildRiskOverviewDashboard(Responsive res, PortfolioViewModel vm) {
    final r = vm.riskMetrics;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBright.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Risk Overview', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 120, height: 120,
                child: RadarChart(
                  RadarChartData(
                    radarBorderData: const BorderSide(color: AppColors.surfaceBright, width: 0.5),
                    gridBorderData: const BorderSide(color: AppColors.surfaceBright, width: 0.2),
                    tickBorderData: const BorderSide(color: AppColors.surfaceBright, width: 0.1),
                    ticksTextStyle: const TextStyle(color: Colors.transparent),
                    titlePositionPercentageOffset: 0.2,
                    titleTextStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 8),
                    dataSets: [
                      RadarDataSet(
                        fillColor: AppColors.trendGreen.withOpacity(0.3),
                        borderColor: AppColors.trendGreen,
                        entryRadius: 2,
                        dataEntries: [
                          RadarEntry(value: r.leverageRisk),
                          RadarEntry(value: r.volatilityRisk),
                          RadarEntry(value: r.concentrationRisk),
                          RadarEntry(value: r.marginUsage),
                        ],
                      ),
                    ],
                    getTitle: (index, angle) {
                      switch (index) {
                        case 0: return const RadarChartTitle(text: 'Leverage');
                        case 1: return const RadarChartTitle(text: 'Volatil.');
                        case 2: return const RadarChartTitle(text: 'Concent.');
                        case 3: return const RadarChartTitle(text: 'Margin');
                        default: return const RadarChartTitle(text: '');
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _buildRiskBar('Leverage Risk', r.leverageRisk),
                    _buildRiskBar('Concentration Risk', r.concentrationRisk),
                    _buildRiskBar('Margin Usage', r.marginUsage),
                    _buildRiskBar('Volatility Risk', r.volatilityRisk),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskBar(String label, double value) {
    final color = value > 70 ? AppColors.trendRed : (value > 40 ? Colors.orange : AppColors.trendGreen);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 9)),
              Text(value > 70 ? 'High' : (value > 40 ? 'Med' : 'Low'), style: GoogleFonts.inter(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 3,
              backgroundColor: AppColors.surfaceBright.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, dynamic value, String subtitle, IconData icon, Color color) {
    return Container();
  }

  Widget _buildDesignCard(String title, dynamic value, String trend, IconData icon, Color accent, {bool isWallet = false, bool showProgress = false, double progressValue = 0.0}) {
    final res = Responsive(context);
    String displayValue = isWallet 
        ? '0x${value.substring(2, 6)}...${value.substring(value.length - 4)}'
        : '\$${value.toStringAsFixed(2)}';
     
     if (_hideValue && !isWallet) displayValue = '****';

     return Container(
       padding: EdgeInsets.all(res.value(mobile: 16, tablet: 12, desktop: 16)),
       decoration: BoxDecoration(
         color: AppColors.surfaceBright.withOpacity(0.2),
         borderRadius: BorderRadius.circular(res.value(mobile: 20, tablet: 14, desktop: 20)),
         border: Border.all(color: Colors.white.withOpacity(0.05)),
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Text(title, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: res.value(mobile: 10, tablet: 8, desktop: 10), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
               Container(
                 padding: EdgeInsets.all(res.value(mobile: 6, tablet: 4, desktop: 6)),
                 decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                 child: Icon(icon, color: accent, size: res.value(mobile: 16, tablet: 12, desktop: 16)),
               ),
             ],
           ),
           Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               FittedBox(
                 fit: BoxFit.scaleDown,
                 child: Text(displayValue, style: GoogleFonts.inter(color: Colors.white, fontSize: res.value(mobile: 16, tablet: 13, desktop: 16), fontWeight: FontWeight.bold)),
               ),
               const SizedBox(height: 4),
               if (showProgress) ...[
                 ClipRRect(
                   borderRadius: BorderRadius.circular(2),
                   child: LinearProgressIndicator(
                     value: progressValue.clamp(0.0, 1.0),
                     minHeight: 3,
                     backgroundColor: AppColors.surfaceBright.withOpacity(0.2),
                     valueColor: AlwaysStoppedAnimation<Color>(accent),
                   ),
                 ),
                 const SizedBox(height: 4),
                 Text(trend, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: res.value(mobile: 9, tablet: 7, desktop: 9), fontWeight: FontWeight.w400)),
               ] else Row(
                 children: [
                    if (!isWallet) Icon(trend.contains('-') ? Icons.arrow_drop_down : Icons.arrow_drop_up, color: trend.contains('-') ? AppColors.trendRed : AppColors.trendGreen, size: res.value(mobile: 14, tablet: 11, desktop: 14)),
                    if (isWallet) Container(width: 6, height: 6, decoration: BoxDecoration(color: AppColors.trendGreen, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(trend, style: GoogleFonts.inter(color: (isWallet || trend.isEmpty) ? AppColors.textSecondary : (trend.contains('-') ? AppColors.trendRed : AppColors.trendGreen), fontSize: res.value(mobile: 10, tablet: 8, desktop: 10), fontWeight: FontWeight.w500)),
                 ],
               ),
             ],
           ),
         ],
       ),
     );
  }

  // ─── STATS CARDS (Performance / Leverage / Margin / Liq Risk) ───────────────

  Widget _buildStatsCards(Responsive res, dynamic s, PortfolioViewModel vm) {
    // ── Performance Summary ──
    final fills = vm.historyFills;
    // Group by hash to get unique trades
    final Map<String, double> tradesPnl = {};
    for (final f in fills) {
      final key = f.hash.isNotEmpty ? f.hash : '${f.time}-${f.coin}';
      tradesPnl[key] = (tradesPnl[key] ?? 0) + f.closedPnl;
    }
    final totalTrades = tradesPnl.length;
    final totalPnl = tradesPnl.values.fold<double>(0, (a, b) => a + b);
    final profitable = tradesPnl.values.where((p) => p > 0).length;
    final winRate = totalTrades > 0 ? (profitable / totalTrades * 100) : 0.0;

    // ── Leverage ──
    final positions = s.positions as List;
    final double totalNotional = positions.fold(
      0.0, (sum, pos) => sum + (pos.size as double) * (pos.markPx as double));
    final double totalBalance = (s.totalBalance as double);
    final double accountLeverage = totalBalance > 0 ? totalNotional / totalBalance : 0;

    // ── Margin Usage ──
    final double marginUsed = s.marginUsed as double;
    final double marginUsedPct = totalBalance > 0 ? (marginUsed / totalBalance * 100) : 0;
    final double freeMargin = s.withdrawable as double;
    final double freeMarginPct = 100 - marginUsedPct;

    // ── Liq Risk — find worst risk level across positions ──
    String liqRiskLabel = 'Safe';
    Color liqRiskColor = AppColors.trendGreen;
    String liqRiskSub = 'No critical positions';
    for (final pos in positions) {
      final risk = pos.liqRisk as String;
      if (risk == 'danger') {
        liqRiskLabel = 'High Risk';
        liqRiskColor = AppColors.trendRed;
        liqRiskSub = 'Liq. distance < 5%';
        break;
      } else if (risk == 'warn' && liqRiskLabel != 'High Risk') {
        liqRiskLabel = 'Caution';
        liqRiskColor = const Color(0xFFF59E0B);
        liqRiskSub = 'Liq. distance < 10%';
      }
    }
    if (positions.isEmpty) {
      liqRiskLabel = 'Neutral';
      liqRiskSub = 'No open positions';
    }

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 600;

      // Build the 4 card widgets
      final cards = [
        // ── 1. Performance Summary ──
        _statsCard(
          label: 'PERFORMANCE SUMMARY',
          mainWidget: Text(
            '${totalPnl >= 0 ? '+' : ''}\$${totalPnl.toStringAsFixed(2)}',
            style: GoogleFonts.jetBrainsMono(
              color: totalPnl >= 0 ? AppColors.trendGreen : AppColors.trendRed,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          subWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Win Rate: ${winRate.toStringAsFixed(1)}%',
                style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 9),
              ),
              Text(
                'Trades: $totalTrades',
                style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 9),
              ),
            ],
          ),
        ),

        // ── 2. Leverage ──
        _statsCard(
          label: 'LEVERAGE',
          mainWidget: Text(
            '${accountLeverage.toStringAsFixed(6)}X',
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          subWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: (accountLeverage / 10).clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    accountLeverage > 5 ? AppColors.trendRed : AppColors.brandAccent,
                  ),
                  minHeight: 3,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '\$${_fmtNum(totalNotional)} Notional',
                style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 8),
              ),
              Text(
                '\$${_fmtNum(totalBalance)} Equity',
                style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 8),
              ),
            ],
          ),
        ),

        // ── 3. Margin Usage ──
        _statsCard(
          label: 'MARGIN USAGE',
          mainWidget: Text(
            '${marginUsedPct.toStringAsFixed(2)}%',
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          subWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: (marginUsedPct / 100).clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    marginUsedPct > 80 ? AppColors.trendRed : AppColors.trendGreen,
                  ),
                  minHeight: 3,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '\$${_fmtNum(freeMargin)} Free',
                style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 8),
              ),
              Text(
                '${freeMarginPct.toStringAsFixed(1)}% free to margin',
                style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 8),
              ),
            ],
          ),
        ),

        // ── 4. Liq Risk ──
        _statsCard(
          label: 'LIQUIDATION RISK',
          mainWidget: Text(
            liqRiskLabel,
            style: GoogleFonts.jetBrainsMono(
              color: liqRiskColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          subWidget: Text(
            liqRiskSub,
            style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 9),
          ),
        ),
      ];

      if (isWide) {
        // 4 in one row
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
              const SizedBox(width: 12),
              Expanded(child: cards[2]),
              const SizedBox(width: 12),
              Expanded(child: cards[3]),
            ],
          ),
        );
      } else {
        // 2×2 grid
        return Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[1]),
                ],
              ),
            ),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[3]),
                ],
              ),
            ),
          ],
        );
      }
    });
  }

  Widget _statsCard({
    required String label,
    required Widget mainWidget,
    required Widget subWidget,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          mainWidget,
          subWidget,
        ],
      ),
    );
  }

  Widget _buildChartsSection(Responsive res, dynamic s, PortfolioViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (vm.ohlcSnapshots.isNotEmpty) ...[
          _buildOhlcChart(vm),
          const SizedBox(height: 24),
        ] else if (vm.snapshotsLoading) ...[
          _buildChartShimmer(),
          const SizedBox(height: 24),
        ],
        // _buildFullPnLChart(res, s, vm), // commented out — only OHLC chart is shown
        // const SizedBox(height: 24),
        _buildAssetTreemap(vm),
      ],
    );
  }

  Widget _buildChartShimmer() {
    return ShimmerSkeleton(
      child: Container(
        height: 320,
        decoration: BoxDecoration(
          color: AppColors.surfaceBright.withOpacity(0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerSkeleton.pill(140, 14),
              const SizedBox(height: 16),
              ShimmerSkeleton.box(double.infinity, 200, radius: 12),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(3, (_) => ShimmerSkeleton.pill(80, 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortfolioTabsSection(Responsive res, dynamic s, PortfolioViewModel vm) {
    // Build tab data with original indices
    final allTabs = [
      {'label': 'Asset Positions', 'count': (s.positions as List).length, 'index': 0},
      {'label': 'Open Orders',     'count': (s.openOrders as List).length, 'index': 1},
      {'label': 'Recent Fills',    'count': vm.historyFills.length,         'index': 2},
      {'label': 'Spot Balances',   'count': (s.spotBalances as List).length,'index': 3},
    ];

    // Only show tabs that have data
    final visibleTabs = allTabs.where((t) => (t['count'] as int) > 0).toList();

    // If current selected tab is now hidden, jump to first visible
    final visibleIndices = visibleTabs.map((t) => t['index'] as int).toList();
    if (visibleIndices.isNotEmpty &&
        !visibleIndices.contains(_selectedDetailedTabIndex)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedDetailedTabIndex = visibleIndices.first;
          });
        }
      });
    }

    if (visibleTabs.isEmpty) return const SizedBox.shrink();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDetailTabs(s, vm, visibleTabs),
          const Divider(color: Colors.white10, height: 1),
          _buildSelectedTable(res, s, vm),
        ],
      ),
    );
  }

  Widget _buildDetailTabs(dynamic s, PortfolioViewModel vm, List<Map<String, dynamic>> visibleTabs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: visibleTabs.map((tab) {
          final originalIndex = tab['index'] as int;
          final isSelected = _selectedDetailedTabIndex == originalIndex;
          final count = tab['count'] as int;

          return GestureDetector(
            onTap: () => setState(() {
              _selectedDetailedTabIndex = originalIndex;
              _positionsPage = 1;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(
                  color: isSelected ? AppColors.brandAccent : Colors.transparent,
                  width: 2,
                )),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tab['label'] as String,
                    style: GoogleFonts.inter(
                      color: isSelected ? Colors.white : Colors.white54,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.jetBrainsMono(
                          color: Colors.white38, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSelectedTable(Responsive res, dynamic s, PortfolioViewModel vm) {
    switch (_selectedDetailedTabIndex) {
      case 0: return _buildDetailedPositions(res, s);
      case 1: return _buildDetailedOrders(s);
      case 2: return _buildDetailedTradeHistory(vm);
      case 3: return _buildDetailedSpotBalances(s);
      default: return const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('Empty', style: TextStyle(color: Colors.white24))));
    }
  }

  Widget _buildOhlcChart(PortfolioViewModel vm) {
    final ohlc = vm.ohlcSnapshots;
    if (ohlc.isEmpty) return const SizedBox.shrink();

    final firstClose = ohlc.first.close;
    final lastClose = ohlc.last.close;
    final isPos = lastClose >= firstClose;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Account Value',
                    style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                Text('OHLC 1h',
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildOhlcTabs(),
          const SizedBox(height: 8),
          SizedBox(
            height: 240,
            child: ohlc.length < 2
                ? Center(
                    child: Text('Not enough data',
                        style: GoogleFonts.jetBrainsMono(color: Colors.white24, fontSize: 12)),
                  )
                : _buildOhlcChartBody(ohlc),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _chartMetric('START', '\$${_fmtNum(firstClose)}'),
                _chartMetric('CURRENT', '\$${_fmtNum(lastClose)}'),
                _chartMetric(
                  'CHANGE',
                  '${(lastClose - firstClose) >= 0 ? '+' : ''}\$${_fmtNum(lastClose - firstClose)}',
                  color: isPos ? AppColors.trendGreen : AppColors.trendRed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOhlcTabs() {
    const labels = ['Candlestick', 'Bar', 'Area'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: List.generate(3, (i) {
            final isActive = _selectedOhlcChartType == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedOhlcChartType = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF10B981) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      labels[i],
                      style: GoogleFonts.jetBrainsMono(
                        color: isActive ? Colors.black : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildOhlcChartBody(List<OhlcSnapshot> ohlc) {
    switch (_selectedOhlcChartType) {
      case 0: return _buildCandlestickChart(ohlc);
      case 1: return _buildOhlcBarChart(ohlc);
      case 2: return _buildOhlcAreaChart(ohlc);
      default: return _buildCandlestickChart(ohlc);
    }
  }

  List<double> _ohlcCloseValues(List<OhlcSnapshot> ohlc) {
    return ohlc.map((s) => s.close).toList();
  }

  List<int> _ohlcTimestamps(List<OhlcSnapshot> ohlc) {
    return ohlc.map((s) => s.timestamp).toList();
  }

  Widget _buildCandlestickChart(List<OhlcSnapshot> ohlc) {
    final n = ohlc.length;
    final double minVal = ohlc.map((s) => s.low).reduce((a, b) => a < b ? a : b);
    final double maxVal = ohlc.map((s) => s.high).reduce((a, b) => a > b ? a : b);
    final double dataRange = maxVal - minVal;
    final double yInterval = _calcNiceInterval(dataRange);
    double yMin = (minVal / yInterval).floorToDouble() * yInterval;
    double yMax = (maxVal / yInterval).ceilToDouble() * yInterval;
    if (yMax - maxVal < yInterval * 0.2) yMax += yInterval;
    if (minVal - yMin < yInterval * 0.2) yMin -= yInterval;
    if (yMin < 0) yMin = 0;

    const double yAxisW = 60.0;

    return LayoutBuilder(builder: (ctx, box) {
      final availW = box.maxWidth - yAxisW - 16;
      final candleW = ((availW - 60) / n - 5).clamp(4.0, 28.0); // Increased width and gap
      final totalW = n * (candleW + 5) + 60;
      final initialW = totalW < availW ? availW : totalW;
      final chartH = 236.0;
      final totalDataW = n * (candleW + 5);
      final startX = (initialW - totalDataW) / 2;

      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: yAxisW,
              child: CustomPaint(
                painter: _YAxisPainter(yMin: yMin, yMax: yMax, interval: yInterval),
              ),
            ),
            Expanded(
              child: ClipRect(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTapUp: (details) {
                        final matrix = _chartTransformCtrl.value;
                        final inverse = Matrix4.inverted(matrix);
                        final chartPos = MatrixUtils.transformPoint(inverse, details.localPosition);

                        for (int i = 0; i < n; i++) {
                          final cx = startX + i * (candleW + 5);
                          if (chartPos.dx >= cx && chartPos.dx <= cx + candleW) {
                            setState(() {
                              _selectedCandle = ohlc[i];
                            });
                            return;
                          }
                        }
                        setState(() {
                          _selectedCandle = null;
                        });
                      },
                      child: InteractiveViewer(
                        transformationController: _chartTransformCtrl,
                        constrained: false,
                        minScale: 1.0,
                        maxScale: 6.0,
                        boundaryMargin: const EdgeInsets.all(40),
                        child: SizedBox(
                          width: initialW,
                          height: chartH,
                          child: CustomPaint(
                            painter: _CandlestickChartPainter(
                              data: ohlc,
                              yMin: yMin,
                              yMax: yMax,
                              candleWidth: candleW,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_selectedCandle != null)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: _buildCandleTooltip(_selectedCandle!),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCandleTooltip(OhlcSnapshot c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _fmtTimestamp(c.timestamp),
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
          const SizedBox(height: 4),
          _tooltipRow('O', c.open, Colors.white70),
          _tooltipRow('H', c.high, const Color(0xFF22C55E)),
          _tooltipRow('L', c.low, const Color(0xFFEF4444)),
          _tooltipRow('C', c.close, c.close >= c.open
              ? const Color(0xFF22C55E)
              : const Color(0xFFEF4444)),
          _tooltipRow('Vol', c.count.toDouble(), Colors.white54),
        ],
      ),
    );
  }

  Widget _tooltipRow(String label, double value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label  ',
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
          Text(_fmtNum(value),
            style: TextStyle(color: valueColor, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildOhlcBarChart(List<OhlcSnapshot> ohlc) {
    final series = _ohlcCloseValues(ohlc);
    final timestamps = _ohlcTimestamps(ohlc);
    final n = series.length;
    final double minVal = series.reduce((a, b) => a < b ? a : b);
    final double maxVal = series.reduce((a, b) => a > b ? a : b);
    final double dataRange = maxVal - minVal;
    final double yInterval = _calcNiceInterval(dataRange);
    double yMin = (minVal / yInterval).floorToDouble() * yInterval;
    double yMax = (maxVal / yInterval).ceilToDouble() * yInterval;
    if (yMax - maxVal < yInterval * 0.2) yMax += yInterval;
    if (minVal - yMin < yInterval * 0.2) yMin -= yInterval;
    if (yMin < 0) yMin = 0;

    final barWidth = n > 15 ? 12.0 : 24.0; // Increased bar thickness
    final double chartW = n * (barWidth + 14) + 40;

    return LayoutBuilder(builder: (ctx, box) {
      final availW = box.maxWidth - 60 - 16;
      final double finalW = chartW < availW ? availW : chartW;

      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 60,
              child: CustomPaint(
                painter: _YAxisPainter(yMin: yMin, yMax: yMax, interval: yInterval),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: finalW,
                  child: BarChart(
                    BarChartData(
                      minY: yMin,
                      maxY: yMax,
                      alignment: BarChartAlignment.spaceAround,
                      barGroups: List.generate(n, (i) {
                        final barColor = series[i] >= series[0] ? AppColors.trendGreen : AppColors.trendRed;
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: series[i],
                              color: barColor.withOpacity(0.8),
                              width: barWidth,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: yInterval,
                        getDrawingHorizontalLine: (_) => FlLine(
                            color: Colors.white.withOpacity(0.04), strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: _ohlcBottomTitles(timestamps, n),
                      ),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => AppColors.surfaceBright,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final abs = rod.toY.abs();
                            final yLabel = abs >= 1000000
                                ? '\$${(rod.toY / 1000000).toStringAsFixed(2)}M'
                                : (abs >= 1000
                                    ? '\$${(rod.toY / 1000).toStringAsFixed(1)}K'
                                    : '\$${rod.toY.toStringAsFixed(2)}');
                            final idx = group.x.toInt();
                            final dateLabel = (idx >= 0 && idx < timestamps.length)
                                ? _fmtTimestamp(timestamps[idx])
                                : '';
                            return BarTooltipItem(
                              '$yLabel\n$dateLabel',
                              GoogleFonts.jetBrainsMono(
                                  color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            );
                          },
                        ),
                      ),
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildOhlcAreaChart(List<OhlcSnapshot> ohlc) {
    final series = _ohlcCloseValues(ohlc);
    final timestamps = _ohlcTimestamps(ohlc);
    final n = series.length;
    final double minVal = series.reduce((a, b) => a < b ? a : b);
    final double maxVal = series.reduce((a, b) => a > b ? a : b);
    final double range = (maxVal - minVal).abs();
    final double yInterval = _calcNiceInterval(range);
    double yMin = (minVal / yInterval).floorToDouble() * yInterval;
    double yMax = (maxVal / yInterval).ceilToDouble() * yInterval;
    if (yMax - maxVal < yInterval * 0.2) yMax += yInterval;
    if (minVal - yMin < yInterval * 0.2) yMin -= yInterval;

    final spots = List<FlSpot>.generate(n, (i) => FlSpot(i.toDouble(), series[i]));

    return LayoutBuilder(builder: (ctx, box) {
      final availW = box.maxWidth - 60 - 16;
      final chartW = n <= 20 ? n * 55.0 : n * 8.0;
      final double finalW = chartW < availW ? availW : chartW;

      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 60,
              child: CustomPaint(
                painter: _YAxisPainter(yMin: yMin, yMax: yMax, interval: yInterval),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: finalW,
                  child: LineChart(
                    LineChartData(
                      minY: yMin,
                      maxY: yMax,
                      minX: 0,
                      maxX: (n - 1).toDouble(),
                      clipData: const FlClipData.all(),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: yInterval,
                        getDrawingHorizontalLine: (_) => FlLine(
                            color: Colors.white.withOpacity(0.04), strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: _ohlcBottomTitles(timestamps, n),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => AppColors.surfaceBright,
                          getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                            final abs = s.y.abs();
                            final yLabel = abs >= 1000000
                                ? '\$${(s.y / 1000000).toStringAsFixed(2)}M'
                                : (abs >= 1000
                                    ? '\$${(s.y / 1000).toStringAsFixed(1)}K'
                                    : '\$${s.y.toStringAsFixed(2)}');
                            final idx = s.x.toInt();
                            final dateLabel = (idx >= 0 && idx < timestamps.length)
                                ? _fmtTimestamp(timestamps[idx])
                                : '';
                            return LineTooltipItem(
                              '$yLabel  $dateLabel',
                              GoogleFonts.jetBrainsMono(
                                  color: AppColors.brandAccent, fontSize: 11, fontWeight: FontWeight.bold),
                            );
                          }).toList(),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.3,
                          color: AppColors.brandAccent,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.brandAccent.withOpacity(0.18),
                                AppColors.brandAccent.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  AxisTitles _ohlcBottomTitles(List<int> timestamps, int n) {
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 40,
        getTitlesWidget: (value, meta) {
          final idx = value.toInt();
          if (idx < 0 || idx >= timestamps.length) return const SizedBox();
          final labelEvery = n <= 10 ? 1 : (n / 10).ceil();
          if (idx % labelEvery != 0) return const SizedBox();
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _fmtTimestamp(timestamps[idx]),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: GoogleFonts.jetBrainsMono(
                  color: Colors.white.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.w500),
            ),
          );
        },
      ),
    );
  }

  String _fmtTimestamp(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    final month = _getMonthName(d.month);
    final day = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$month $day\n$hh:$mm';
  }

  double _calcNiceInterval(double range) {
    if (range <= 0) return 1;
    final rawInterval = (range / 5).abs().clamp(0.01, double.infinity);
    final exponent = (log(rawInterval) / ln10).floorToDouble();
    final fraction = rawInterval / pow(10, exponent);
    double niceFraction;
    if (fraction < 1.5) {
      niceFraction = 1.0;
    } else if (fraction < 3.0) {
      niceFraction = 2.0;
    } else if (fraction < 7.0) {
      niceFraction = 5.0;
    } else {
      niceFraction = 10.0;
    }
    return niceFraction * pow(10, exponent);
  }

  Widget _buildFullPnLChart(Responsive res, dynamic s, PortfolioViewModel vm) {
    final series     = _getSelectedSeries(vm);
    final timestamps = vm.historyTimestamps;
    final bool hasData = series.length >= 2;
    final bool isAccountValue = _selectedChartTabIndex == 2;
    final bool isPos  = series.isNotEmpty && series.last >= series.first;
    final Color themeColor = isAccountValue
        ? AppColors.brandAccent
        : (isPos ? AppColors.trendGreen : AppColors.trendRed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Card: header + bottom stats ──
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceBright.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: tabs + dropdown — only show if there's data
              if (hasData) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.surfaceBright),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // _chartTabHome('Combined PnL', 0),
                                // _chartTabHome('Perp PnL',     1),
                                _chartTabHome('Acct Value',   2),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildRangeDropdown(vm),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Chart — full width, no horizontal padding ──
                SizedBox(
                  height: 240,
                  child: _buildMainLineChart(series, timestamps, themeColor),
                ),
              ],

              // Bottom stats — always show
              Padding(
                padding: EdgeInsets.fromLTRB(20, hasData ? 12 : 18, 20, 18),
                child: Column(children: [
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _chartMetric('CURRENT VALUE',
                          '\$${_fmtNum(s.totalBalance as double)}'),
                      _chartMetric('TRADE VOLUME',
                          '\$${_fmtNum(vm.currentVolume)}'),
                      _chartMetric(
                        'ALL CHANGE',
                        '${vm.allChange >= 0 ? '+' : ''}\$${_fmtNum(vm.allChange)}',
                        color: vm.allChange >= 0
                            ? AppColors.trendGreen
                            : AppColors.trendRed,
                      ),
                    ],
                  ),
                ]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Tab pill — same visual as home screen _buildTab
  Widget _chartTabHome(String label, int index) {
    final isActive = _selectedChartTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedChartTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.surfaceBright : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: isActive ? AppColors.brandAccent : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// Range dropdown — D / W / M / Y / ALL
  Widget _buildRangeDropdown(PortfolioViewModel vm) {
    const labels = {
      PortfolioTimeRange.day:   'D',
      PortfolioTimeRange.week:  'W',
      PortfolioTimeRange.month: 'M',
      PortfolioTimeRange.year:  'Y',
      PortfolioTimeRange.all:   'ALL',
    };

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBright),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PortfolioTimeRange>(
          value: vm.selectedRange,
          dropdownColor: AppColors.background,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: AppColors.brandAccent, size: 14),
          style: GoogleFonts.jetBrainsMono(
              color: AppColors.brandAccent,
              fontSize: 11,
              fontWeight: FontWeight.bold),
          borderRadius: BorderRadius.circular(8),
          elevation: 4,
          onChanged: (r) { if (r != null) vm.setTimeRange(r); },
          items: labels.entries
              .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  ))
              .toList(),
        ),
      ),
    );
  }

  List<double> _getSelectedSeries(PortfolioViewModel vm) {
    switch (_selectedChartTabIndex) {
      case 0: return vm.combinedPnlSeries;
      case 1: return vm.perpPnlSeries;
      case 2: return vm.accountValueSeries;
      default: return vm.combinedPnlSeries;
    }
  }

  Widget _buildMainLineChart(List<double> pnlData, List<int> timestamps, Color themeColor) {
    final double minVal = pnlData.reduce((a, b) => a < b ? a : b);
    final double maxVal = pnlData.reduce((a, b) => a > b ? a : b);
    final double range = (maxVal - minVal).abs();
    
    // 1. Calculate a "nice" interval
    double rawInterval = (range / 5).abs().clamp(0.01, double.infinity);
    double exponent = (log(rawInterval) / ln10).floorToDouble();
    double fraction = rawInterval / pow(10, exponent);
    double niceFraction;
    if (fraction < 1.5) { niceFraction = 1.0; }
    else if (fraction < 3.0) { niceFraction = 2.0; }
    else if (fraction < 7.0) { niceFraction = 5.0; }
    else { niceFraction = 10.0; }
    double yInterval = niceFraction * pow(10, exponent);

    // 2. Align yMin and yMax to this interval for clean labels
    double yMin = (minVal / yInterval).floorToDouble() * yInterval;
    double yMax = (maxVal / yInterval).ceilToDouble() * yInterval;

    // Add one extra interval of padding if too tight
    if (yMax - maxVal < yInterval * 0.2) yMax += yInterval;
    if (minVal - yMin < yInterval * 0.2) yMin -= yInterval;

    String fmtDate(int ts) {
      final d = DateTime.fromMillisecondsSinceEpoch(ts);
      final month = _getMonthName(d.month);
      final day = d.day.toString().padLeft(2, '0');
      final hh = d.hour.toString().padLeft(2, '0');
      final mm = d.minute.toString().padLeft(2, '0');
      return '$month $day\n$hh:$mm';
    }

    final int n = pnlData.length;
    const double yAxisW = 60.0;

    final spots = List<FlSpot>.generate(n, (i) => FlSpot(i.toDouble(), pnlData[i]));
    final int labelEvery = n <= 20 ? 1 : (n / 10).ceil();

    return LayoutBuilder(builder: (ctx, box) {
      final availW = box.maxWidth - yAxisW - 16;
      final chartW = n <= 20 ? n * 55.0 : n * 8.0;
      final double finalW = chartW < availW ? availW : chartW;

      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: yAxisW,
              child: CustomPaint(
                painter: _YAxisPainter(yMin: yMin, yMax: yMax, interval: yInterval),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: finalW,
                  child: LineChart(
                    key: ValueKey('chart_${_selectedChartTabIndex}_$n'),
                    LineChartData(
                      minY: yMin,
                      maxY: yMax,
                      minX: 0,
                      maxX: (n - 1).toDouble(),
                      clipData: const FlClipData.all(),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: yInterval,
                        getDrawingHorizontalLine: (_) => FlLine(
                            color: Colors.white.withOpacity(0.04), strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= timestamps.length) return const SizedBox();
                              if (idx % labelEvery != 0) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  fmtDate(timestamps[idx]),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  style: GoogleFonts.jetBrainsMono(
                                      color: Colors.white.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.w500),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => AppColors.surfaceBright,
                          getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                            final abs = s.y.abs();
                            final String yLabel;
                            if (abs >= 1000000) {
                              yLabel = '\$${(s.y / 1000000).toStringAsFixed(2)}M';
                            } else if (abs >= 1000) {
                              yLabel = '\$${(s.y / 1000).toStringAsFixed(1)}K';
                            } else {
                              yLabel = '\$${s.y.toStringAsFixed(2)}';
                            }
                            final idx = s.x.toInt();
                            final dateLabel = (idx >= 0 && idx < timestamps.length)
                                ? fmtDate(timestamps[idx])
                                : '';
                            return LineTooltipItem(
                              '$yLabel  $dateLabel',
                              GoogleFonts.jetBrainsMono(
                                  color: themeColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            );
                          }).toList(),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.3,
                          color: themeColor,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                themeColor.withOpacity(0.18),
                                themeColor.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _chartTab(String label, {bool active = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.surfaceBright : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: active ? AppColors.brandAccent : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _chartMetric(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label,
            style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Text(value,
            style: GoogleFonts.jetBrainsMono(
                color: color ?? Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildChartContainer(String title, String value, String sub, Widget chart, {bool hasDropdown = false, String? detailLabel}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(title, style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  if (detailLabel != null) ...[
                    const SizedBox(width: 8),
                    Text(detailLabel, style: GoogleFonts.inter(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 10)),
                  ],
                ],
              ),
              if (hasDropdown) Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceBright.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(children: [Text('All allocations', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)), Icon(Icons.keyboard_arrow_down, color: Colors.white.withOpacity(0.7), size: 14)]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (value.isNotEmpty) ...[
            Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(sub, style: GoogleFonts.inter(color: AppColors.trendGreen, fontSize: 12)),
            const SizedBox(height: 20),
          ],
          chart,
        ],
      ),
    );
  }

  // ─── ASSET COMPOSITION ────────────────────────────────────────────────────────

  Widget _buildAssetTreemap(PortfolioViewModel vm) {
    final items = vm.assetComposition;

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceBright.withOpacity(0.2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('No asset data', style: TextStyle(color: Colors.white24)),
          ),
        ),
      );
    }

    // Total value for center label
    final double totalValue = items.fold(0, (sum, i) => sum + i.usdValue);

    String fmtTotal(double v) {
      if (v >= 1000000) return '\$${(v / 1000000).toStringAsFixed(1)}M';
      if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(1)}K';
      return '\$${v.toStringAsFixed(0)}';
    }

    // Build PieChartSectionData from items
    final sections = items.map((item) {
      return PieChartSectionData(
        value: item.usdValue,
        color: item.color,
        radius: 26,
        showTitle: false,
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Asset Composition',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Donut + List row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Donut chart ──
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 42,
                        sectionsSpace: 2,
                        startDegreeOffset: -90,
                      ),
                    ),
                    // Center label
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'TOTAL',
                          style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          fmtTotal(totalValue),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // ── Symbols list ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOP SYMBOLS',
                      style: GoogleFonts.inter(
                        color: Colors.white30,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...items.map((item) => _assetSymbolRow(item)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _assetSymbolRow(AssetCompositionItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          // Color dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          // Coin name
          Expanded(
            child: Text(
              item.coin,
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // USD value
          Text(
            '\$${_fmtNum(item.usdValue)}',
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 12),
          // Percentage
          SizedBox(
            width: 38,
            child: Text(
              '${item.percentage.toStringAsFixed(1)}%',
              textAlign: TextAlign.right,
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── RECENTLY TRADED SYMBOLS ─────────────────────────────────────────────────

  Widget _buildRecentlyTradedSection(Responsive res, PortfolioViewModel vm) {
    final all = vm.symbolSummaries; // already sorted by volume desc

    if (all.isEmpty) return const SizedBox.shrink();

    final int totalPages = (all.length / _recentPerPage).ceil();
    final int start = (_recentPage - 1) * _recentPerPage;
    final int end = (start + _recentPerPage).clamp(0, all.length);
    final items = all.sublist(start, end);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recently Traded Symbols',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${all.length} symbols',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white30,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Table — fixed left + horizontal scroll right ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fixed: Rank + Symbol
              SizedBox(
                width: 130,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _rtHeader('Symbol', width: 130, leftPad: 20),
                    // Rows
                    ...items.asMap().entries.map((e) {
                      final rank = start + e.key + 1;
                      return _rtAssetCell(e.value.symbol, rank);
                    }),
                  ],
                ),
              ),

              // Scrollable: Trades, Volume, PnL, Win Rate, Best/Worst, Fees
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      SizedBox(
                        height: 40,
                        child: Row(children: [
                          _rtHeader('Trades',    width: 70),
                          _rtHeader('Volume',    width: 110),
                          _rtHeader('PnL',       width: 110),
                          _rtHeader('Win Rate',  width: 120),
                          _rtHeader('Best / Worst', width: 140),
                          _rtHeader('Fees',      width: 80),
                        ]),
                      ),
                      // Data rows
                      ...items.map((sym) {
                        final pnlPos  = sym.pnl >= 0;
                        final pnlClr  = pnlPos ? AppColors.trendGreen : AppColors.trendRed;
                        final winFrac = (sym.winRate / 100).clamp(0.0, 1.0);
                        final hasBest  = sym.best  > -999999998;
                        final hasWorst = sym.worst <  999999998;

                        return Container(
                          height: 52,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Trades
                              SizedBox(
                                width: 70,
                                child: Text(
                                  '${sym.trades}',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.jetBrainsMono(
                                    color: AppColors.textPrimary,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              // Volume
                              SizedBox(
                                width: 110,
                                child: Text(
                                  '\$${_fmtExact(sym.volume)}',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.jetBrainsMono(
                                    color: AppColors.textPrimary,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              // PnL
                              SizedBox(
                                width: 110,
                                child: Text(
                                  '${pnlPos ? '+' : ''}\$${_fmtExact(sym.pnl)}',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.jetBrainsMono(
                                    color: pnlClr,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // Win Rate — bar + %
                              SizedBox(
                                width: 120,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(2),
                                          child: LinearProgressIndicator(
                                            value: winFrac,
                                            backgroundColor: Colors.white.withOpacity(0.07),
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              sym.winRate >= 60
                                                  ? AppColors.trendGreen
                                                  : sym.winRate >= 40
                                                      ? const Color(0xFFF59E0B)
                                                      : AppColors.trendRed,
                                            ),
                                            minHeight: 4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${sym.winRate.toStringAsFixed(0)}%',
                                        style: GoogleFonts.jetBrainsMono(
                                          color: AppColors.textSecondary,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Best / Worst
                              SizedBox(
                                width: 140,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      hasBest
                                          ? '+\$${_fmtExact(sym.best)}'
                                          : '—',
                                      style: GoogleFonts.jetBrainsMono(
                                        color: AppColors.trendGreen,
                                        fontSize: 10,
                                      ),
                                    ),
                                    Text(
                                      '  /  ',
                                      style: GoogleFonts.jetBrainsMono(
                                        color: Colors.white24,
                                        fontSize: 10,
                                      ),
                                    ),
                                    Text(
                                      hasWorst
                                          ? '\$${_fmtExact(sym.worst)}'
                                          : '—',
                                      style: GoogleFonts.jetBrainsMono(
                                        color: AppColors.trendRed,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Fees
                              SizedBox(
                                width: 80,
                                child: Text(
                                  '\$${sym.fees.toStringAsFixed(2)}',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.jetBrainsMono(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Pagination ──
          if (totalPages > 1) ...[
            const Divider(color: AppColors.surfaceBright, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${start + 1}–$end of ${all.length}',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  Row(
                    children: [
                      _posPageBtn(
                        icon: Icons.chevron_left,
                        isEnabled: _recentPage > 1,
                        isActive: false,
                        onTap: () => setState(() => _recentPage--),
                      ),
                      const SizedBox(width: 6),
                      ...() {
                        int pStart = (_recentPage - 1).clamp(1, totalPages);
                        int pEnd = (pStart + 2).clamp(1, totalPages);
                        if (pEnd == totalPages && totalPages > 3) pStart = pEnd - 2;
                        List<Widget> btns = [];
                        for (int i = pStart; i <= pEnd; i++) {
                          btns.add(Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: _posPageBtn(
                              text: '$i',
                              isActive: i == _recentPage,
                              isEnabled: true,
                              onTap: () => setState(() => _recentPage = i),
                            ),
                          ));
                        }
                        return btns;
                      }(),
                      const SizedBox(width: 6),
                      _posPageBtn(
                        icon: Icons.chevron_right,
                        isEnabled: _recentPage < totalPages,
                        isActive: false,
                        onTap: () => setState(() => _recentPage++),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 8),
        ],
      ),
    );
  }

  // Fixed-left header cell for recently traded table
  Widget _rtHeader(String label, {required double width, double leftPad = 0}) {
    return Container(
      width: width,
      height: 40,
      padding: EdgeInsets.only(left: leftPad),
      alignment: leftPad > 0 ? Alignment.centerLeft : Alignment.center,
      child: Text(
        label,
        textAlign: leftPad > 0 ? TextAlign.left : TextAlign.center,
        style: GoogleFonts.jetBrainsMono(
          color: AppColors.textSecondary,
          fontSize: 10,
        ),
      ),
    );
  }

  // Fixed-left asset cell with rank
  Widget _rtAssetCell(String symbol, int rank) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$rank',
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white30,
                fontSize: 10,
              ),
            ),
          ),
          Expanded(
            child: Text(
              symbol,
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Format number with 4 decimal places for trade data
  String _fmtExact(double val) {
    final abs = val.abs();
    if (abs >= 1000000) return '${(val / 1000000).toStringAsFixed(2)}M';
    if (abs >= 1000)    return '${(val / 1000).toStringAsFixed(2)}K';
    if (abs >= 100)     return val.toStringAsFixed(2);
    if (abs >= 10)      return val.toStringAsFixed(4);
    return val.toStringAsFixed(4);
  }

  // ─── PORTFOLIO TABLES (Home-screen style) ───────────────────────────────────

  Widget _buildDetailedPositions(Responsive res, dynamic s) {
    final allPositions = s.positions as List;
    if (allPositions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: Text('No Open Positions', style: TextStyle(color: Colors.white24))),
      );
    }

    final int totalPages = (allPositions.length / _positionsPerPage).ceil();
    final int start = (_positionsPage - 1) * _positionsPerPage;
    final int end = (start + _positionsPerPage).clamp(0, allPositions.length);
    final positions = allPositions.sublist(start, end);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Table ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed left: Asset column
            SizedBox(
              width: 120,
              child: Column(
                children: [
                  _posTableHeaderCell('Asset', width: 120, align: Alignment.centerLeft, leftPad: 16),
                  ...positions.map((pos) => _posAssetCell(pos)),
                ],
              ),
            ),
            // Scrollable right columns
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Row(children: [
                        _posTableHeaderCell('Size', width: 100),
                        _posTableHeaderCell('Entry Px', width: 100),
                        _posTableHeaderCell('Mark Px', width: 100),
                        _posTableHeaderCell('Liq. Px', width: 100),
                        _posTableHeaderCell('Unreal. PnL', width: 110),
                        _posTableHeaderCell('Margin', width: 90),
                      ]),
                    ),
                    ...positions.map((pos) {
                      final pnlPos = pos.unrealizedPnl >= 0;
                      final pnlColor = pnlPos ? AppColors.trendGreen : AppColors.trendRed;
                      return Container(
                        height: 56,
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
                        ),
                        child: Row(children: [
                          SizedBox(
                            width: 100,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(pos.size.toStringAsFixed(3),
                                  style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                Text('\$${_fmtNum(pos.size * pos.markPx)}',
                                  style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 9),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 100, child: Text('\$${_fmtNum(pos.entryPx)}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: 11),
                          )),
                          SizedBox(width: 100, child: Text('\$${_fmtNum(pos.markPx)}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: 11),
                          )),
                          SizedBox(width: 100, child: Text(
                            pos.liqPx <= 0 ? '—' : '\$${_fmtNum(pos.liqPx)}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.jetBrainsMono(
                              color: pos.liqPx > 0 ? AppColors.trendRed.withOpacity(0.8) : AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          )),
                          SizedBox(
                            width: 110,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${pnlPos ? '+' : ''}\$${pos.unrealizedPnl.toStringAsFixed(2)}',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.jetBrainsMono(color: pnlColor, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                Text('${pnlPos ? '+' : ''}${pos.unrealizedPnlPct.toStringAsFixed(2)}%',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.jetBrainsMono(color: pnlColor.withOpacity(0.7), fontSize: 9),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 90, child: Text('\$${pos.marginUsed.toStringAsFixed(2)}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 11),
                          )),
                        ]),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ── Pagination ──
        if (totalPages > 1) ...[
          const SizedBox(height: 4),
          const Divider(color: AppColors.surfaceBright, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // "Showing X–Y of Z"
                Text(
                  'Showing ${start + 1}–$end of ${allPositions.length}',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                // Page buttons
                Row(
                  children: [
                    // Prev
                    _posPageBtn(
                      icon: Icons.chevron_left,
                      isEnabled: _positionsPage > 1,
                      isActive: false,
                      onTap: () => setState(() => _positionsPage--),
                    ),
                    const SizedBox(width: 6),
                    // Numbered pages (show up to 3 around current)
                    ...() {
                      int pStart = (_positionsPage - 1).clamp(1, totalPages);
                      int pEnd = (pStart + 2).clamp(1, totalPages);
                      if (pEnd == totalPages && totalPages > 3) pStart = pEnd - 2;
                      List<Widget> btns = [];
                      for (int i = pStart; i <= pEnd; i++) {
                        btns.add(Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: _posPageBtn(
                            text: '$i',
                            isActive: i == _positionsPage,
                            isEnabled: true,
                            onTap: () => setState(() => _positionsPage = i),
                          ),
                        ));
                      }
                      return btns;
                    }(),
                    const SizedBox(width: 6),
                    // Next
                    _posPageBtn(
                      icon: Icons.chevron_right,
                      isEnabled: _positionsPage < totalPages,
                      isActive: false,
                      onTap: () => setState(() => _positionsPage++),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else
          const SizedBox(height: 8),
      ],
    );
  }

  Widget _posPageBtn({
    String? text,
    IconData? icon,
    required bool isActive,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.35,
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? AppColors.brandAccent : AppColors.background,
            border: Border.all(
              color: isActive ? AppColors.brandAccent : AppColors.surfaceBright,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: text != null
              ? Text(
                  text,
                  style: GoogleFonts.jetBrainsMono(
                    color: isActive ? Colors.black : AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                )
              : Icon(
                  icon,
                  size: 14,
                  color: AppColors.textPrimary,
                ),
        ),
      ),
    );
  }

  Widget _posAssetCell(dynamic pos) {
    final isLong = pos.side.toLowerCase() == 'long';
    final sideColor = isLong ? AppColors.trendGreen : AppColors.trendRed;
    return Container(
      height: 56,
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(pos.coin, style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: sideColor.withOpacity(0.12), borderRadius: BorderRadius.circular(2)),
                child: Text(pos.side.toUpperCase(), style: GoogleFonts.jetBrainsMono(color: sideColor, fontSize: 7, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: AppColors.brandAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(2)),
                child: Text('${pos.leverage.toInt()}x', style: GoogleFonts.jetBrainsMono(color: AppColors.brandAccent, fontSize: 7, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _posTableHeaderCell(String label, {required double width, Alignment align = Alignment.center, double leftPad = 0}) {
    return Container(
      width: width,
      height: 48,
      padding: EdgeInsets.only(left: leftPad),
      alignment: align,
      child: Text(label, textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 11)),
    );
  }

  // ─── FILLS TABLE ────────────────────────────────────────────────────────────

  Widget _buildDetailedTradeHistory(PortfolioViewModel vm) {
    final allFills = vm.historyFills;
    if (allFills.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: Text('No Recent Fills', style: TextStyle(color: Colors.white24))),
      );
    }

    final int totalPages = (allFills.length / _fillsPerPage).ceil();
    final int start = (_fillsPage - 1) * _fillsPerPage;
    final int end = (start + _fillsPerPage).clamp(0, allFills.length);
    final fills = allFills.sublist(start, end);

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Column(
                children: [
                  _posTableHeaderCell('Time / Asset', width: 140, align: Alignment.centerLeft, leftPad: 16),
                  ...fills.map((f) => _fillAssetCell(f)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Row(children: [
                        _posTableHeaderCell('Side', width: 80),
                        _posTableHeaderCell('Price', width: 110),
                        _posTableHeaderCell('Size', width: 100),
                        _posTableHeaderCell('Closed PnL', width: 110),
                        _posTableHeaderCell('Fee', width: 80),
                      ]),
                    ),
                    ...fills.map((f) {
                      final isPos = f.closedPnl > 0;
                      final pnlColor = isPos ? AppColors.trendGreen : (f.closedPnl < 0 ? AppColors.trendRed : AppColors.textSecondary);
                      final isBuy = f.dir.toLowerCase().contains('buy') || f.dir.toLowerCase().contains('long');
                      final sideColor = isBuy ? AppColors.trendGreen : AppColors.trendRed;
                      final sideLabel = isBuy ? 'BUY' : 'SELL';
                      return Container(
                        height: 56,
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5))),
                        child: Row(children: [
                          SizedBox(width: 80, child: Center(child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: sideColor.withOpacity(0.12), borderRadius: BorderRadius.circular(2)),
                            child: Text(sideLabel, style: GoogleFonts.jetBrainsMono(color: sideColor, fontSize: 9, fontWeight: FontWeight.bold)),
                          ))),
                          SizedBox(width: 110, child: Text('\$${_fmtNum(f.px)}', textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: 11))),
                          SizedBox(width: 100, child: Text(f.sz.toStringAsFixed(4), textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: 11))),
                          SizedBox(width: 110, child: Text('${isPos ? '+' : ''}\$${f.closedPnl.toStringAsFixed(2)}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.jetBrainsMono(color: pnlColor, fontSize: 11, fontWeight: FontWeight.bold),
                          )),
                          SizedBox(width: 80, child: Text('\$${f.fee.toStringAsFixed(3)}', textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 11))),
                        ]),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (totalPages > 1) ...[
          const SizedBox(height: 4),
          const Divider(color: AppColors.surfaceBright, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${start + 1}–$end of ${allFills.length}',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                Row(
                  children: [
                    _posPageBtn(
                      icon: Icons.chevron_left,
                      isEnabled: _fillsPage > 1,
                      isActive: false,
                      onTap: () => setState(() => _fillsPage--),
                    ),
                    const SizedBox(width: 6),
                    ...() {
                      int pStart = (_fillsPage - 1).clamp(1, totalPages);
                      int pEnd = (pStart + 2).clamp(1, totalPages);
                      if (pEnd == totalPages && totalPages > 3) pStart = pEnd - 2;
                      List<Widget> btns = [];
                      for (int i = pStart; i <= pEnd; i++) {
                        btns.add(Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: _posPageBtn(
                            text: '$i',
                            isActive: i == _fillsPage,
                            isEnabled: true,
                            onTap: () => setState(() => _fillsPage = i),
                          ),
                        ));
                      }
                      return btns;
                    }(),
                    const SizedBox(width: 6),
                    _posPageBtn(
                      icon: Icons.chevron_right,
                      isEnabled: _fillsPage < totalPages,
                      isActive: false,
                      onTap: () => setState(() => _fillsPage++),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else
          const SizedBox(height: 8),
      ],
    );
  }

  Widget _fillAssetCell(dynamic f) {
    final time = DateTime.fromMillisecondsSinceEpoch(f.time);
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final dateStr = '${time.day}/${time.month}';
    return Container(
      height: 56,
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(f.coin, style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          Text('$dateStr  $timeStr', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 9)),
        ],
      ),
    );
  }

  // ─── ORDERS TABLE ───────────────────────────────────────────────────────────

  Widget _buildDetailedOrders(dynamic s) {
    final allOrders = s.openOrders as List;
    if (allOrders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: Text('No Open Orders', style: TextStyle(color: Colors.white24))),
      );
    }

    final int totalPages = (allOrders.length / _ordersPerPage).ceil();
    final int start = (_ordersPage - 1) * _ordersPerPage;
    final int end = (start + _ordersPerPage).clamp(0, allOrders.length);
    final orders = allOrders.sublist(start, end);

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Column(
                children: [
                  _posTableHeaderCell('Asset', width: 120, align: Alignment.centerLeft, leftPad: 16),
                  ...orders.map((o) {
                    final isBuy = o.side.toLowerCase().contains('buy');
                    final sideColor = isBuy ? AppColors.trendGreen : AppColors.trendRed;
                    return Container(
                      height: 56,
                      width: 120,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(o.coin, style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(color: sideColor.withOpacity(0.12), borderRadius: BorderRadius.circular(2)),
                            child: Text(o.side.toUpperCase(), style: GoogleFonts.jetBrainsMono(color: sideColor, fontSize: 7, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Row(children: [
                        _posTableHeaderCell('Type', width: 90),
                        _posTableHeaderCell('Size', width: 100),
                        _posTableHeaderCell('Limit Price', width: 110),
                      ]),
                    ),
                    ...orders.map((o) => Container(
                      height: 56,
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5))),
                      child: Row(children: [
                        SizedBox(width: 90, child: Text(o.orderType, textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 11))),
                        SizedBox(width: 100, child: Text(o.size.toStringAsFixed(4), textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: 11))),
                        SizedBox(width: 110, child: Text('\$${_fmtNum(o.limitPx)}', textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold))),
                      ]),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (totalPages > 1) ...[
          const SizedBox(height: 4),
          const Divider(color: AppColors.surfaceBright, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${start + 1}–$end of ${allOrders.length}',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                Row(
                  children: [
                    _posPageBtn(
                      icon: Icons.chevron_left,
                      isEnabled: _ordersPage > 1,
                      isActive: false,
                      onTap: () => setState(() => _ordersPage--),
                    ),
                    const SizedBox(width: 6),
                    ...() {
                      int pStart = (_ordersPage - 1).clamp(1, totalPages);
                      int pEnd = (pStart + 2).clamp(1, totalPages);
                      if (pEnd == totalPages && totalPages > 3) pStart = pEnd - 2;
                      List<Widget> btns = [];
                      for (int i = pStart; i <= pEnd; i++) {
                        btns.add(Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: _posPageBtn(
                            text: '$i',
                            isActive: i == _ordersPage,
                            isEnabled: true,
                            onTap: () => setState(() => _ordersPage = i),
                          ),
                        ));
                      }
                      return btns;
                    }(),
                    const SizedBox(width: 6),
                    _posPageBtn(
                      icon: Icons.chevron_right,
                      isEnabled: _ordersPage < totalPages,
                      isActive: false,
                      onTap: () => setState(() => _ordersPage++),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else
          const SizedBox(height: 8),
      ],
    );
  }

  // ─── SPOT BALANCES TABLE ─────────────────────────────────────────────────────

  Widget _buildDetailedSpotBalances(dynamic s) {
    final allBalances = s.spotBalances as List;
    if (allBalances.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: Text('No Spot Balances', style: TextStyle(color: Colors.white24))),
      );
    }

    final int totalPages = (allBalances.length / _spotPerPage).ceil();
    final int start = (_spotPage - 1) * _spotPerPage;
    final int end = (start + _spotPerPage).clamp(0, allBalances.length);
    final balances = allBalances.sublist(start, end);

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Column(
                children: [
                  _posTableHeaderCell('Asset', width: 130, align: Alignment.centerLeft, leftPad: 16),
                  ...balances.map((b) => Container(
                    height: 56,
                    width: 130,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5))),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(b.iconUrl, width: 20, height: 20, errorBuilder: (_, __, ___) => Container(width: 20, height: 20, decoration: BoxDecoration(color: AppColors.surfaceBright, shape: BoxShape.circle), child: Center(child: Text(b.coin[0], style: const TextStyle(color: Colors.white, fontSize: 9))))),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(b.coin, style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Row(children: [
                        _posTableHeaderCell('Amount', width: 110),
                        _posTableHeaderCell('USD Value', width: 110),
                        _posTableHeaderCell('Allocation', width: 160),
                      ]),
                    ),
                    ...balances.map((b) => Container(
                      height: 56,
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5))),
                      child: Row(children: [
                        SizedBox(width: 110, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(b.total.toStringAsFixed(4), textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                          if (b.hold > 0) Text('${b.hold.toStringAsFixed(3)} held', textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 8)),
                        ])),
                        SizedBox(width: 110, child: Text('\$${b.usdValue.toStringAsFixed(2)}', textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: 11))),
                        SizedBox(
                          width: 160,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: (b.allocationPct / 100).clamp(0.0, 1.0),
                                  backgroundColor: AppColors.surfaceBright,
                                  color: AppColors.trendGreen,
                                  minHeight: 3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text('${b.allocationPct.toStringAsFixed(1)}%', textAlign: TextAlign.center, style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 9)),
                            ]),
                          ),
                        ),
                      ]),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (totalPages > 1) ...[
          const SizedBox(height: 4),
          const Divider(color: AppColors.surfaceBright, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${start + 1}–$end of ${allBalances.length}',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                Row(
                  children: [
                    _posPageBtn(
                      icon: Icons.chevron_left,
                      isEnabled: _spotPage > 1,
                      isActive: false,
                      onTap: () => setState(() => _spotPage--),
                    ),
                    const SizedBox(width: 6),
                    ...() {
                      int pStart = (_spotPage - 1).clamp(1, totalPages);
                      int pEnd = (pStart + 2).clamp(1, totalPages);
                      if (pEnd == totalPages && totalPages > 3) pStart = pEnd - 2;
                      List<Widget> btns = [];
                      for (int i = pStart; i <= pEnd; i++) {
                        btns.add(Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: _posPageBtn(
                            text: '$i',
                            isActive: i == _spotPage,
                            isEnabled: true,
                            onTap: () => setState(() => _spotPage = i),
                          ),
                        ));
                      }
                      return btns;
                    }(),
                    const SizedBox(width: 6),
                    _posPageBtn(
                      icon: Icons.chevron_right,
                      isEnabled: _spotPage < totalPages,
                      isActive: false,
                      onTap: () => setState(() => _spotPage++),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else
          const SizedBox(height: 8),
      ],
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────────

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(text, style: GoogleFonts.inter(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

}

/// Draws Y-axis labels on a fixed-width column that stays outside the
/// horizontally-scrollable chart area.
class _YAxisPainter extends CustomPainter {
  final double yMin;
  final double yMax;
  final double interval;

  _YAxisPainter({
    required this.yMin,
    required this.yMax,
    required this.interval,
  });

  static String _fmt(double v) {
    final abs = v.abs();
    if (abs >= 1000000) {
      final m = v / 1000000;
      return '\$${m.toStringAsFixed(m.truncateToDouble() == m ? 0 : 2)}M';
    }
    if (abs >= 1000) {
      final k = v / 1000;
      return '\$${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}K';
    }
    return '\$${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1)}';
  }

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(textDirection: TextDirection.ltr);
    final range = yMax - yMin;
    if (range <= 0 || interval <= 0) return;

    final steps = (range / interval).floor().clamp(1, 10);
    for (int i = 0; i <= steps; i++) {
      final value = yMin + i * interval;
      // Skip if value exceeds yMax too much
      if (value > yMax + (interval * 0.1)) break;

      final frac = (value - yMin) / range;
      const bottomReserve = 40.0;
      
      // Calculate Y: (H - reserve) is the bottom. Subtracting (frac * height) moves it up.
      final chartHeight = size.height - bottomReserve;
      final y = chartHeight - (frac * chartHeight);

      tp.text = TextSpan(
        text: _fmt(value),
        style: const TextStyle(
          color: Color(0x88FFFFFF),
          fontSize: 10,
          fontFamily: 'JetBrainsMono',
          fontWeight: FontWeight.w500,
        ),
      );
      tp.layout(maxWidth: 54);
      tp.paint(canvas, Offset(4, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_YAxisPainter old) =>
      old.yMin != yMin || old.yMax != yMax || old.interval != interval;
}

class _CandlestickChartPainter extends CustomPainter {
  final List<OhlcSnapshot> data;
  final double yMin;
  final double yMax;
  final double candleWidth;

  _CandlestickChartPainter({
    required this.data,
    required this.yMin,
    required this.yMax,
    required this.candleWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final range = yMax - yMin;
    if (range <= 0 || data.isEmpty) return;

    const dateLabelH = 24.0;
    const topPad = 4.0;
    final chartHeight = size.height - dateLabelH - topPad;
    final n = data.length;
    final double totalWidth = n * (candleWidth + 4);
    final double startX = (size.width - totalWidth) / 2;

    for (int i = 0; i < n; i++) {
      final s = data[i];
      final x = startX + i * (candleWidth + 4) + candleWidth / 2;

      double yPrice(double price) {
        final frac = (price - yMin) / range;
        return chartHeight - (frac * chartHeight) + topPad;
      }

      final yHigh = yPrice(s.high);
      final yLow = yPrice(s.low);
      final yOpen = yPrice(s.open);
      final yClose = yPrice(s.close);

      final isBull = s.close >= s.open;
      final bodyColor = isBull
          ? const Color(0xFF22C55E)
          : const Color(0xFFEF4444);

      // Draw wick
      canvas.drawLine(
        Offset(x, yHigh),
        Offset(x, yLow),
        Paint()
          ..color = bodyColor.withOpacity(0.8)
          ..strokeWidth = 1.2,
      );

      // Draw body
      final bodyTop = isBull ? yClose : yOpen;
      final bodyBottom = isBull ? yOpen : yClose;
      final bodyHeight = (bodyBottom - bodyTop).clamp(1.0, double.infinity);

      canvas.drawRect(
        Rect.fromLTRB(
          x - candleWidth / 2 + 1,
          bodyTop,
          x + candleWidth / 2 - 1,
          bodyTop + bodyHeight,
        ),
        Paint()..color = bodyColor,
      );
    }

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;
    for (int i = 0; i <= 5; i++) {
      final y = chartHeight * (1 - i / 5) + topPad;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Date labels
    final labelStep = n <= 10 ? 1 : (n / 7).ceil();
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    for (int i = 0; i < n; i += labelStep) {
      final d = DateTime.fromMillisecondsSinceEpoch(data[i].timestamp);
      final label = '${d.day}/${d.month}';
      final x = startX + i * (candleWidth + 4) + candleWidth / 2;
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, chartHeight + topPad + 4),
      );
    }
  }

  @override
  bool shouldRepaint(_CandlestickChartPainter old) =>
      old.data != data || old.yMin != yMin || old.yMax != yMax;
}

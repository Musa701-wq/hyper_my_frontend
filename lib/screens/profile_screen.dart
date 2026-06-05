import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../viewmodels/portfolio_viewmodel.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/shimmer_skeleton.dart';

class ProfileScreen extends StatefulWidget {
  final String walletAddress;

  const ProfileScreen({
    super.key, 
    this.walletAddress = '0x31ca8395cf837de08b24da3f660e77761dfb974b',
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _hideValue = false;
  int _selectedChartTabIndex = 0; // 0: Combined, 1: Perp, 2: Account Value
  int _selectedDetailedTabIndex = 0; // 0: Assets, 1: Orders, 2: Fills, 3: Spot
  
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
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<PortfolioViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading && !vm.hasData) {
            return _buildPortfolioShimmer(res);
          }

          if (vm.error != null && !vm.hasData) {
            return ErrorStateWidget(
              errorMessage: vm.error!,
              onRetry: () => vm.fetchPortfolio(widget.walletAddress),
            );
          }

          if (!vm.hasData) {
            return const Center(child: Text('No data found', style: TextStyle(color: Colors.white)));
          }

          final s = vm.summary!;

          return RefreshIndicator(
            color: AppColors.brandAccent,
            onRefresh: () => vm.fetchPortfolio(widget.walletAddress),
            child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: res.horizontalPadding(16),
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDynamicHeader(res, widget.walletAddress),
                if (vm.isRefreshing) ...[
                  const SizedBox(height: 8),
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
                ],
                const SizedBox(height: 24),
                _buildSummaryCards(res, s),
                const SizedBox(height: 32),
                _buildChartsSection(res, s, vm),
                const SizedBox(height: 24),
                _buildPortfolioTabsSection(res, s, vm),
                const SizedBox(height: 60),
              ],
            ),
          ),
          );
        },
      ),
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

  Widget _buildDynamicHeader(Responsive res, String wallet) {
    final String initial = wallet.length > 2 ? wallet[2].toUpperCase() : 'W';
    final String shortId = '0x${wallet.substring(2, 6)}...${wallet.substring(wallet.length - 4)}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.purpleAccent,
                shape: BoxShape.circle,
              ),
              child: Center(child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back,', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
                Text('Trader $shortId', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        Row(
          children: [
            _headerIconButton(_hideValue ? Icons.visibility_off_outlined : Icons.visibility_outlined, onTap: () => setState(() => _hideValue = !_hideValue)),
            const SizedBox(width: 12),
            _headerIconButton(Icons.notifications_none, hasDot: true),
          ],
        ),
      ],
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
    return GridView.count(
      crossAxisCount: res.gridColumnCount(mobile: 2, tablet: 2, desktop: 4),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildDesignCard('ACCOUNT VALUE', s.totalBalance, '', Icons.account_balance_wallet, Colors.tealAccent),
        _buildDesignCard('WITHDRAWABLE', s.withdrawable, '', Icons.account_balance, Colors.blueAccent),
        _buildDesignCard('UNREALIZED PNL', s.unrealizedPnl, '${s.unrealizedPnlPct.toStringAsFixed(2)}%', Icons.show_chart, AppColors.trendRed),
        _buildDesignCard('WALLET', s.walletAddress, 'Live', Icons.qr_code_scanner, Colors.purpleAccent, isWallet: true),
      ],
    );
  }

  Widget _buildDesignCard(String title, dynamic value, String trend, IconData icon, Color accent, {bool isWallet = false}) {
     String displayValue = isWallet 
        ? '0x${value.substring(2, 6)}...${value.substring(value.length - 4)}'
        : '\$${value.toStringAsFixed(2)}';
     
     if (_hideValue && !isWallet) displayValue = '****';

     return Container(
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
         color: AppColors.surfaceBright.withOpacity(0.2),
         borderRadius: BorderRadius.circular(20),
         border: Border.all(color: Colors.white.withOpacity(0.05)),
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Text(title, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
               Container(
                 padding: const EdgeInsets.all(6),
                 decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                 child: Icon(icon, color: accent, size: 16),
               ),
             ],
           ),
           Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(displayValue, style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
               const SizedBox(height: 4),
               Row(
                 children: [
                    if (!isWallet) Icon(trend.contains('-') ? Icons.arrow_drop_down : Icons.arrow_drop_up, color: trend.contains('-') ? AppColors.trendRed : AppColors.trendGreen, size: 14),
                    if (isWallet) Container(width: 6, height: 6, decoration: BoxDecoration(color: AppColors.trendGreen, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(trend, style: GoogleFonts.inter(color: trend.contains('-') ? AppColors.trendRed : AppColors.trendGreen, fontSize: 10, fontWeight: FontWeight.w500)),
                 ],
               ),
             ],
           ),
         ],
       ),
     );
  }

  Widget _buildChartsSection(Responsive res, dynamic s, PortfolioViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IntrinsicWidth(
            child: Row(
              children: [
                 _chartTab('Combined PnL', active: _selectedChartTabIndex == 0, onTap: () => setState(() => _selectedChartTabIndex = 0)),
                 _chartTab('Perp PnL', active: _selectedChartTabIndex == 1, onTap: () => setState(() => _selectedChartTabIndex = 1)),
                 _chartTab('Account Value', active: _selectedChartTabIndex == 2, onTap: () => setState(() => _selectedChartTabIndex = 2)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildFullPnLChart(res, s, vm),
        const SizedBox(height: 24),
        // Treemap now takes full width
        _buildChartContainer('Asset Composition', '', '', _buildAssetTreemap(s, vm), hasDropdown: true, detailLabel: '(${vm.assetComposition.length} Assets total)'),
      ],
    );
  }

  Widget _buildPortfolioTabsSection(Responsive res, dynamic s, PortfolioViewModel vm) {
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
          _buildDetailTabs(s, vm),
          const Divider(color: Colors.white10, height: 1),
          _buildSelectedTable(res, s, vm),
        ],
      ),
    );
  }

  Widget _buildDetailTabs(dynamic s, PortfolioViewModel vm) {
    final tabs = [
      {'label': 'Asset Positions', 'count': '${(s.positions as List).length}'},
      {'label': 'Open Orders', 'count': '${(s.openOrders as List).length}'},
      {'label': 'Recent Fills', 'count': '${vm.historyFills.length}'},
      {'label': 'Spot Balances', 'count': '${(s.spotBalances as List).length}'},
      {'label': 'Staking', 'count': '0'},
      {'label': 'Compared Trades', 'count': null},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final isSelected = _selectedDetailedTabIndex == entry.key;
          return GestureDetector(
            onTap: () => setState(() => _selectedDetailedTabIndex = entry.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isSelected ? Colors.blueAccent : Colors.transparent, width: 2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.value['label']!,
                    style: GoogleFonts.inter(
                      color: isSelected ? Colors.white : Colors.white54,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (entry.value['count'] != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        entry.value['count']!,
                        style: GoogleFonts.jetBrainsMono(color: Colors.white38, fontSize: 10),
                      ),
                    ),
                  ],
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

  Widget _buildFullPnLChart(Responsive res, dynamic s, PortfolioViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildTimeRangeDropdown(vm),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 250,
            child: _buildMainLineChart(_getSelectedSeries(vm), vm.historyTimestamps),
          ),
          const SizedBox(height: 32),
          const Divider(color: Colors.white10),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _chartMetric('CURRENT VALUE', '\$${s.totalBalance.toStringAsFixed(2)}'),
              _chartMetric('TRADE VOLUME', '\$${vm.currentVolume >= 1000000 ? (vm.currentVolume / 1000000).toStringAsFixed(1) + 'M' : (vm.currentVolume / 1000).toStringAsFixed(1) + 'K'}'),
              _chartMetric('ALL CHANGE', '${vm.allChange >= 0 ? '+' : ''}\$${vm.allChange.toStringAsFixed(2)}', color: vm.allChange >= 0 ? AppColors.trendGreen : AppColors.trendRed),
            ],
          ),
        ],
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

  Widget _buildTimeRangeDropdown(PortfolioViewModel vm) {
    return Container(
      height: 32, // Controlled height
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PortfolioTimeRange>(
          value: vm.selectedRange,
          dropdownColor: AppColors.surfaceBright,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.blueAccent, size: 14),
          style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          onChanged: (range) {
            if (range != null) vm.setTimeRange(range);
          },
          items: [
            _timeDropdownItem(PortfolioTimeRange.hour, 'H'),
            _timeDropdownItem(PortfolioTimeRange.day, 'D'),
            _timeDropdownItem(PortfolioTimeRange.week, 'W'),
            _timeDropdownItem(PortfolioTimeRange.month, 'M'),
            _timeDropdownItem(PortfolioTimeRange.year, 'Y'),
            _timeDropdownItem(PortfolioTimeRange.all, 'ALL'),
          ],
        ),
      ),
    );
  }

  DropdownMenuItem<PortfolioTimeRange> _timeDropdownItem(PortfolioTimeRange range, String label) {
    return DropdownMenuItem(
      value: range,
      child: Text(label),
    );
  }

  Widget _chartTab(String label, {bool active = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.surfaceBright : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label, 
          style: GoogleFonts.jetBrainsMono(
            color: active ? AppColors.brandAccent : AppColors.textSecondary, 
            fontSize: 11, 
            fontWeight: active ? FontWeight.bold : FontWeight.normal
          )
        ),
      ),
    );
  }

  // _timeFilter is no longer used, but I'll remove it or keep it if it's used elsewhere. 
  // It seems it was only used in _buildFullPnLChart.

  Widget _chartMetric(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.jetBrainsMono(color: color ?? Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMainLineChart(List<double> pnlData, List<int> timestamps) {
    if (pnlData.isEmpty || timestamps.isEmpty) return const Center(child: Text('No data', style: TextStyle(color: Colors.white24)));
    
    // Convert data to spots
    List<FlSpot> spots = [];
    for (int i = 0; i < pnlData.length; i++) {
        spots.add(FlSpot(i.toDouble(), pnlData[i]));
    }

    final bool isAccountValue = _selectedChartTabIndex == 2;
    final bool isPos = pnlData.isNotEmpty && pnlData.last >= (pnlData.first);
    final themeColor = isAccountValue ? Colors.blueAccent : (isPos ? AppColors.trendGreen : AppColors.trendRed);

    double minVal = pnlData.reduce((a, b) => a < b ? a : b);
    double maxVal = pnlData.reduce((a, b) => a > b ? a : b);
    double range = maxVal - minVal;
    
    // Ensure some padding in range for smooth display
    double padding = range * 0.15;
    if (padding == 0) padding = 1000;
    
    double adjustedMin = minVal - padding;
    double adjustedMax = maxVal + padding;
    double interval = (adjustedMax - adjustedMin) / 4;
    if (interval <= 0) interval = 1000;

    return LineChart(
      LineChartData(
        minY: adjustedMin,
        maxY: adjustedMax,
        gridData: FlGridData(
           show: true,
           drawVerticalLine: false,
           horizontalInterval: interval,
           getDrawingHorizontalLine: (value) {
             return FlLine(color: Colors.white.withOpacity(0.03), strokeWidth: 1);
           },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: (pnlData.length / 4).clamp(1, double.maxFinite),
              getTitlesWidget: (value, _) {
                int index = value.toInt();
                if (index < 0 || index >= timestamps.length) return const SizedBox();
                
                final dt = DateTime.fromMillisecondsSinceEpoch(timestamps[index]);
                String label;
                
                // Format based on range
                if (pnlData.length <= 1) return const SizedBox();
                
                final duration = DateTime.fromMillisecondsSinceEpoch(timestamps.last).difference(DateTime.fromMillisecondsSinceEpoch(timestamps.first));
                
                if (duration.inDays > 30) {
                   label = '${dt.day} ${_getMonthName(dt.month)}';
                } else if (duration.inDays > 1) {
                   label = '${dt.day} ${_getMonthName(dt.month)}';
                } else {
                   label = '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
                }
                
                return _axisLabel(label);
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: interval,
              getTitlesWidget: (value, _) {
                 String label;
                double absVal = value.abs();
                if (absVal >= 1000000) {
                  label = '\$${(value/1000000).toStringAsFixed(1)}M';
                } else if (absVal >= 1000) {
                  label = '\$${(value/1000).toStringAsFixed(0)}k';
                } else {
                  label = '\$${value.toStringAsFixed(0)}';
                }
                return Text(label, style: TextStyle(color: AppColors.textSecondary.withOpacity(0.4), fontSize: 9));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: themeColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [themeColor.withOpacity(0.12), themeColor.withOpacity(0)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _axisLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(text, style: TextStyle(color: AppColors.textSecondary.withOpacity(0.3), fontSize: 9)),
    );
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

  Widget _buildAssetTreemap(dynamic s, PortfolioViewModel vm) {
    final items = vm.assetComposition;
    if (items.isEmpty) return const Center(child: Text('No data', style: TextStyle(color: Colors.white24)));

    const List<Color> greenShades = [
      Color(0xFF184E3D),
      Color(0xFF1B5845),
      Color(0xFF1F6650),
      Color(0xFF23755B),
      Color(0xFF288567),
      Color(0xFF2D9573),
      Color(0xFF32A680),
      Color(0xFF38B78D),
      Color(0xFF42C59B),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isOthers = item.coin == 'Others';
            
            // Simulation of CSS flex-basis and grid appearance
            double widthFactor;
            if (isOthers) {
              widthFactor = 1.0;
            } else if (item.percentage > 5) {
              widthFactor = 0.24; // 4 per row
            } else if (item.percentage > 2) {
              widthFactor = 0.15; // 6 per row
            } else {
              widthFactor = 0.115; // 8 per row
            }
            
            double itemWidth = (totalWidth - 40) * widthFactor; 
            if (isOthers) itemWidth = totalWidth;

            return Container(
              width: itemWidth,
              height: isOthers ? 120 : 80,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: greenShades[index % greenShades.length],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.coin.toUpperCase(), style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text('${item.percentage.toStringAsFixed(1)}%', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.5), fontSize: 9)),
                ],
              ),
            );
          }).toList(),
        );
      }
    );
  }

  // ─── PORTFOLIO TABLES (Home-screen style) ───────────────────────────────────

  Widget _buildDetailedPositions(Responsive res, dynamic s) {
    final positions = s.positions as List;
    if (positions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: Text('No Open Positions', style: TextStyle(color: Colors.white24))),
      );
    }

    return Row(
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
                // Header row
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
                // Data rows
                ...positions.map((pos) {
                  final isLong = pos.side.toLowerCase() == 'long';
                  final pnlPos = pos.unrealizedPnl >= 0;
                  final pnlColor = pnlPos ? AppColors.trendGreen : AppColors.trendRed;
                  return Container(
                    height: 56,
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
                    ),
                    child: Row(children: [
                      // Size
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
                      // Entry Px
                      SizedBox(width: 100, child: Text('\$${_fmtNum(pos.entryPx)}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: 11),
                      )),
                      // Mark Px
                      SizedBox(width: 100, child: Text('\$${_fmtNum(pos.markPx)}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: 11),
                      )),
                      // Liq. Px
                      SizedBox(width: 100, child: Text(
                        pos.liqPx <= 0 ? '—' : '\$${_fmtNum(pos.liqPx)}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.jetBrainsMono(color: pos.liqPx > 0 ? AppColors.trendRed.withValues(alpha: 0.8) : AppColors.textSecondary, fontSize: 11),
                      )),
                      // Unrealized PnL
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
                              style: GoogleFonts.jetBrainsMono(color: pnlColor.withValues(alpha: 0.7), fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                      // Margin
                      SizedBox(width: 90, child: Text('\$${pos.marginUsed.toStringAsFixed(2)}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 11),
                      )),
                    ]),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
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
                decoration: BoxDecoration(color: sideColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(2)),
                child: Text(pos.side.toUpperCase(), style: GoogleFonts.jetBrainsMono(color: sideColor, fontSize: 7, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2)),
                child: Text('${pos.leverage.toInt()}x', style: GoogleFonts.jetBrainsMono(color: Colors.blueAccent, fontSize: 7, fontWeight: FontWeight.bold)),
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
    final fills = vm.historyFills;
    if (fills.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: Text('No Recent Fills', style: TextStyle(color: Colors.white24))),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Column(
            children: [
              _posTableHeaderCell('Time / Asset', width: 140, align: Alignment.centerLeft, leftPad: 16),
              ...fills.take(50).map((f) => _fillAssetCell(f)),
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
                ...fills.take(50).map((f) {
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
                        decoration: BoxDecoration(color: sideColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(2)),
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
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
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
    final orders = s.openOrders as List;
    if (orders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: Text('No Open Orders', style: TextStyle(color: Colors.white24))),
      );
    }

    return Row(
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
                        decoration: BoxDecoration(color: sideColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(2)),
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
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── SPOT BALANCES TABLE ─────────────────────────────────────────────────────

  Widget _buildDetailedSpotBalances(dynamic s) {
    final balances = s.spotBalances as List;
    if (balances.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: Text('No Spot Balances', style: TextStyle(color: Colors.white24))),
      );
    }

    return Row(
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
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────────

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(text, style: GoogleFonts.inter(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  String _fmtNum(double val) {
    if (val >= 1000000) return '${(val / 1000000).toStringAsFixed(2)}M';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(2)}k';
    if (val >= 100) return val.toStringAsFixed(2);
    if (val >= 10) return val.toStringAsFixed(3);
    return val.toStringAsFixed(4);
  }
}

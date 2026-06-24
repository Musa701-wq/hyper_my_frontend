import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/app_colors.dart';
import '../utils/common_widgets.dart';
import '../utils/responsive.dart';
import '../viewmodels/defillama_viewmodel.dart';
import '../widgets/error_state_widget.dart';

// ─── Sub-protocol colors (only used in scope tabs / period table) ──
const Color kColorPerps = Color(0xFF0D9488);
const Color kColorSpot  = Color(0xFF7C3AED);

class DefiLlamaScreen extends StatefulWidget {
  const DefiLlamaScreen({super.key});
  @override
  State<DefiLlamaScreen> createState() => _DefiLlamaScreenState();
}

class _DefiLlamaScreenState extends State<DefiLlamaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DefiLlamaViewModel>().fetchAll();
    });
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
            child: const Icon(Icons.arrow_back, color: AppColors.brandAccent),
          ),
          title: Consumer<DefiLlamaViewModel>(
            builder: (_, vm, __) => Text(
              'Fees & Revenue: ${vm.tabLabel}',
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.brandAccent,
                fontSize: res.fontSize(16),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
        body: Consumer<DefiLlamaViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) return _buildLoading(res);
            if (vm.errorMessage.isNotEmpty) {
              return Padding(
                padding: EdgeInsets.only(top: res.spacing(40)),
                child: ErrorStateWidget(
                  errorMessage: vm.errorMessage,
                  onRetry: () => vm.fetchAll(),
                ),
              );
            }
            return _buildContent(vm, res);
          },
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  MAIN CONTENT
  // ════════════════════════════════════════════════════════════
  Widget _buildContent(DefiLlamaViewModel vm, Responsive res) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(res.spacing(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tabRow(vm, res),
            SizedBox(height: res.spacing(16)),

            _sectionLabel('OVERVIEW'),
            SizedBox(height: res.spacing(12)),
            _statCards(vm, res),
            SizedBox(height: res.spacing(12)),

            _allTimeChart(vm, res),
            SizedBox(height: res.spacing(16)),
            _chartDataTable(vm, res),
            SizedBox(height: res.spacing(20)),

            _sectionLabel('PERIOD BREAKDOWN'),
            SizedBox(height: res.spacing(8)),
            _periodBreakdownTable(vm, res),
            SizedBox(height: res.spacing(28)),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => SectionLabel(text: text);

  // ════════════════════════════════════════════════════════════
  //  TAB TOGGLE
  // ════════════════════════════════════════════════════════════
  Widget _tabRow(DefiLlamaViewModel vm, Responsive res) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.surfaceBright),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(children: [
          _tabPill('Fees',    vm.tab == 'fees',    () => vm.setTab('fees'),    res),
          _tabPill('Revenue', vm.tab == 'revenue', () => vm.setTab('revenue'), res),
        ]),
      ),
    );
  }

  Widget _tabPill(String title, bool active, VoidCallback onTap, Responsive res) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.surfaceBright : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(title,
            style: GoogleFonts.jetBrainsMono(
              color: active ? AppColors.brandAccent : AppColors.textSecondary,
              fontSize: res.fontSize(12),
              fontWeight: FontWeight.bold,
            )),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  AREA / BAR TOGGLE
  // ════════════════════════════════════════════════════════════
  Widget _chartToggle(String mode, void Function(String) onSet, Responsive res) {
    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBright),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _modePill('Area', mode == 'area', () => onSet('area'), res),
        _modePill('Bar',  mode == 'bar',  () => onSet('bar'),  res),
      ]),
    );
  }

  Widget _modePill(String label, bool active, VoidCallback onTap, Responsive res) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: res.spacing(10)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.surfaceBright : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(label,
          style: GoogleFonts.jetBrainsMono(
            color: active ? AppColors.brandAccent : AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          )),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  STAT CARDS — 3 per row, Profile-style with icons
  // ════════════════════════════════════════════════════════════
  Widget _statCards(DefiLlamaViewModel vm, Responsive res) {
    final change = vm.change1d;
    final isUp = change >= 0;
    return Row(
      children: [
        Expanded(child: _profileStatCard(
          title: '24H',
          value: vm.fmtCompact(vm.stat24h),
          icon: Icons.trending_up,
          accent: AppColors.brandAccent,
          badge: vm.fmtPct(change),
          badgeUp: isUp,
        )),
        SizedBox(width: res.spacing(10)),
        Expanded(child: _profileStatCard(
          title: '7D',
          value: vm.fmtCompact(vm.stat7d),
          icon: Icons.date_range,
          accent: AppColors.brandAccent,
        )),
        SizedBox(width: res.spacing(10)),
        Expanded(child: _profileStatCard(
          title: 'ALL TIME',
          value: vm.fmtCompact(vm.statAllTime),
          icon: Icons.history,
          accent: AppColors.brandAccent,
        )),
      ],
    );
  }

  Widget _profileStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accent,
    String? badge,
    bool badgeUp = true,
  }) {
    return Container(
      padding: EdgeInsets.all(responsive(context).spacing(12)),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.2),
        borderRadius: BorderRadius.circular(responsive(context).value(mobile: 16, tablet: 14, desktop: 20)),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: responsive(context).value(mobile: 9, tablet: 8, desktop: 10),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                )),
              Container(
                padding: EdgeInsets.all(responsive(context).value(mobile: 6, tablet: 4, desktop: 6)),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accent,
                  size: responsive(context).value(mobile: 14, tablet: 12, desktop: 16)),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: responsive(context).value(mobile: 16, tablet: 13, desktop: 16),
                    fontWeight: FontWeight.bold,
                  )),
              ),
              if (badge != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(badgeUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      color: badgeUp ? AppColors.trendGreen : AppColors.trendRed,
                      size: responsive(context).value(mobile: 14, tablet: 11, desktop: 14)),
                    const SizedBox(width: 2),
                    Text(badge,
                      style: GoogleFonts.inter(
                        color: badgeUp ? AppColors.trendGreen : AppColors.trendRed,
                        fontSize: responsive(context).value(mobile: 10, tablet: 8, desktop: 10),
                        fontWeight: FontWeight.w500,
                      )),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Responsive responsive(BuildContext context) => Responsive(context);

  // ════════════════════════════════════════════════════════════
  //  SCOPE TABS  — All / Perps / Spot / HLP  (OHLC-style)
  // ════════════════════════════════════════════════════════════
  Widget _scopeTabRow(DefiLlamaViewModel vm, Responsive res) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: ChartScope.values.map((s) {
          final isSelected = vm.chartScope == s;
          return Expanded(
            child: GestureDetector(
              onTap: () => vm.setChartScope(s),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s.label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jetBrainsMono(
                    color: isSelected ? Colors.black : AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  RANGE DROPDOWN — 1D / 1W / 1M / 1Y
  // ════════════════════════════════════════════════════════════
  Widget _rangeDropdown(DefiLlamaViewModel vm, Responsive res) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.surfaceBright),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: AppColors.background,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<ChartRange>(
            value: vm.chartRange,
            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 14),
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.brandAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            padding: EdgeInsets.zero,
            dropdownColor: AppColors.background,
            onChanged: (ChartRange? r) {
              if (r != null) vm.setChartRange(r);
            },
            items: ChartRange.values.map((r) {
              return DropdownMenuItem<ChartRange>(
                value: r,
                child: Text(r.label),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  ALL-TIME DAILY CHART  — scrollable, latest data on right
  // ════════════════════════════════════════════════════════════
  Widget _allTimeChart(DefiLlamaViewModel vm, Responsive res) {
    if (vm.isChartLoading) {
      return Shimmer.fromColors(
        baseColor: const Color(0xFF1E222D),
        highlightColor: const Color(0xFF2E3340),
        period: const Duration(milliseconds: 1400),
        child: Container(
          height: 320,
          decoration: BoxDecoration(
            color: AppColors.surfaceBright.withOpacity(0.1),
            border: Border.all(color: AppColors.surfaceBright.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    }

    final spots = vm.chartSpots;
    final dates = vm.chartDates;
    if (spots.isEmpty) return _emptyBox(res, 320);

    final n          = spots.length;
    final scopeColor = vm.chartScope.color;

    // Available width after subtracting page padding
    final screenW = MediaQuery.of(context).size.width - res.spacing(24);

    // Fixed Y-axis column width
    const yAxisW = 56.0;

    // Scrollable area width (screen minus Y-axis)
    final scrollAreaW = screenW - yAxisW;

    // Compute canvas width based on range:
    final double pxPerBar;
    switch (vm.chartRange) {
      case ChartRange.daily:
        pxPerBar = (scrollAreaW / 365).clamp(3.0, 10.0).toDouble();
        break;
      case ChartRange.weekly:
        pxPerBar = (scrollAreaW / 52).clamp(12.0, 36.0).toDouble();
        break;
      case ChartRange.monthly:
        pxPerBar = (scrollAreaW / 12).clamp(40.0, 80.0).toDouble();
        break;
      case ChartRange.yearly:
        pxPerBar = scrollAreaW;
        break;
    }

    final canvasW = (n * pxPerBar).clamp(scrollAreaW, scrollAreaW * 15).toDouble();

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DAILY ${vm.tabLabel.toUpperCase()}',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              _rangeDropdown(vm, res),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.06), height: 1, thickness: 1),
          const SizedBox(height: 12),
          _scopeTabRow(vm, res),
          const SizedBox(height: 16),
          SizedBox(
            height: 320,
            child: Stack(
              children: [
                _ChartWithPinnedYAxis(
                  height: 320,
                  yAxisW: yAxisW,
                  canvasW: canvasW,
                  yAxisWidget: _yAxisWidget(spots, scopeColor),
                  chartBuilder: (chartWidth) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: vm.chartMode == 'bar'
                        ? _barChart(spots, dates, scopeColor, res, chartWidth)
                        : _areaChart(spots, dates, scopeColor, res, chartWidth),
                  ),
                ),
                // Overlaid Controls (Grouped on right)
                Positioned(
                  top: 0,
                  right: 0,
                  child: _chartToggle(vm.chartMode, vm.setChartMode, res),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Standalone Y-axis widget — always visible, not scrolling
  Widget _yAxisWidget(List<FlSpot> spots, Color scopeColor) {
    final vals   = spots.map((s) => s.y).toList();
    final minY   = vals.reduce((a, b) => a < b ? a : b);
    final maxY   = vals.reduce((a, b) => a > b ? a : b);
    final range  = maxY - minY;
    final double interval = range > 0 ? range / 6 : (maxY > 0 ? maxY / 6 : 1.0);

    return LineChart(
      LineChartData(
        minX: 0, maxX: 1,
        minY: minY - interval * 0.2,
        maxY: maxY + interval * 0.2,
        clipData: const FlClipData.all(),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: const [FlSpot(0, 0), FlSpot(1, 0)],
            color: Colors.transparent, barWidth: 0,
            dotData: const FlDotData(show: false),
          ),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 54,
              interval: interval,
              getTitlesWidget: (v, meta) {
                if (v == meta.max || v == meta.min) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(_fmtY(v),
                    textAlign: TextAlign.right,
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 8.5,
                    )),
                );
              },
            ),
          ),
        ),
        lineTouchData: const LineTouchData(enabled: false),
      ),
      duration: Duration.zero,
    );
  }

  // ─── Area / Line ─────────────────────────────────────────────
  Widget _areaChart(
    List<FlSpot> spots, List<DateTime> dates, Color color, Responsive res,
    [double? canvasWidth]
  ) {
    final n    = spots.length;
    final vals = spots.map((s) => s.y).toList();
    final minY = vals.reduce((a, b) => a < b ? a : b);
    final maxY = vals.reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final double interval = range > 0 ? range / 6 : (maxY > 0 ? maxY / 6 : 1.0);
    final chartMinY = minY - interval * 0.2;
    final chartMaxY = maxY + interval * 0.2;
    final labelEvery = _labelEvery(n, canvasWidth);

    return LineChart(
      LineChartData(
        minX: 0, maxX: (n - 1).toDouble(),
        minY: chartMinY, maxY: chartMaxY,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true, drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.white.withOpacity(0.06), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: _axisTitles(n, dates, labelEvery, hideLeft: true),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceBright,
            tooltipRoundedRadius: 6,
            getTooltipItems: (touched) => touched.map((ts) {
              final idx = ts.x.toInt().clamp(0, dates.length - 1);
              return LineTooltipItem(
                '${_fmtY(ts.y)}\n${_dateStr(dates[idx])}',
                GoogleFonts.jetBrainsMono(
                  color: color, fontSize: 11, fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots, isCurved: true, curveSmoothness: 0.28,
            color: color, barWidth: 2, isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [color.withOpacity(0.22), color.withOpacity(0.0)],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 200),
    );
  }

  // ─── Bar chart ───────────────────────────────────────────────
  Widget _barChart(
    List<FlSpot> spots, List<DateTime> dates, Color color, Responsive res,
    [double? canvasWidth]
  ) {
    final n    = spots.length;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final interval = maxY > 0 ? maxY / 6 : 1.0;
    final labelEvery = _labelEvery(n, canvasWidth);
    final rodW = canvasWidth != null && n > 0
        ? (canvasWidth / n * 0.6).clamp(1.0, 12.0).toDouble()
        : (n > 300 ? 1.0 : n > 150 ? 1.6 : n > 60 ? 2.4 : 4.0);

    return BarChart(
      BarChartData(
        maxY: maxY + interval * 0.2,
        minY: 0,
        barGroups: spots.map((s) => BarChartGroupData(
          x: s.x.toInt(),
          barRods: [BarChartRodData(
            toY: s.y, color: color, width: rodW,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          )],
        )).toList(),
        gridData: FlGridData(
          show: true, drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.white.withOpacity(0.06), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: _axisTitles(n, dates, labelEvery, hideLeft: true),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceBright,
            direction: TooltipDirection.top,
            fitInsideVertically: true,
            fitInsideHorizontally: true,
            getTooltipItem: (group, _, rod, __) {
              final idx = group.x.clamp(0, dates.length - 1);
              return BarTooltipItem(
                '${_fmtY(rod.toY)}\n${_dateStr(dates[idx])}',
                GoogleFonts.jetBrainsMono(
                  color: color, fontSize: 11, fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
      ),
      duration: const Duration(milliseconds: 200),
    );
  }

  // How often to show a bottom-axis label — based on canvas width
  // Minimum ~55px per label to avoid overlap
  int _labelEvery(int n, double? canvasWidth) {
    if (n <= 1) return 1;
    final avail = canvasWidth ?? 300.0;
    final maxLabels = (avail / 55).floor().clamp(1, n);
    final every = (n / maxLabels).ceil();
    return every.clamp(1, n);
  }

  FlTitlesData _axisTitles(int n, List<DateTime> dates, int every,
      {bool hideLeft = false}) {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: !hideLeft, reservedSize: hideLeft ? 0 : 54),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true, reservedSize: 22,
          getTitlesWidget: (value, _) {
            final idx = value.toInt();
            if (idx < 0 || idx >= dates.length) return const SizedBox();
            if (idx % every != 0) return const SizedBox();
            final dt = dates[idx];
            // Format depends on density:
            // <=12 points (monthly/yearly)  → "Jun '25"
            // <=52 points (weekly)          → "14 Jun"
            // >52 points (daily/all)        → "Jun '25"
            final String label;
            if (n <= 1) {
              label = '${dt.year}';
            } else if (n <= 12) {
              label = '${_mon(dt.month)} \'${dt.year.toString().substring(2)}';
            } else if (n <= 52) {
              label = '${dt.day} ${_mon(dt.month)}';
            } else {
              label = '${_mon(dt.month)} \'${dt.year.toString().substring(2)}';
            }
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(label,
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white.withOpacity(0.38), fontSize: 8,
                )),
            );
          },
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  CHART DATA TABLE  (spot-balances style)
  // ════════════════════════════════════════════════════════════
  Widget _chartDataTable(DefiLlamaViewModel vm, Responsive res) {
    final rows = vm.paginatedTableRows;
    if (rows.isEmpty) return const SizedBox.shrink();

    final String dateHeader;
    switch (vm.chartRange) {
      case ChartRange.daily:   dateHeader = 'Date';  break;
      case ChartRange.weekly:  dateHeader = 'Week';  break;
      case ChartRange.monthly: dateHeader = 'Month'; break;
      case ChartRange.yearly:  dateHeader = 'Year';  break;
    }
    final scopeColor = vm.chartScope.color;

    final totalPages  = vm.tableTotalPages;
    final currentPage = vm.tablePage;
    final totalRows   = vm.chartSpots.length;
    final rowsPerPage = vm.tableRowsPerPage;
    final startRow = (currentPage - 1) * rowsPerPage + 1;
    final endRow   = (startRow + rowsPerPage - 1).clamp(1, totalRows);

    final tp = totalPages.clamp(1, totalPages);
    int pStart = (currentPage - 1).clamp(1, tp);
    int pEnd   = (pStart + 2).clamp(1, tp);
    if (pEnd == tp && tp > 3) pStart = pEnd - 2;

    return AppCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final colW = constraints.maxWidth / 2;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: colW,
                    child: Column(
                      children: [
                        _tableHeaderCell(dateHeader, width: colW, align: Alignment.centerLeft, leftPad: 16),
                        ...rows.map((row) => Container(
                          height: 52,
                          width: colW,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(vm.tableDateLabel(row.date),
                              style: GoogleFonts.jetBrainsMono(
                                color: AppColors.textPrimary, fontSize: 11,
                                fontWeight: FontWeight.w500,
                              )),
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
                              _tableHeaderCell(vm.tabLabel, width: colW),
                            ]),
                          ),
                          ...rows.map((row) => Container(
                            height: 52,
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5)),
                            ),
                            child: Row(children: [
                              SizedBox(
                                width: colW,
                                child: Text(vm.fmtCompact(row.value),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.jetBrainsMono(
                                    color: scopeColor, fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  )),
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
                const Divider(color: AppColors.surfaceBright, height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing $startRow\u2013$endRow of $totalRows',
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.textSecondary, fontSize: 10,
                        ),
                      ),
                      Row(
                        children: [
                          _pageBtn(icon: Icons.chevron_left, isEnabled: currentPage > 1, isActive: false,
                            onTap: () => vm.setTablePage(currentPage - 1)),
                          const SizedBox(width: 6),
                          ...List.generate(pEnd - pStart + 1, (i) {
                            final p = pStart + i;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: _pageBtn(text: '$p', isActive: p == currentPage, isEnabled: true,
                                onTap: () => vm.setTablePage(p)),
                            );
                          }),
                          const SizedBox(width: 6),
                          _pageBtn(icon: Icons.chevron_right, isEnabled: currentPage < totalPages, isActive: false,
                            onTap: () => vm.setTablePage(currentPage + 1)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _tableHeaderCell(String label, {required double width, Alignment align = Alignment.center, double leftPad = 0}) {
    return Container(
      width: width,
      height: 48,
      padding: EdgeInsets.only(left: leftPad),
      alignment: align,
      child: Text(label.toUpperCase(),
        textAlign: TextAlign.center,
        style: GoogleFonts.jetBrainsMono(
          color: AppColors.textSecondary, fontSize: 11,
        )),
    );
  }

  Widget _pageBtn({
    String? text, IconData? icon,
    required bool isActive, required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.35,
        child: Container(
          width: 28, height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? AppColors.brandAccent : AppColors.background,
            border: Border.all(
              color: isActive ? AppColors.brandAccent : AppColors.surfaceBright,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: text != null
              ? Text(text,
                  style: GoogleFonts.jetBrainsMono(
                    color: isActive ? Colors.black : AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ))
              : Icon(icon, size: 14, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  PERIOD BREAKDOWN TABLE  (spot-balances style)
  // ════════════════════════════════════════════════════════════
  Widget _periodBreakdownTable(DefiLlamaViewModel vm, Responsive res) {
    final bd     = vm.periodBreakdowns;
    final keys   = DefiLlamaViewModel.periodKeys;
    final labels = DefiLlamaViewModel.periodLabels;

    if (bd.isEmpty) return _emptyBox(res, 80);

    return AppCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final colW = constraints.maxWidth / 3;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: colW,
                    child: Column(
                      children: [
                        _tableHeaderCell('Period', width: colW, align: Alignment.centerLeft, leftPad: 16),
                        ...List.generate(keys.length, (i) {
                          final isLast = i == keys.length - 1;
                          return Container(
                            height: 52,
                            width: colW,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              border: isLast ? null : const Border(
                                bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5),
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(labels[i].toUpperCase(),
                                style: GoogleFonts.jetBrainsMono(
                                  color: AppColors.textPrimary, fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                )),
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
                              _tableHeaderCell('Perps', width: colW),
                              _tableHeaderCell('Spot', width: colW),
                            ]),
                          ),
                          ...List.generate(keys.length, (i) {
                            final k      = keys[i];
                            final p      = bd[k];
                            final isLast = i == keys.length - 1;
                            return Container(
                              height: 52,
                              decoration: BoxDecoration(
                                border: isLast ? null : const Border(
                                  bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5),
                                ),
                              ),
                              child: Row(children: [
                                SizedBox(
                                  width: colW,
                                  child: Text(
                                    p != null ? vm.fmtCompact(p.perps) : '-',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.jetBrainsMono(
                                      color: kColorPerps, fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    )),
                                ),
                                SizedBox(
                                  width: colW,
                                  child: Text(
                                    p != null ? vm.fmtCompact(p.spot) : '-',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.jetBrainsMono(
                                      color: kColorSpot, fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    )),
                                ),
                              ]),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  HELPERS
  // ════════════════════════════════════════════════════════════
  Widget _emptyBox(Responsive res, double h) => AppCard(
    height: h,
    child: Center(child: Text('No data',
      style: GoogleFonts.jetBrainsMono(
        color: AppColors.textSecondary, fontSize: res.fontSize(12),
      ))),
  );

  String _fmtY(double v) {
    final abs = v.abs();
    if (abs >= 1e9) return '\$${(v / 1e9).toStringAsFixed(1)}B';
    if (abs >= 1e6) return '\$${(v / 1e6).toStringAsFixed(1)}M';
    if (abs >= 1e3) return '\$${(v / 1e3).toStringAsFixed(0)}K';
    return '\$${v.toStringAsFixed(0)}';
  }

  String _mon(int m) {
    const n = ['Jan','Feb','Mar','Apr','May','Jun',
               'Jul','Aug','Sep','Oct','Nov','Dec'];
    return n[m - 1];
  }

  String _dateStr(DateTime dt) => '${_mon(dt.month)} ${dt.day}, ${dt.year}';

  // ════════════════════════════════════════════════════════════
  //  SHIMMER LOADING
  // ════════════════════════════════════════════════════════════
  Widget _buildLoading(Responsive res) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2C2F3A),
      highlightColor: const Color(0xFF3F4452),
      period: const Duration(milliseconds: 1400),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(res.spacing(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sh(res, 48, 0, radius: 14),
              SizedBox(height: res.spacing(20)),
              _sh(res, 12, 0),
              SizedBox(height: res.spacing(16)),
              Row(children: [
                Expanded(child: _sh(res, 90, 0, radius: 20)),
                SizedBox(width: res.spacing(12)),
                Expanded(child: _sh(res, 90, 0, radius: 20)),
                SizedBox(width: res.spacing(12)),
                Expanded(child: _sh(res, 90, 0, radius: 20)),
              ]),
              SizedBox(height: res.spacing(12)),
              Row(children: [
                Expanded(child: _sh(res, 90, 0, radius: 20)),
                SizedBox(width: res.spacing(12)),
                Expanded(child: _sh(res, 90, 0, radius: 20)),
                SizedBox(width: res.spacing(12)),
                Expanded(child: _sh(res, 90, 0, radius: 20)),
              ]),
              SizedBox(height: res.spacing(32)),
              _sh(res, 12, 0),
              SizedBox(height: res.spacing(16)),
              _sh(res, 420, 0, radius: 24), // Large consolidated dashboard card
            ],
          ),
        ),
      ),
    );
  }

  Widget _sh(Responsive res, double h, double inset, {double radius = 16}) => Container(
    height: h,
    margin: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

// ─── Chart with pinned Y-axis + scrollable content ───────────
// Scrolls to latest (rightmost) data automatically on build/update
class _ChartWithPinnedYAxis extends StatefulWidget {
  final double height;
  final double yAxisW;
  final double canvasW;
  final Widget yAxisWidget;
  final Widget Function(double chartWidth) chartBuilder;

  const _ChartWithPinnedYAxis({
    required this.height,
    required this.yAxisW,
    required this.canvasW,
    required this.yAxisWidget,
    required this.chartBuilder,
  });

  @override
  State<_ChartWithPinnedYAxis> createState() => _ChartWithPinnedYAxisState();
}

class _ChartWithPinnedYAxisState extends State<_ChartWithPinnedYAxis> {
  final ScrollController _sc = ScrollController();
  double _zoomScale = 1.0;      // current zoom multiplier
  double _scaleStart = 1.0;     // zoom at gesture start
  static const double _minZoom = 1.0;
  static const double _maxZoom = 8.0;

  @override
  void initState() {
    super.initState();
    _scrollToEnd();
  }

  @override
  void didUpdateWidget(_ChartWithPinnedYAxis old) {
    super.didUpdateWidget(old);
    if (old.canvasW != widget.canvasW) {
      _zoomScale = 1.0; // reset zoom on range/scope change
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sc.hasClients && _sc.position.hasContentDimensions) {
        _sc.jumpTo(_sc.position.maxScrollExtent);
      }
    });
  }

  void _setZoom(double value, {bool keepLatestVisible = false}) {
    setState(() => _zoomScale = value.clamp(_minZoom, _maxZoom).toDouble());
    if (keepLatestVisible) _scrollToEnd();
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveW = widget.canvasW * _zoomScale;

    return Container(
      height: widget.height,
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 30, bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Pinned Y-axis (never scrolls or zooms) ──
            SizedBox(width: widget.yAxisW, child: widget.yAxisWidget),
            // ── Zoomable + scrollable chart ──
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    controller: _sc,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: GestureDetector(
                      // Pinch to zoom
                      onScaleStart: (d) {
                        _scaleStart = _zoomScale;
                      },
                      onScaleUpdate: (d) {
                        if (d.pointerCount < 2) return; // only pinch, not single drag
                        _setZoom(_scaleStart * d.scale);
                      },
                      child: SizedBox(
                        width: effectiveW,
                        child: widget.chartBuilder(effectiveW),
                      ),
                    ),
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

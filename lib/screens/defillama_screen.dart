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

// ─── Sub-protocol colors ─────────────────────────────────────
const Color kColorPerps = Color(0xFF0D9488);
const Color kColorSpot  = Color(0xFF7C3AED);
const Color kColorHLP   = Color(0xFFD97706);
const Color kColorMain  = Color(0xFF059669);
const Color kColorBar   = Color(0xFF10B981);

// ─── Stat card data model ────────────────────────────────────
class _StatCard {
  final String label;
  final String value;
  final String badge;
  final bool badgeUp;
  final bool showBadge;
  const _StatCard({
    required this.label,
    required this.value,
    this.badge = '',
    this.badgeUp = true,
    this.showBadge = false,
  });
}

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
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
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
            SizedBox(height: res.spacing(8)),
            _statCards(vm, res),
            SizedBox(height: res.spacing(20)),

            Row(children: [
              _sectionLabel('DAILY ${vm.tabLabel.toUpperCase()} — ALL TIME'),
              const Spacer(),
              _chartToggle(vm.chartMode, vm.setChartMode, res),
            ]),
            SizedBox(height: res.spacing(8)),
            _scopeTabRow(vm, res),
            SizedBox(height: res.spacing(6)),
            _rangeTabRow(vm, res),
            SizedBox(height: res.spacing(8)),
            _allTimeChart(vm, res),
            SizedBox(height: res.spacing(12)),
            _chartDataTable(vm, res),
            SizedBox(height: res.spacing(8)),
            _tablePagination(vm, res),
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

  Widget _sectionLabel(String text) => Text(
    text,
    style: GoogleFonts.jetBrainsMono(
      color: AppColors.textSecondary.withOpacity(0.45),
      fontSize: 9,
      letterSpacing: 1.8,
    ),
  );

  // ════════════════════════════════════════════════════════════
  //  TAB TOGGLE
  // ════════════════════════════════════════════════════════════
  Widget _tabRow(DefiLlamaViewModel vm, Responsive res) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.surfaceBright),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(3),
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
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(title,
            style: GoogleFonts.jetBrainsMono(
              color: active ? AppColors.brandAccent : AppColors.textSecondary,
              fontSize: res.fontSize(12),
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
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
      height: 26,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.surfaceBright),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _modePill('Area', mode == 'area', () => onSet('area'), res),
          _modePill('Bar',  mode == 'bar',  () => onSet('bar'),  res),
        ]),
      ),
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
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
          style: GoogleFonts.jetBrainsMono(
            color: active ? AppColors.brandAccent : AppColors.textSecondary,
            fontSize: res.fontSize(9),
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          )),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  6 STAT CARDS
  // ════════════════════════════════════════════════════════════
  Widget _statCards(DefiLlamaViewModel vm, Responsive res) {
    final change = vm.change1d;
    final cards = [
      _StatCard(
        label: '24h',
        value: vm.fmtCompact(vm.stat24h),
        badge: vm.fmtPct(change),
        badgeUp: change >= 0,
        showBadge: true,
      ),
      _StatCard(label: 'Prev 24h', value: vm.fmtCompact(vm.statPrev24h)),
      _StatCard(label: '7d',       value: vm.fmtCompact(vm.stat7d)),
      _StatCard(label: '30d',      value: vm.fmtCompact(vm.stat30d)),
      _StatCard(label: '1y',       value: vm.fmtCompact(vm.stat1y)),
      _StatCard(label: 'All Time', value: vm.fmtCompact(vm.statAllTime)),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: res.spacing(8),
      mainAxisSpacing: res.spacing(8),
      childAspectRatio: 1.35,
      children: cards.map((c) => _statCardTile(c, res)).toList(),
    );
  }

  Widget _statCardTile(_StatCard c, Responsive res) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: res.spacing(10), vertical: res.spacing(9),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.brandAccent.withOpacity(0.25),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brandAccent.withOpacity(0.13),
            AppColors.brandAccent.withOpacity(0.04),
            AppColors.background,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandAccent.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(c.label,
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.brandAccent.withOpacity(0.7),
              fontSize: res.fontSize(9),
              letterSpacing: 0.6,
              fontWeight: FontWeight.w500,
            )),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(c.value,
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontSize: res.fontSize(14),
                fontWeight: FontWeight.bold,
              )),
          ),
          if (c.showBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: c.badgeUp
                    ? AppColors.trendGreen.withOpacity(0.18)
                    : AppColors.trendRed.withOpacity(0.18),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: c.badgeUp
                      ? AppColors.trendGreen.withOpacity(0.3)
                      : AppColors.trendRed.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Text(c.badge,
                style: GoogleFonts.jetBrainsMono(
                  color: c.badgeUp ? AppColors.trendGreen : AppColors.trendRed,
                  fontSize: res.fontSize(8),
                  fontWeight: FontWeight.bold,
                )),
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  SCOPE TABS  — All / Perps / Spot / HLP
  // ════════════════════════════════════════════════════════════
  Widget _scopeTabRow(DefiLlamaViewModel vm, Responsive res) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.surfaceBright),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          children: ChartScope.values.map((s) {
            final active = vm.chartScope == s;
            final color  = s.color;
            return Expanded(
              child: GestureDetector(
                onTap: () => vm.setChartScope(s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? color.withOpacity(0.18) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: active
                        ? Border.all(color: color.withOpacity(0.5), width: 1)
                        : null,
                  ),
                  child: Text(s.label,
                    style: GoogleFonts.jetBrainsMono(
                      color: active ? color : AppColors.textSecondary,
                      fontSize: res.fontSize(11),
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    )),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  RANGE TABS  — 1D / 1W / 1M / 1Y / ALL
  // ════════════════════════════════════════════════════════════
  Widget _rangeTabRow(DefiLlamaViewModel vm, Responsive res) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.surfaceBright),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          children: ChartRange.values.map((r) {
            final active = vm.chartRange == r;
            return Expanded(
              child: GestureDetector(
                onTap: () => vm.setChartRange(r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? AppColors.surfaceBright : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(r.label,
                    style: GoogleFonts.jetBrainsMono(
                      color: active ? AppColors.brandAccent : AppColors.textSecondary,
                      fontSize: res.fontSize(11),
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    )),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  ALL-TIME DAILY CHART  — scrollable, latest data on right
  // ════════════════════════════════════════════════════════════
  Widget _allTimeChart(DefiLlamaViewModel vm, Responsive res) {
    if (vm.isChartLoading) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.surfaceBright),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: SizedBox(
          width: 24, height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2, color: vm.chartScope.color,
          ),
        )),
      );
    }

    final spots = vm.chartSpots;
    final dates = vm.chartDates;
    if (spots.isEmpty) return _emptyBox(res, 300);

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
        pxPerBar = (scrollAreaW / 365).clamp(3.0, 10.0);
        break;
      case ChartRange.weekly:
        pxPerBar = (scrollAreaW / 52).clamp(12.0, 36.0);
        break;
      case ChartRange.monthly:
        pxPerBar = (scrollAreaW / 12).clamp(40.0, 80.0);
        break;
      case ChartRange.yearly:
        pxPerBar = scrollAreaW;
        break;
    }

    final canvasW = (n * pxPerBar).clamp(scrollAreaW, scrollAreaW * 15);

    return _ChartWithPinnedYAxis(
      height: 300,
      yAxisW: yAxisW,
      canvasW: canvasW,
      yAxisWidget: _yAxisWidget(spots, scopeColor),
      chartWidget: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: vm.chartMode == 'bar'
            ? _barChart(spots, dates, scopeColor, res, canvasW)
            : _areaChart(spots, dates, scopeColor, res, canvasW),
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
        ? (canvasWidth / n * 0.6).clamp(1.0, 12.0)
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
  //  CHART DATA TABLE  (same data as graph, paginated)
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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.surfaceBright),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: res.spacing(14), vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.surfaceBright)),
            ),
            child: Row(children: [
              Expanded(flex: 3, child: Text(dateHeader,
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textSecondary, fontSize: res.fontSize(10),
                  fontWeight: FontWeight.bold, letterSpacing: 0.4,
                ))),
              Expanded(flex: 2, child: Text(vm.tabLabel,
                textAlign: TextAlign.right,
                style: GoogleFonts.jetBrainsMono(
                  color: scopeColor, fontSize: res.fontSize(10),
                  fontWeight: FontWeight.bold,
                ))),
            ]),
          ),
          ...rows.asMap().entries.map((e) {
            final isLast = e.key == rows.length - 1;
            final row    = e.value;
            return Container(
              padding: EdgeInsets.symmetric(horizontal: res.spacing(14), vertical: 12),
              decoration: BoxDecoration(
                border: isLast ? null : const Border(
                  bottom: BorderSide(color: AppColors.surfaceBright, width: 0.5),
                ),
              ),
              child: Row(children: [
                Expanded(flex: 3, child: Text(vm.tableDateLabel(row.date),
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white, fontSize: res.fontSize(11),
                    fontWeight: FontWeight.w500,
                  ))),
                Expanded(flex: 2, child: Text(vm.fmtCompact(row.value),
                  textAlign: TextAlign.right,
                  style: GoogleFonts.jetBrainsMono(
                    color: scopeColor, fontSize: res.fontSize(11),
                    fontWeight: FontWeight.w600,
                  ))),
              ]),
            );
          }),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  TABLE PAGINATION  (same style as home screen)
  // ════════════════════════════════════════════════════════════
  Widget _tablePagination(DefiLlamaViewModel vm, Responsive res) {
    final totalPages  = vm.tableTotalPages;
    final currentPage = vm.tablePage;
    if (totalPages <= 1) return const SizedBox.shrink();

    final tp = totalPages.clamp(1, totalPages);
    int start = (currentPage - 1).clamp(1, tp);
    int end   = (start + 2).clamp(1, tp);
    if (end == tp && tp > 3) start = (end - 2).clamp(1, tp);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Rows:', style: GoogleFonts.jetBrainsMono(
          color: AppColors.textSecondary, fontSize: res.fontSize(12),
        )),
        const SizedBox(width: 8),
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border.all(color: AppColors.surfaceBright),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              dropdownColor: AppColors.background,
              value: vm.tableRowsPerPage,
              icon: const Icon(Icons.keyboard_arrow_down,
                color: AppColors.textSecondary, size: 16),
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textPrimary, fontSize: res.fontSize(12)),
              borderRadius: BorderRadius.circular(8),
              onChanged: (v) { if (v != null) vm.setTableRowsPerPage(v); },
              items: DefiLlamaViewModel.tableRowsOptions
                  .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                  .toList(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        _pgBtn(res, icon: Icons.chevron_left,
          enabled: currentPage > 1,
          onTap: () => vm.setTablePage(currentPage - 1)),
        const SizedBox(width: 8),
        ...List.generate(end - start + 1, (i) {
          final p = start + i;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _pgBtn(res, text: '$p', active: p == currentPage,
              onTap: () => vm.setTablePage(p)),
          );
        }),
        const SizedBox(width: 8),
        _pgBtn(res, icon: Icons.chevron_right,
          enabled: currentPage < totalPages,
          onTap: () => vm.setTablePage(currentPage + 1)),
      ],
    );
  }

  Widget _pgBtn(Responsive res, {
    IconData? icon, String? text,
    bool active = false, bool enabled = true,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled || active ? onTap : null,
      child: Opacity(
        opacity: (!enabled && !active && icon != null) ? 0.35 : 1.0,
        child: Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: active ? AppColors.brandAccent : AppColors.background,
            border: active ? null : Border.all(color: AppColors.surfaceBright),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, size: 16,
                    color: active ? Colors.black : Colors.white)
                : Text(text ?? '',
                    style: GoogleFonts.jetBrainsMono(
                      color: active ? Colors.black : Colors.white,
                      fontSize: res.fontSize(11),
                      fontWeight: FontWeight.bold,
                    )),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  PERIOD BREAKDOWN TABLE
  // ════════════════════════════════════════════════════════════
  Widget _periodBreakdownTable(DefiLlamaViewModel vm, Responsive res) {
    final bd     = vm.periodBreakdowns;
    final keys   = DefiLlamaViewModel.periodKeys;
    final labels = DefiLlamaViewModel.periodLabels;

    if (bd.isEmpty) return _emptyBox(res, 80);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.surfaceBright),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // ── Header ──
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: res.spacing(14), vertical: 10,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.surfaceBright)),
            ),
            child: Row(children: [
              SizedBox(
                width: 54,
                child: Text('Period',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary,
                    fontSize: res.fontSize(10),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  )),
              ),
              Expanded(child: Text('Perps', textAlign: TextAlign.right,
                style: GoogleFonts.jetBrainsMono(
                  color: kColorPerps, fontSize: res.fontSize(10),
                  fontWeight: FontWeight.bold,
                ))),
              Expanded(child: Text('Spot', textAlign: TextAlign.right,
                style: GoogleFonts.jetBrainsMono(
                  color: kColorSpot, fontSize: res.fontSize(10),
                  fontWeight: FontWeight.bold,
                ))),
              Expanded(child: Text('HLP', textAlign: TextAlign.right,
                style: GoogleFonts.jetBrainsMono(
                  color: kColorHLP, fontSize: res.fontSize(10),
                  fontWeight: FontWeight.bold,
                ))),
            ]),
          ),
          // ── Data rows ──
          ...List.generate(keys.length, (i) {
            final p      = bd[keys[i]];
            final isLast = i == keys.length - 1;
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: res.spacing(14), vertical: 13,
              ),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(
                          color: AppColors.surfaceBright, width: 0.5,
                        ),
                      ),
              ),
              child: Row(children: [
                SizedBox(
                  width: 54,
                  child: Text(labels[i],
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white,
                      fontSize: res.fontSize(11),
                      fontWeight: FontWeight.w600,
                    )),
                ),
                Expanded(child: Text(
                  p != null ? vm.fmtCompact(p.perps) : '-',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.jetBrainsMono(
                    color: kColorPerps,
                    fontSize: res.fontSize(11),
                    fontWeight: FontWeight.w600,
                  ),
                )),
                Expanded(child: Text(
                  p != null ? vm.fmtCompact(p.spot) : '-',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.jetBrainsMono(
                    color: kColorSpot,
                    fontSize: res.fontSize(11),
                    fontWeight: FontWeight.w600,
                  ),
                )),
                Expanded(child: Text(
                  p != null ? vm.fmtCompact(p.hlp) : '-',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.jetBrainsMono(
                    color: kColorHLP,
                    fontSize: res.fontSize(11),
                    fontWeight: FontWeight.w600,
                  ),
                )),
              ]),
            );
          }),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  HELPERS
  // ════════════════════════════════════════════════════════════
  Widget _emptyBox(Responsive res, double h) => Container(
    height: h,
    decoration: BoxDecoration(
      color: AppColors.background,
      border: Border.all(color: AppColors.surfaceBright),
      borderRadius: BorderRadius.circular(8),
    ),
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
      baseColor: const Color(0xFF1E222D),
      highlightColor: const Color(0xFF2A2F3E),
      period: const Duration(milliseconds: 1200),
      child: Padding(
        padding: EdgeInsets.all(res.spacing(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sh(res, 38, 0),
            _sh(res, 12, 0),
            _sh(res, 10, 60),
            _sh(res, 6, 0),
            Row(children: [
              Expanded(child: _sh(res, 76, 0)),
              SizedBox(width: res.spacing(8)),
              Expanded(child: _sh(res, 76, 0)),
              SizedBox(width: res.spacing(8)),
              Expanded(child: _sh(res, 76, 0)),
            ]),
            _sh(res, 8, 0),
            Row(children: [
              Expanded(child: _sh(res, 76, 0)),
              SizedBox(width: res.spacing(8)),
              Expanded(child: _sh(res, 76, 0)),
              SizedBox(width: res.spacing(8)),
              Expanded(child: _sh(res, 76, 0)),
            ]),
            _sh(res, 20, 0),
            _sh(res, 10, 60),
            _sh(res, 6, 0),
            _sh(res, 260, 0),
            _sh(res, 20, 0),
            _sh(res, 10, 60),
            _sh(res, 6, 0),
            _sh(res, 150, 0),
          ],
        ),
      ),
    );
  }

  Widget _sh(Responsive res, double h, double inset) => Container(
    height: h,
    margin: EdgeInsets.symmetric(
      vertical: 3,
      horizontal: inset > 0 ? res.spacing(inset) : 0,
    ),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.03),
      borderRadius: BorderRadius.circular(6),
    ),
  );
}

// ─── Simple data holder for protocol card rows ───────────────
class _ProtocolRow {
  final String period;
  final String value;
  const _ProtocolRow({required this.period, required this.value});
}

// ─── Chart with pinned Y-axis + scrollable content ───────────
// Scrolls to latest (rightmost) data automatically on build/update
class _ChartWithPinnedYAxis extends StatefulWidget {
  final double height;
  final double yAxisW;
  final double canvasW;
  final Widget yAxisWidget;
  final Widget chartWidget;

  const _ChartWithPinnedYAxis({
    required this.height,
    required this.yAxisW,
    required this.canvasW,
    required this.yAxisWidget,
    required this.chartWidget,
  });

  @override
  State<_ChartWithPinnedYAxis> createState() => _ChartWithPinnedYAxisState();
}

class _ChartWithPinnedYAxisState extends State<_ChartWithPinnedYAxis> {
  final ScrollController _sc = ScrollController();
  double _zoomScale = 1.0;      // current zoom multiplier
  double _scaleStart = 1.0;     // zoom at gesture start
  static const double _minZoom = 0.5;
  static const double _maxZoom = 8.0;

  @override
  void initState() {
    super.initState();
    _scrollToStart();
  }

  @override
  void didUpdateWidget(_ChartWithPinnedYAxis old) {
    super.didUpdateWidget(old);
    if (old.canvasW != widget.canvasW) {
      _zoomScale = 1.0; // reset zoom on range/scope change
      _scrollToStart();
    }
  }

  void _scrollToStart() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sc.hasClients && _sc.position.hasContentDimensions) {
        _sc.jumpTo(0);
      }
    });
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
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.surfaceBright),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Pinned Y-axis (never scrolls or zooms) ──
            SizedBox(width: widget.yAxisW, child: widget.yAxisWidget),
            // ── Zoomable + scrollable chart ──
            Expanded(
              child: GestureDetector(
                // Pinch to zoom
                onScaleStart: (d) {
                  _scaleStart = _zoomScale;
                },
                onScaleUpdate: (d) {
                  if (d.pointerCount < 2) return; // only pinch, not single drag
                  setState(() {
                    _zoomScale = (_scaleStart * d.scale)
                        .clamp(_minZoom, _maxZoom);
                  });
                },
                child: SingleChildScrollView(
                  controller: _sc,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: effectiveW,
                    child: widget.chartWidget,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

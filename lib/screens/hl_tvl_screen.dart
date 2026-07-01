import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/hl_tvl_model.dart';
import '../utils/app_colors.dart';
import '../utils/common_widgets.dart';
import '../utils/responsive.dart';
import '../viewmodels/hl_tvl_viewmodel.dart';

class HlTvlScreen extends StatefulWidget {
  const HlTvlScreen({super.key});

  @override
  State<HlTvlScreen> createState() => _HlTvlScreenState();
}

class _HlTvlScreenState extends State<HlTvlScreen> {
  bool _showChainPie = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HlTvlViewModel>().fetchAll();
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
            child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.brandAccent, size: res.fontSize(20)),
          ),
          title: Text(
            'Hyperliquid TVL',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.brandAccent,
              fontSize: res.fontSize(16),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        body: Consumer<HlTvlViewModel>(
          builder: (_, vm, __) {
            if (vm.isLoading) return _buildLoading();
            if (vm.error.isNotEmpty) return _buildError(vm);
            if (vm.summary == null) return const SizedBox.shrink();
            return _buildContent(vm, res);
          },
        ),
      ),
    );
  }

  Widget _buildContent(HlTvlViewModel vm, Responsive res) {
    final s = vm.summary!;
    final m = vm.metrics;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(res.spacing(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _protocolHeader(s, res),
          SizedBox(height: res.spacing(16)),
          _statCards(s, m, res),
          SizedBox(height: res.spacing(16)),
          _chainBreakdownCard(s, res),
          SizedBox(height: res.spacing(16)),
          _tvlHistoryCard(vm, res),
          SizedBox(height: res.spacing(16)),
          _tvlChainsHistoryCard(vm, res),
          SizedBox(height: res.spacing(24)),
          if (m != null) ...[
            _advancedGrowthCard(m, res),
            SizedBox(height: res.spacing(16)),
            _hyperliquidEcosystemCard(s, res),
          ],
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  // ── Advanced growth card ───────────────────────────────────────
  Widget _advancedGrowthCard(HlTvlMetrics m, Responsive res) {
    return AppCard(
      padding: EdgeInsets.all(res.spacing(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Advanced Growth Metrics', style: GoogleFonts.inter(
              color: Colors.white, fontSize: res.fontSize(13), fontWeight: FontWeight.bold)),
            const SizedBox(width: 6),
            Icon(Icons.info_outline, color: AppColors.textSecondary.withOpacity(0.5), size: res.fontSize(14)),
          ]),
          SizedBox(height: res.spacing(20)),
          Row(
            children: [
              _advancedMetricTile('30d Growth', m.change30d, 'May 25, 2026', res),
              _advancedMetricTile('90d Growth', m.change90d, 'Mar 26, 2026', res),
              _advancedMetricTile('1y Growth', m.change1y, 'Jun 24, 2025', res),
              _advancedMetricTile('Drawdown from ATH', m.drawdown, null, res, isDrawdown: true),
            ],
          ),
          SizedBox(height: res.spacing(24)),
          Divider(color: Colors.white.withOpacity(0.05)),
          SizedBox(height: res.spacing(20)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _bottomMetric('Current TVL', fmtTvl(m.currentTvl), res),
              _bottomMetric('All Time High', fmtTvl(m.athTvl), res),
              _bottomMetric('ATH Date', _fmtDateFull(m.athDate), res),
              _bottomMetric('Data Source', 'DeFiLlama', res, showSourceIcon: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _advancedMetricTile(String label, double? val, String? dateRange, Responsive res, {bool isDrawdown = false}) {
    if (val == null) return const Expanded(child: SizedBox.shrink());
    final isUp = val >= 0;
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(res.spacing(10)),
        margin: EdgeInsets.only(right: res.spacing(8)),
        decoration: BoxDecoration(
          color: AppColors.surfaceBright.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: res.fontSize(8), fontWeight: FontWeight.w600)),
            SizedBox(height: res.spacing(8)),
            Text('${isUp && !isDrawdown ? '+' : ''}${val.toStringAsFixed(2)}%',
              style: GoogleFonts.inter(
                color: isUp && !isDrawdown ? AppColors.trendGreen : (isDrawdown ? AppColors.trendRed : AppColors.trendRed),
                fontSize: res.fontSize(14), fontWeight: FontWeight.bold)),
            if (dateRange != null) ...[
              SizedBox(height: res.spacing(4)),
              Text('vs $dateRange', style: GoogleFonts.inter(color: AppColors.textSecondary.withOpacity(0.5), fontSize: res.fontSize(7))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bottomMetric(String label, String value, Responsive res, {bool showSourceIcon = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: res.fontSize(8), fontWeight: FontWeight.w600)),
        SizedBox(height: res.spacing(8)),
        Row(
          children: [
            if (showSourceIcon) ...[
              Container(
                width: res.fontSize(14), height: res.fontSize(14),
                decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle),
                child: Center(child: Text('D', style: TextStyle(color: Colors.white, fontSize: res.fontSize(8), fontWeight: FontWeight.bold))),
              ),
              SizedBox(width: res.spacing(6)),
            ],
            Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: res.fontSize(11), fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  String _fmtDateFull(int timestamp) {
    if (timestamp == 0) return '-';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('MMMM d, yyyy').format(date);
  }

  // ── Hyperliquid Ecosystem card ────────────────────────────────
  Widget _hyperliquidEcosystemCard(HlTvlSummary s, Responsive res) {
    return AppCard(
      padding: EdgeInsets.all(res.spacing(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hyperliquid Ecosystem', style: GoogleFonts.inter(
            color: Colors.white, fontSize: res.fontSize(13), fontWeight: FontWeight.bold)),
          SizedBox(height: res.spacing(20)),
          _ecosystemRow('Hyperliquid Bridge', 'Bridge assets to and from Hyperliquid L1', 'B', const Color(0xFFDCFCE7), const Color(0xFF166534), res),
          _ecosystemRow('Hyperliquid HLP', 'Liquidity provider vault', 'H', const Color(0xFFF3E8FF), const Color(0xFF6B21A8), res),
          _ecosystemRow('Hyperliquid Perps', 'Perpetual futures trading', 'P', const Color(0xFFE0F2FE), const Color(0xFF075985), res),
          _ecosystemRow('Hyperliquid Spot Orderbook', 'Spot trading on Hyperliquid', 'S', const Color(0xFFFEF9C3), const Color(0xFF854D0E), res),
        ],
      ),
    );
  }

  Widget _ecosystemRow(String name, String desc, String char, Color bg, Color textColor, Responsive res) {
    return Padding(
      padding: EdgeInsets.only(bottom: res.spacing(12)),
      child: Container(
        padding: EdgeInsets.all(res.spacing(12)),
        decoration: BoxDecoration(
          color: AppColors.surfaceBright.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: res.spacing(32), height: res.spacing(32),
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Center(child: Text(char, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: res.fontSize(14)))),
            ),
            SizedBox(width: res.spacing(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.inter(color: Colors.white, fontSize: res.fontSize(11), fontWeight: FontWeight.bold)),
                  SizedBox(height: res.spacing(2)),
                  Text(desc, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: res.fontSize(8))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Metrics card (DEPRECATED) ──────────────────────────────────
  Widget _metricsCard(HlTvlMetrics m, Responsive res) {
    return const SizedBox.shrink(); // Replaced by _advancedGrowthCard
  }

  // ── Protocol header card ───────────────────────────────────────
  Widget _protocolHeader(HlTvlSummary s, Responsive res) {
    return AppCard(
      padding: EdgeInsets.all(res.spacing(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              s.metadata.logo,
              width: res.spacing(44), height: res.spacing(44), fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: res.spacing(44), height: res.spacing(44),
                decoration: BoxDecoration(
                  color: AppColors.brandAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.currency_exchange, color: AppColors.brandAccent, size: res.fontSize(22)),
              ),
            ),
          ),
          SizedBox(width: res.spacing(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(s.metadata.name,
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white, fontSize: res.fontSize(14), fontWeight: FontWeight.bold)),
                  SizedBox(width: res.spacing(6)),
                  Icon(Icons.verified, size: res.fontSize(14), color: AppColors.brandAccent),
                ]),
                SizedBox(height: res.spacing(4)),
                Text(
                  s.metadata.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary, fontSize: res.fontSize(9)),
                ),
                SizedBox(height: res.spacing(8)),
                _viewAllButton(s, res),
              ],
            ),
          ),
          SizedBox(width: res.spacing(12)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('MARKET CAP', style: GoogleFonts.inter(
                color: AppColors.textSecondary, fontSize: res.fontSize(8), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              SizedBox(height: res.spacing(3)),
              Text(fmtTvl(s.marketCap), style: GoogleFonts.jetBrainsMono(
                color: Colors.white, fontSize: res.fontSize(13), fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  // ── View All button → detail dialog ───────────────────────────
  Widget _viewAllButton(HlTvlSummary s, Responsive res) {
    return GestureDetector(
      onTap: () => _showDetailDialog(s),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('VIEW ALL', style: GoogleFonts.jetBrainsMono(
            color: AppColors.brandAccent, fontSize: res.fontSize(9), fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          SizedBox(width: res.spacing(3)),
          Icon(Icons.chevron_right_rounded, size: res.fontSize(13), color: AppColors.brandAccent),
        ],
      ),
    );
  }

  // ── Stat cards row ─────────────────────────────────────────────
  Widget _statCards(HlTvlSummary s, HlTvlMetrics? m, Responsive res) {
    final isUp24 = s.tvl.change24h >= 0;
    final isUp7d = s.tvl.change7d >= 0;
    return Row(children: [
      Expanded(child: _statCard(
        title: 'TOTAL TVL',
        value: fmtTvl(s.tvl.total),
        badge: '${isUp24 ? '+' : ''}${s.tvl.change24h.toStringAsFixed(2)}%',
        badgeUp: isUp24,
        icon: Icons.account_balance_wallet_rounded,
        res: res,
      )),
      SizedBox(width: res.spacing(10)),
      Expanded(child: _statCard(
        title: 'ATH TVL',
        value: fmtTvl(s.tvl.ath),
        badge: fmtDate(s.tvl.athDate),
        badgeUp: true,
        badgeIsDate: true,
        icon: Icons.emoji_events_rounded,
        res: res,
      )),
      SizedBox(width: res.spacing(10)),
      Expanded(child: _statCard(
        title: '7D CHANGE',
        value: '${isUp7d ? '+' : ''}${s.tvl.change7d.toStringAsFixed(2)}%',
        valueColor: isUp7d ? AppColors.trendGreen : AppColors.trendRed,
        icon: isUp7d ? Icons.trending_up : Icons.trending_down,
        res: res,
      )),
    ]);
  }

  Widget _statCard({
    required String title,
    required String value,
    String? badge,
    bool badgeUp = true,
    bool badgeIsDate = false,
    required IconData icon,
    required Responsive res,
    Color? valueColor,
  }) {
    return Container(
      padding: EdgeInsets.all(res.spacing(12)),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(child: Text(title, style: GoogleFonts.inter(
              color: AppColors.textSecondary, fontSize: res.fontSize(9),
              fontWeight: FontWeight.w600, letterSpacing: 0.5))),
            Container(
              padding: EdgeInsets.all(res.spacing(6)),
              decoration: BoxDecoration(
                color: AppColors.brandAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: AppColors.brandAccent, size: res.fontSize(14)),
            ),
          ]),
          SizedBox(height: res.spacing(6)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: GoogleFonts.inter(
              color: valueColor ?? Colors.white,
              fontSize: res.fontSize(15),
              fontWeight: FontWeight.bold)),
          ),
          if (badge != null) ...[
            SizedBox(height: res.spacing(4)),
            Row(children: [
              if (!badgeIsDate)
                Icon(badgeUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: badgeUp ? AppColors.trendGreen : AppColors.trendRed, size: res.fontSize(14)),
              Flexible(child: Text(badge, style: GoogleFonts.inter(
                color: badgeIsDate
                    ? AppColors.textSecondary
                    : (badgeUp ? AppColors.trendGreen : AppColors.trendRed),
                fontSize: res.fontSize(9),
                fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis)),
            ]),
          ],
        ],
      ),
    );
  }

  // ── TVL History Chart ──────────────────────────────────────────
  Widget _tvlHistoryCard(HlTvlViewModel vm, Responsive res) {
    final h = vm.history;
    return AppCard(
      padding: EdgeInsets.all(res.spacing(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text('Total Value Locked Over Time',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: res.fontSize(13),
                        fontWeight: FontWeight.bold)),
              ),
              _buildRangeSelector(vm, res),
            ],
          ),
          SizedBox(height: res.spacing(16)),
          if (vm.isHistoryLoading && h == null)
            SizedBox(height: res.spacing(200), child: const Center(child: CircularProgressIndicator(color: AppColors.brandAccent, strokeWidth: 2)))
          else if (h == null || h.data.isEmpty)
            SizedBox(height: res.spacing(200), child: Center(child: Text('No history data available', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: res.fontSize(11)))))
          else
            _buildLineChart(h, vm.summary?.tvl.total ?? 0, res),
        ],
      ),
    );
  }

  Widget _buildRangeSelector(HlTvlViewModel vm, Responsive res) {
    final ranges = ['7D', '30D', '90D', '1Y', 'ALL'];
    final current = vm.selectedRange.toUpperCase();
    return Theme(
      data: Theme.of(context).copyWith(canvasColor: AppColors.background),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceBright.withOpacity(0.12),
          border: Border.all(color: AppColors.surfaceBright.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: current,
            dropdownColor: const Color(0xFF1A1D24),
            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 16),
            style: GoogleFonts.jetBrainsMono(color: AppColors.brandAccent, fontSize: res.fontSize(11), fontWeight: FontWeight.bold),
            isDense: true,
            onChanged: (v) { if (v != null) vm.setRange(v.toLowerCase()); },
            items: ranges.map((r) => DropdownMenuItem(
              value: r,
              child: Text(r, style: GoogleFonts.jetBrainsMono(
                color: r == current ? AppColors.brandAccent : AppColors.textSecondary,
                fontSize: res.fontSize(11),
                fontWeight: r == current ? FontWeight.bold : FontWeight.w500,
              )),
            )).toList(),
          ),
        ),
      ),
    );
  }
  Widget _buildLineChart(HlTvlHistory h, double currentTvl, Responsive res) {
    final spots = h.data.map((p) => FlSpot(p.date.toDouble(), p.value)).toList();
    if (spots.isEmpty) return const SizedBox.shrink();
    
    final minY = h.data.map((e) => e.value).reduce((a, b) => a < b ? a : b) * 0.95;
    final maxY = h.data.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.1;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: res.spacing(220),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 2.0,
            child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 4 > 0 ? (maxY - minY) / 4 : 1.0,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withOpacity(0.03), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              interval: spots.length > 1 ? (spots.last.x - spots.first.x) / (res.isMobile ? 4 : 6) : 1.0,
              getTitlesWidget: (value, meta) {
                // Skip first and last to avoid edge overlap
                if (value <= meta.min || value >= meta.max) return const SizedBox.shrink();
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt() * 1000);
                String label = '';
                if (h.range == '7d') label = DateFormat('E').format(date);
                else if (h.range == '30d') label = DateFormat('MMM d').format(date);
                else label = DateFormat('MMM').format(date);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary.withOpacity(0.5), fontSize: res.fontSize(9))),
                );
              },
            )),
            leftTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              reservedSize: res.spacing(54),
              interval: (maxY - minY) / 4 > 0 ? (maxY - minY) / 4 : 1.0,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) return const SizedBox.shrink();
                return Text(fmtTvl(value),
                  style: GoogleFonts.inter(color: AppColors.textSecondary.withOpacity(0.5), fontSize: res.fontSize(9)));
              },
            )),
          ),
          borderData: FlBorderData(show: false),
          minX: spots.first.x,
          maxX: spots.last.x,
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.trendGreen,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [AppColors.trendGreen.withOpacity(0.15), AppColors.trendGreen.withOpacity(0.0)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: currentTvl,
                color: AppColors.trendGreen.withOpacity(0.5),
                strokeWidth: 1,
                dashArray: [4, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.trendGreen,
                    fontSize: res.fontSize(8),
                    fontWeight: FontWeight.bold,
                    background: Paint()..color = const Color(0xFF0D0F14)..strokeWidth = 10..style = PaintingStyle.stroke..strokeJoin = StrokeJoin.round,
                  ),
                  labelResolver: (line) => fmtTvl(line.y),
                ),
              ),
            ],
          ),
        ), // LineChartData
        ), // LineChart
        ), // inner SizedBox
        ), // SingleChildScrollView
      ),   // outer SizedBox
    );     // ClipRRect
  }

  // ── TVL by Chain (Migration) Card ──────────────────────────────
  Widget _tvlChainsHistoryCard(HlTvlViewModel vm, Responsive res) {
    final h = vm.chainsHistory;
    return AppCard(
      padding: EdgeInsets.all(res.spacing(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text('TVL by Chain Over Time',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: res.fontSize(13),
                        fontWeight: FontWeight.bold)),
              ),
              _buildChainsRangeSelector(vm, res),
            ],
          ),
          SizedBox(height: res.spacing(10)),
          _buildChainsLegend(res),
          SizedBox(height: res.spacing(16)),
          if (vm.isChainsHistoryLoading && h == null)
            SizedBox(height: res.spacing(200), child: const Center(child: CircularProgressIndicator(color: AppColors.brandAccent, strokeWidth: 2)))
          else if (h == null || h.data.isEmpty)
            SizedBox(height: res.spacing(200), child: Center(child: Text('No chain history data available', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: res.fontSize(11)))))
          else
            _buildChainsLineChart(h, vm.summary?.chainBreakdown ?? [], res),
        ],
      ),
    );
  }

  Widget _buildChainsLegend(Responsive res) {
    return Row(
      children: [
        _legendItem('Hyperliquid L1', AppColors.brandAccent, res),
        SizedBox(width: res.spacing(16)),
        _legendItem('Arbitrum', const Color(0xFF3B82F6), res),
      ],
    );
  }

  Widget _legendItem(String label, Color color, Responsive res) {
    return Row(
      children: [
        Container(width: res.fontSize(8), height: res.fontSize(8), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: res.spacing(6)),
        Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: res.fontSize(10), fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildChainsRangeSelector(HlTvlViewModel vm, Responsive res) {
    final ranges = ['7D', '30D', '90D', '1Y', 'ALL'];
    final current = vm.selectedChainsRange.toUpperCase();
    return Theme(
      data: Theme.of(context).copyWith(canvasColor: AppColors.background),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceBright.withOpacity(0.12),
          border: Border.all(color: AppColors.surfaceBright.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: current,
            dropdownColor: const Color(0xFF1A1D24),
            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 16),
            style: GoogleFonts.jetBrainsMono(color: AppColors.brandAccent, fontSize: res.fontSize(11), fontWeight: FontWeight.bold),
            isDense: true,
            onChanged: (v) { if (v != null) vm.setChainsRange(v.toLowerCase()); },
            items: ranges.map((r) => DropdownMenuItem(
              value: r,
              child: Text(r, style: GoogleFonts.jetBrainsMono(
                color: r == current ? AppColors.brandAccent : AppColors.textSecondary,
                fontSize: res.fontSize(11),
                fontWeight: r == current ? FontWeight.bold : FontWeight.w500,
              )),
            )).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildChainsLineChart(HlChainsHistory h, List<HlChainBreakdown> current, Responsive res) {
    final spotsL1 = h.data.map((p) => FlSpot(p.date.toDouble(), p.l1)).toList();
    final spotsArb = h.data.map((p) => FlSpot(p.date.toDouble(), p.arbitrum)).toList();
    
    final allVals = h.data.expand((e) => [e.l1, e.arbitrum]).toList();
    final minY = 0.0;
    final maxY = allVals.reduce((a, b) => a > b ? a : b) * 1.1;

    double curL1 = 0;
    double curArb = 0;
    for (var c in current) {
      if (c.name.contains('L1')) curL1 = c.value;
      if (c.name.contains('Arbitrum')) curArb = c.value;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: res.spacing(250),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 2.0,
            child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 5 > 0 ? maxY / 5 : 1.0,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withOpacity(0.03), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              interval: spotsL1.length > 1 ? (spotsL1.last.x - spotsL1.first.x) / (res.isMobile ? 4 : 6) : 1.0,
              getTitlesWidget: (value, meta) {
                if (value <= meta.min || value >= meta.max) return const SizedBox.shrink();
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt() * 1000);
                String label = '';
                if (h.range == 'all' || h.range == '1y') {
                   if (date.month == 1) label = date.year.toString();
                   else label = DateFormat('MMM').format(date);
                } else label = DateFormat('MMM d').format(date);

                final isYear = label == '2024' || label == '2025' || label == '2026';
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(label, style: GoogleFonts.inter(
                    color: isYear ? Colors.white.withOpacity(0.5) : AppColors.textSecondary.withOpacity(0.4),
                    fontSize: isYear ? res.fontSize(10) : res.fontSize(9),
                    fontWeight: isYear ? FontWeight.bold : FontWeight.normal,
                  )),
                );
              },
            )),
            leftTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              reservedSize: res.spacing(54),
              interval: maxY / 4 > 0 ? maxY / 4 : 1.0,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) return const SizedBox.shrink();
                return Text(fmtTvl(value),
                  style: GoogleFonts.inter(color: AppColors.textSecondary.withOpacity(0.5), fontSize: res.fontSize(9)));
              },
            )),
          ),
          borderData: FlBorderData(show: false),
          minX: spotsL1.first.x,
          maxX: spotsL1.last.x,
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spotsL1,
              isCurved: true,
              color: AppColors.brandAccent,
              barWidth: 2,
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: spotsArb,
              isCurved: true,
              color: const Color(0xFF3B82F6),
              barWidth: 2,
              dotData: const FlDotData(show: false),
            ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              _buildHorizontalLine(curL1, AppColors.brandAccent, 'Hyperliquid L1', res),
              _buildHorizontalLine(curArb, const Color(0xFF3B82F6), 'Arbitrum', res),
            ],
          ),
        ), // LineChartData
        ), // LineChart
        ), // inner SizedBox
        ), // SingleChildScrollView
      ),   // outer SizedBox
    );     // ClipRRect
  }

  HorizontalLine _buildHorizontalLine(double value, Color color, String name, Responsive res) {
    return HorizontalLine(
      y: value,
      color: color.withOpacity(0.4),
      strokeWidth: 1,
      dashArray: [4, 4],
      label: HorizontalLineLabel(
        show: true,
        alignment: Alignment.topLeft,
        padding: const EdgeInsets.only(left: 4, bottom: 4),
        style: TextStyle(
          color: color,
          fontSize: res.fontSize(8),
          fontWeight: FontWeight.bold,
          background: Paint()..color = const Color(0xFF0D0F14)..strokeWidth = 10..style = PaintingStyle.stroke..strokeJoin = StrokeJoin.round,
        ),
        labelResolver: (line) => name,
      ),
    );
  }

  Widget _metricTile(String label, double? val, Responsive res) {
    if (val == null) return Expanded(child: Center(child: Text('-',
      style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(11)))));
    final isUp = val >= 0;
    return Expanded(
      child: Column(children: [
        Text(label, style: GoogleFonts.inter(
          color: AppColors.textSecondary, fontSize: res.fontSize(8), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        SizedBox(height: res.spacing(6)),
        Text('${isUp ? '+' : ''}${val.toStringAsFixed(2)}%',
          style: GoogleFonts.jetBrainsMono(
            color: isUp ? AppColors.trendGreen : AppColors.trendRed,
            fontSize: res.fontSize(12), fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _divider() => Container(width: 1, height: 32, color: Colors.white.withOpacity(0.07));

  // ── Chain breakdown card ───────────────────────────────────────
  Widget _chainBreakdownCard(HlTvlSummary s, Responsive res) {
    return AppCard(
      padding: EdgeInsets.all(res.spacing(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CHAIN BREAKDOWN', style: GoogleFonts.jetBrainsMono(
                color: AppColors.textSecondary, fontSize: res.fontSize(10), fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              _buildChainToggle(res),
            ],
          ),
          SizedBox(height: res.spacing(16)),
          _showChainPie ? _buildChainPieView(s, res) : _buildChainBarView(s, res),
        ],
      ),
    );
  }

  Widget _buildChainToggle(Responsive res) {
    return Container(
      padding: EdgeInsets.all(res.spacing(4)),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleIcon(Icons.leaderboard_rounded, !_showChainPie, () => setState(() => _showChainPie = false), res),
          SizedBox(width: res.spacing(4)),
          _toggleIcon(Icons.pie_chart_outline_rounded, _showChainPie, () => setState(() => _showChainPie = true), res),
        ],
      ),
    );
  }

  Widget _toggleIcon(IconData icon, bool active, VoidCallback onTap, Responsive res) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: res.spacing(8), vertical: res.spacing(4)),
        decoration: BoxDecoration(
          color: active ? AppColors.brandAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: res.fontSize(14), color: active ? Colors.black : AppColors.textSecondary),
      ),
    );
  }

  Widget _buildChainBarView(HlTvlSummary s, Responsive res) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: s.chainBreakdown.map((c) => _chainRow(c, res)).toList(),
    );
  }

  Widget _buildChainPieView(HlTvlSummary s, Responsive res) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Donut Chart
            SizedBox(
              height: res.spacing(156),
              width: res.spacing(156),
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: res.spacing(48),
                  startDegreeOffset: -90,
                  sections: s.chainBreakdown.asMap().entries.map((entry) {
                    final idx = entry.value.name.contains('L1') ? 0 : 1;
                    final color = idx == 0 ? AppColors.brandAccent : const Color(0xFF3B82F6);
                    return PieChartSectionData(
                      color: color,
                      value: entry.value.percentage,
                      radius: res.spacing(20),
                      showTitle: false,
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Legend
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: s.chainBreakdown.asMap().entries.map((entry) {
                  final c = entry.value;
                  final idx = c.name.contains('L1') ? 0 : 1;
                  final color = idx == 0 ? AppColors.brandAccent : const Color(0xFF3B82F6);
                  return Padding(
                    padding: EdgeInsets.only(bottom: res.spacing(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(width: res.fontSize(8), height: res.fontSize(8), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            SizedBox(width: res.spacing(8)),
                            Text(c.name, style: GoogleFonts.inter(color: Colors.white, fontSize: res.fontSize(11), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: res.spacing(16), top: res.spacing(2)),
                          child: Text('${fmtTvl(c.value)} (${c.percentage.toStringAsFixed(1)}%)',
                            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: res.fontSize(10))),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        Divider(color: Colors.white10, height: res.spacing(24)),
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: res.fontSize(10), fontWeight: FontWeight.w600)),
              SizedBox(height: res.spacing(4)),
              Text(fmtTvl(s.tvl.total), style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: res.fontSize(14), fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chainRow(HlChainBreakdown c, Responsive res) {
    final colors = [AppColors.brandAccent, const Color(0xFF7C3AED)];
    final idx = c.name.contains('L1') ? 0 : 1;
    final color = colors[idx % colors.length];
    return Padding(
      padding: EdgeInsets.only(bottom: res.spacing(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(c.name, style: GoogleFonts.jetBrainsMono(
            color: Colors.white, fontSize: res.fontSize(11), fontWeight: FontWeight.w700)),
          Row(children: [
            Text(fmtTvl(c.value), style: GoogleFonts.jetBrainsMono(
              color: Colors.white, fontSize: res.fontSize(11), fontWeight: FontWeight.w700)),
            SizedBox(width: res.spacing(8)),
            Text('${c.percentage.toStringAsFixed(1)}%', style: GoogleFonts.jetBrainsMono(
              color: color, fontSize: res.fontSize(11), fontWeight: FontWeight.w800)),
          ]),
        ]),
        SizedBox(height: res.spacing(6)),
        LayoutBuilder(builder: (_, constraints) => ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Stack(children: [
            Container(height: res.spacing(5), width: double.infinity, color: Colors.white.withOpacity(0.06)),
            Container(
              height: res.spacing(5),
              width: constraints.maxWidth * (c.percentage / 100).clamp(0.0, 1.0),
              decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3),
                boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4)]),
            ),
          ]),
        )),
      ]),
    );
  }

  // ── Ecosystem card ─────────────────────────────────────────────
  // ── Detail dialog ──────────────────────────────────────────────
  void _showDetailDialog(HlTvlSummary s) {
    final res = Responsive(context);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF111418),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(res.spacing(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(s.metadata.logo, width: res.spacing(36), height: res.spacing(36), fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(Icons.currency_exchange, color: AppColors.brandAccent, size: res.fontSize(22))),
              ),
              SizedBox(width: res.spacing(10)),
              Expanded(child: Text(s.metadata.name,
                style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: res.fontSize(15), fontWeight: FontWeight.bold))),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close_rounded, color: AppColors.textSecondary, size: res.fontSize(20)),
              ),
            ]),
            SizedBox(height: res.spacing(14)),
            Text(s.metadata.description,
              style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: res.fontSize(10), height: 1.6)),
            SizedBox(height: res.spacing(16)),
            _dialogRow('Website', s.metadata.url, res),
            _dialogRow('Twitter', '@${s.metadata.twitter}', res),
            _dialogRow('Last Updated', fmtDate(s.lastUpdated), res),
            SizedBox(height: res.spacing(14)),
            Text('CHAIN BREAKDOWN', style: GoogleFonts.jetBrainsMono(
              color: AppColors.textSecondary, fontSize: res.fontSize(9), fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            SizedBox(height: res.spacing(8)),
            ...s.chainBreakdown.map((c) => Padding(
              padding: EdgeInsets.only(bottom: res.spacing(6)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(c.name, style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: res.fontSize(11))),
                Text('${fmtTvl(c.value)}  ${c.percentage.toStringAsFixed(1)}%',
                  style: GoogleFonts.jetBrainsMono(color: AppColors.brandAccent, fontSize: res.fontSize(11), fontWeight: FontWeight.bold)),
              ]),
            )),
            SizedBox(height: res.spacing(14)),
            Text('ECOSYSTEM', style: GoogleFonts.jetBrainsMono(
              color: AppColors.textSecondary, fontSize: res.fontSize(9), fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            SizedBox(height: res.spacing(8)),
            Wrap(spacing: res.spacing(8), runSpacing: res.spacing(8),
              children: s.ecosystem.map((e) => Container(
                padding: EdgeInsets.symmetric(horizontal: res.spacing(10), vertical: res.spacing(5)),
                decoration: BoxDecoration(
                  color: AppColors.brandAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.brandAccent.withOpacity(0.2)),
                ),
                child: Text(e.name, style: GoogleFonts.jetBrainsMono(
                  color: AppColors.brandAccent, fontSize: res.fontSize(9), fontWeight: FontWeight.w700)),
              )).toList()),
          ]),
        ),
      ),
    );
  }

  Widget _dialogRow(String label, String value, Responsive res) {
    return Padding(
      padding: EdgeInsets.only(bottom: res.spacing(8)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: res.spacing(90), child: Text(label, style: GoogleFonts.inter(
          color: AppColors.textSecondary, fontSize: res.fontSize(10), fontWeight: FontWeight.w600))),
        Expanded(child: Text(value, style: GoogleFonts.jetBrainsMono(
          color: Colors.white, fontSize: res.fontSize(10)), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  // ── Loading / error ────────────────────────────────────────────
  Widget _buildLoading() {
    final res = Responsive(context);
    return Shimmer.fromColors(
      baseColor: const Color(0xFF323645),
      highlightColor: const Color(0xFF4A4F60),
      period: const Duration(milliseconds: 1400),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(res.spacing(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Shimmer
            _sh(res, 56, 0, radius: 16),
            SizedBox(height: res.spacing(16)),
            // Stat Cards Shimmer
            Row(children: [
              Expanded(child: _sh(res, 90, 0, radius: 16)),
              SizedBox(width: res.spacing(10)),
              Expanded(child: _sh(res, 90, 0, radius: 16)),
              SizedBox(width: res.spacing(10)),
              Expanded(child: _sh(res, 90, 0, radius: 16)),
            ]),
            SizedBox(height: res.spacing(16)),
            // Chain Breakdown Shimmer
            _sh(res, 180, 0, radius: 16),
            SizedBox(height: res.spacing(16)),
            // Main Chart Shimmer
            _sh(res, 300, 0, radius: 20),
            SizedBox(height: res.spacing(16)),
            // Secondary Chart Shimmer
            _sh(res, 300, 0, radius: 20),
            SizedBox(height: res.spacing(24)),
            // Bottom Cards Shimmer
            _sh(res, 150, 0, radius: 16),
            SizedBox(height: res.spacing(16)),
            _sh(res, 200, 0, radius: 16),
          ],
        ),
      ),
    );
  }

  Widget _sh(Responsive res, double h, double inset, {double radius = 12}) => Container(
    height: h,
    margin: EdgeInsets.symmetric(vertical: 2),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(radius),
    ),
  );

  Widget _buildError(HlTvlViewModel vm) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(vm.error, style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 12),
        textAlign: TextAlign.center),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: vm.fetchAll,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.brandAccent.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('RETRY', style: GoogleFonts.jetBrainsMono(
            color: AppColors.brandAccent, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ),
    ]));
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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
            child: const Icon(Icons.arrow_back, color: AppColors.brandAccent),
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
          if (m != null) ...[
            _metricsCard(m, res),
            SizedBox(height: res.spacing(16)),
          ],
          _chainBreakdownCard(s, res),
          SizedBox(height: res.spacing(16)),
          _ecosystemCard(s, res),
          const SizedBox(height: 24),
        ],
      ),
    );
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
              width: 44, height: 44, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.brandAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.currency_exchange, color: AppColors.brandAccent, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(s.metadata.name,
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white, fontSize: res.fontSize(14), fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  const Icon(Icons.verified, size: 14, color: AppColors.brandAccent),
                ]),
                const SizedBox(height: 4),
                Text(
                  s.metadata.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary, fontSize: res.fontSize(9)),
                ),
                const SizedBox(height: 8),
                _viewAllButton(s, res),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('MARKET CAP', style: GoogleFonts.inter(
                color: AppColors.textSecondary, fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(height: 3),
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
            color: AppColors.brandAccent, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(width: 3),
          const Icon(Icons.chevron_right_rounded, size: 13, color: AppColors.brandAccent),
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
              color: AppColors.textSecondary, fontSize: res.value(mobile: 9, tablet: 8, desktop: 10),
              fontWeight: FontWeight.w600, letterSpacing: 0.5))),
            Container(
              padding: EdgeInsets.all(res.value(mobile: 6, tablet: 4, desktop: 6)),
              decoration: BoxDecoration(
                color: AppColors.brandAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: AppColors.brandAccent, size: res.value(mobile: 14, tablet: 12, desktop: 16)),
            ),
          ]),
          SizedBox(height: res.spacing(6)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: GoogleFonts.inter(
              color: valueColor ?? Colors.white,
              fontSize: res.value(mobile: 15, tablet: 13, desktop: 16),
              fontWeight: FontWeight.bold)),
          ),
          if (badge != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              if (!badgeIsDate)
                Icon(badgeUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: badgeUp ? AppColors.trendGreen : AppColors.trendRed, size: 14),
              Flexible(child: Text(badge, style: GoogleFonts.inter(
                color: badgeIsDate
                    ? AppColors.textSecondary
                    : (badgeUp ? AppColors.trendGreen : AppColors.trendRed),
                fontSize: res.value(mobile: 9, tablet: 8, desktop: 10),
                fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis)),
            ]),
          ],
        ],
      ),
    );
  }

  // ── Advanced metrics card ──────────────────────────────────────
  Widget _metricsCard(HlTvlMetrics m, Responsive res) {
    return AppCard(
      padding: EdgeInsets.all(res.spacing(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GROWTH METRICS', style: GoogleFonts.jetBrainsMono(
            color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          SizedBox(height: res.spacing(12)),
          Row(children: [
            _metricTile('30D', m.change30d, res),
            _divider(),
            _metricTile('90D', m.change90d, res),
            _divider(),
            _metricTile('1Y', m.change1y, res),
            _divider(),
            _metricTile('DRAWDOWN', m.drawdown, res),
          ]),
        ],
      ),
    );
  }

  Widget _metricTile(String label, double? val, Responsive res) {
    if (val == null) return Expanded(child: Center(child: Text('-',
      style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 11))));
    final isUp = val >= 0;
    return Expanded(
      child: Column(children: [
        Text(label, style: GoogleFonts.inter(
          color: AppColors.textSecondary, fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 6),
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
                color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              _buildChainToggle(),
            ],
          ),
          SizedBox(height: res.spacing(16)),
          _showChainPie ? _buildChainPieView(s, res) : _buildChainBarView(s, res),
        ],
      ),
    );
  }

  Widget _buildChainToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleIcon(Icons.leaderboard_rounded, !_showChainPie, () => setState(() => _showChainPie = false)),
          const SizedBox(width: 4),
          _toggleIcon(Icons.pie_chart_outline_rounded, _showChainPie, () => setState(() => _showChainPie = true)),
        ],
      ),
    );
  }

  Widget _toggleIcon(IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.brandAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: active ? Colors.black : AppColors.textSecondary),
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
              height: res.value(mobile: 130, tablet: 156, desktop: 180),
              width: res.value(mobile: 130, tablet: 156, desktop: 180),
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: res.value(mobile: 40, tablet: 48, desktop: 56),
                  startDegreeOffset: -90,
                  sections: s.chainBreakdown.asMap().entries.map((entry) {
                    final idx = entry.value.name.contains('L1') ? 0 : 1;
                    final color = idx == 0 ? AppColors.brandAccent : const Color(0xFF3B82F6);
                    return PieChartSectionData(
                      color: color,
                      value: entry.value.percentage,
                      radius: 20,
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
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(c.name, style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 2),
                          child: Text('${fmtTvl(c.value)} (${c.percentage.toStringAsFixed(1)}%)',
                            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 10)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        const Divider(color: Colors.white10, height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(fmtTvl(s.tvl.total), style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(c.name, style: GoogleFonts.jetBrainsMono(
            color: Colors.white, fontSize: res.fontSize(11), fontWeight: FontWeight.w700)),
          Row(children: [
            Text(fmtTvl(c.value), style: GoogleFonts.jetBrainsMono(
              color: Colors.white, fontSize: res.fontSize(11), fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Text('${c.percentage.toStringAsFixed(1)}%', style: GoogleFonts.jetBrainsMono(
              color: color, fontSize: res.fontSize(11), fontWeight: FontWeight.w800)),
          ]),
        ]),
        const SizedBox(height: 6),
        LayoutBuilder(builder: (_, constraints) => ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Stack(children: [
            Container(height: 5, width: double.infinity, color: Colors.white.withOpacity(0.06)),
            Container(
              height: 5,
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
  Widget _ecosystemCard(HlTvlSummary s, Responsive res) {
    return AppCard(
      padding: EdgeInsets.all(res.spacing(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ECOSYSTEM', style: GoogleFonts.jetBrainsMono(
            color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          SizedBox(height: res.spacing(10)),
          Wrap(spacing: 8, runSpacing: 8,
            children: s.ecosystem.map((e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.brandAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.brandAccent.withOpacity(0.2)),
              ),
              child: Text(e.name, style: GoogleFonts.jetBrainsMono(
                color: AppColors.brandAccent, fontSize: 9, fontWeight: FontWeight.w700)),
            )).toList()),
        ],
      ),
    );
  }

  // ── Detail dialog ──────────────────────────────────────────────
  void _showDetailDialog(HlTvlSummary s) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF111418),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(s.metadata.logo, width: 36, height: 36, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.currency_exchange, color: AppColors.brandAccent, size: 22)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(s.metadata.name,
                style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold))),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
              ),
            ]),
            const SizedBox(height: 14),
            Text(s.metadata.description,
              style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 10, height: 1.6)),
            const SizedBox(height: 16),
            _dialogRow('Website', s.metadata.url),
            _dialogRow('Twitter', '@${s.metadata.twitter}'),
            _dialogRow('Last Updated', fmtDate(s.lastUpdated)),
            const SizedBox(height: 14),
            Text('CHAIN BREAKDOWN', style: GoogleFonts.jetBrainsMono(
              color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            ...s.chainBreakdown.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(c.name, style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 11)),
                Text('${fmtTvl(c.value)}  ${c.percentage.toStringAsFixed(1)}%',
                  style: GoogleFonts.jetBrainsMono(color: AppColors.brandAccent, fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
            )),
            const SizedBox(height: 14),
            Text('ECOSYSTEM', style: GoogleFonts.jetBrainsMono(
              color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8,
              children: s.ecosystem.map((e) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.brandAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.brandAccent.withOpacity(0.2)),
                ),
                child: Text(e.name, style: GoogleFonts.jetBrainsMono(
                  color: AppColors.brandAccent, fontSize: 9, fontWeight: FontWeight.w700)),
              )).toList()),
          ]),
        ),
      ),
    );
  }

  Widget _dialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 90, child: Text(label, style: GoogleFonts.inter(
          color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600))),
        Expanded(child: Text(value, style: GoogleFonts.jetBrainsMono(
          color: Colors.white, fontSize: 10), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  // ── Loading / error ────────────────────────────────────────────
  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator(color: AppColors.brandAccent, strokeWidth: 2));
  }

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

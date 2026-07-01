import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/protocol_model.dart';
import '../services/protocol_service.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';

class ProtocolDetailScreen extends StatefulWidget {
  final String slug;
  final String? name;
  final String? logo;

  const ProtocolDetailScreen({
    super.key,
    required this.slug,
    this.name,
    this.logo,
  });

  @override
  State<ProtocolDetailScreen> createState() => _ProtocolDetailScreenState();
}

class _ProtocolDetailScreenState extends State<ProtocolDetailScreen> {
  final ProtocolService _service = ProtocolService();
  ProtocolDetail? _detail;
  bool _isLoading = true;
  String _error = '';
  bool _showChainPieChart = false;
  int _touchedChainIndex = -1;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() { _isLoading = true; _error = ''; });
    try {
      final detail = await _service.getProjectDetail(widget.slug);
      if (mounted) setState(() { _detail = detail; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'TVL Dashboard',
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.textSecondary,
            fontSize: res.fontSize(13),
          ),
        ),
        titleSpacing: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandAccent))
          : _error.isNotEmpty
              ? _buildError(res)
              : _buildContent(res),
    );
  }

  Widget _buildError(Responsive res) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: AppColors.trendRed, size: 48),
          const SizedBox(height: 12),
          Text(_error, style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchDetail,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandAccent),
            child: Text('Retry', style: GoogleFonts.jetBrainsMono(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Responsive res) {
    final d = _detail!;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(res.spacing(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(d, res),
          SizedBox(height: res.spacing(20)),
          _buildTvlHero(d, res),
          SizedBox(height: res.spacing(20)),
          _buildTvlChart(d, res),
          SizedBox(height: res.spacing(20)),
          _buildChainTvls(d, res),
          SizedBox(height: res.spacing(20)),
          _buildAboutSection(d, res),
          SizedBox(height: res.spacing(32)),
          _buildFooter(res),
          SizedBox(height: res.spacing(16)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HEADER — Logo, name, category badges, links
  // ═══════════════════════════════════════════════════════════
  Widget _buildHeader(ProtocolDetail d, Responsive res) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBright.withOpacity(0.3)),
            color: AppColors.surfaceBright.withOpacity(0.1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              d.logo,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.token, color: AppColors.textSecondary, size: 28),
            ),
          ),
        ),
        SizedBox(width: res.spacing(16)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                d.name,
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: res.fontSize(22),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _badge(d.category, AppColors.brandAccent),
                  _badge(d.type.toUpperCase(), d.type == 'core' ? AppColors.brandAccent : AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (d.url.isNotEmpty) _linkChip(Icons.language, 'Website', d.url),
                  if (d.twitter != null) ...[
                    const SizedBox(width: 8),
                    _linkChip(Icons.alternate_email, '@${d.twitter}', 'https://x.com/${d.twitter}'),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _linkChip(IconData icon, String label, String url) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceBright.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surfaceBright.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.brandAccent),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TVL HERO — Big number + change badges
  // ═══════════════════════════════════════════════════════════
  Widget _buildTvlHero(ProtocolDetail d, Responsive res) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(res.spacing(20)),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandAccent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, size: 14, color: AppColors.brandAccent.withOpacity(0.7)),
              const SizedBox(width: 6),
              Text(
                'TOTAL VALUE LOCKED',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              d.fullTvl,
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontSize: res.fontSize(32),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _changeBadge('1H CHANGE', d.change1h),
              const SizedBox(width: 10),
              _changeBadge('1D CHANGE', d.change1d),
              const SizedBox(width: 10),
              _changeBadge('7D CHANGE', d.change7d),
            ],
          ),
        ],
      ),
    );
  }

  Widget _changeBadge(String label, double value) {
    final isPositive = value >= 0;
    final color = isPositive ? AppColors.trendGreen : AppColors.trendRed;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2), width: 0.5),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 7, letterSpacing: 0.5),
            ),
            const SizedBox(height: 3),
            Text(
              '${isPositive ? "+" : ""}${value.toStringAsFixed(2)}%',
              style: GoogleFonts.jetBrainsMono(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TVL CHART — Historical line graph
  // ═══════════════════════════════════════════════════════════
  Widget _buildTvlChart(ProtocolDetail d, Responsive res) {
    if (d.historicalTvl.isEmpty) return const SizedBox.shrink();

    final spots = d.historicalTvl.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList();
    final vals = d.historicalTvl.map((e) => e.value).toList();
    final minY = vals.reduce((a, b) => a < b ? a : b);
    final maxY = vals.reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final interval = range > 0 ? range / 5 : (maxY > 0 ? maxY / 5 : 1.0);

    return Container(
      height: 240,
      padding: EdgeInsets.all(res.spacing(16)),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBright.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded, size: 14, color: AppColors.brandAccent),
              const SizedBox(width: 8),
              Text(
                'Historical TVL',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.surfaceBright.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      interval: interval,
                      getTitlesWidget: (val, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            _fmtCompact(val),
                            textAlign: TextAlign.right,
                            style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 8),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (val, meta) {
                        final i = val.toInt();
                        if (i < 0 || i >= d.historicalTvl.length) return const SizedBox();
                        if (i % (d.historicalTvl.length ~/ 4) != 0 && i != d.historicalTvl.length - 1) return const SizedBox();
                        final date = d.historicalTvl[i].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat('MMM yy').format(date),
                            style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 8),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.brandAccent,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.brandAccent.withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surfaceBright,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((s) {
                        final i = s.x.toInt();
                        final date = DateFormat('MMM dd, yyyy').format(d.historicalTvl[i].date);
                        return LineTooltipItem(
                          '${_fmtLargeNum(s.y)}\n$date',
                          GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtCompact(double n) {
    if (n >= 1e9) return '${(n / 1e9).toStringAsFixed(1)}B';
    if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)}M';
    if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(0)}K';
    return n.toStringAsFixed(0);
  }

  // ═══════════════════════════════════════════════════════════
  // PROTOCOL STATS — Market Cap, Mcap/TVL
  // ═══════════════════════════════════════════════════════════
  Widget _buildStatsSection(ProtocolDetail d, Responsive res) {
    final hasMcap = d.mcap != null && d.mcap! > 0;
    final hasRatio = d.mcapTvlRatio != null && d.mcapTvlRatio! > 0;

    return Container(
      padding: EdgeInsets.all(res.spacing(16)),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBright.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, size: 14, color: AppColors.brandAccent),
              const SizedBox(width: 8),
              Text(
                'Protocol Stats',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (hasMcap) ...[
            _statRow('Market Cap', _fmtLargeNum(d.mcap!)),
            const Divider(color: AppColors.surfaceBright, height: 20),
          ],
          if (hasRatio) ...[
            _statRow('Mcap/TVL Ratio', d.mcapTvlRatio!.toStringAsFixed(2)),
            const Divider(color: AppColors.surfaceBright, height: 20),
          ],
          
          Text(
            'Supported Chains',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: d.chains.map((chain) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceBright.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.surfaceBright.withOpacity(0.2)),
              ),
              child: Text(
                chain,
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )).toList(),
          ),
          if (d.type != 'other') ...[
            const Divider(color: AppColors.surfaceBright, height: 24),
            _statRow('Type', d.type.toUpperCase()),
          ],
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 11)),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TVL BY CHAIN — sorted list with percentage bars
  // ═══════════════════════════════════════════════════════════
  Widget _buildChainTvls(ProtocolDetail d, Responsive res) {
    if (d.chainTvls.isEmpty) return const SizedBox.shrink();

    // Sort by TVL descending
    final sorted = d.chainTvls.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final totalChainTvl = sorted.fold<double>(0, (sum, e) => sum + e.value);

    return Container(
      padding: EdgeInsets.all(res.spacing(16)),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBright.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.account_tree_rounded, size: 14, color: AppColors.brandAccent),
                  const SizedBox(width: 8),
                  Text(
                    'TVL by Chain',
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Toggle
              Container(
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBright.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildToggleBtn(Icons.list_rounded, !_showChainPieChart, () => setState(() => _showChainPieChart = false)),
                    _buildToggleBtn(Icons.pie_chart_outline_rounded, _showChainPieChart, () => setState(() => _showChainPieChart = true)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_showChainPieChart)
            _buildChainPieChart(sorted, totalChainTvl)
          else
            Column(
              children: sorted.map((entry) {
                final pct = totalChainTvl > 0 ? (entry.value / totalChainTvl * 100) : 0.0;
                return _chainRow(entry.key, entry.value, pct, res);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.brandAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active ? [
            BoxShadow(
              color: AppColors.brandAccent.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: active ? Colors.black : AppColors.textSecondary),
            if (active) ...[
              const SizedBox(width: 6),
              Text(
                active && icon == Icons.list_rounded ? 'LIST' : 'PIE',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.black,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  Widget _buildChainPieChart(List<MapEntry<String, double>> data, double total) {
    if (data.isEmpty) return const SizedBox.shrink();

    // Group small values into "Others"
    double othersTvl = 0;
    final List<MapEntry<String, double>> processedData = [];
    
    // Threshold 2%
    const threshold = 0.02;
    
    for (var entry in data) {
      if (total > 0 && (entry.value / total) < threshold) {
        othersTvl += entry.value;
      } else {
        processedData.add(entry);
      }
    }
    
    if (othersTvl > 0) {
      processedData.add(MapEntry('Others', othersTvl));
    }

    // Sort by TVL descending
    processedData.sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      AppColors.brandAccent,
      const Color(0xFF7C3AED),
      const Color(0xFFD97706),
      const Color(0xFF0D9488),
      const Color(0xFF60A5FA),
      const Color(0xFFF43F5E),
      const Color(0xFF10B981),
      const Color(0xFF8B5CF6),
    ];

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedChainIndex = -1;
                      return;
                    }
                    _touchedChainIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sectionsSpace: 0,
              centerSpaceRadius: 50,
              sections: processedData.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final isTouched = _touchedChainIndex == i;
                final pct = total > 0 ? (item.value / total * 100) : 0.0;
                final showTitle = pct > 4 || isTouched;
                return PieChartSectionData(
                  color: colors[i % colors.length],
                  value: item.value,
                  title: showTitle ? '${pct.toStringAsFixed(0)}%' : '',
                  radius: isTouched ? 65 : 55,
                  titleStyle: GoogleFonts.jetBrainsMono(
                    color: Colors.white,
                    fontSize: isTouched ? 12 : 10,
                    fontWeight: FontWeight.bold,
                  ),
                  badgeWidget: isTouched ? _chainBadge(item.key, item.value) : null,
                  badgePositionPercentageOffset: 1.4,
                  borderSide: isTouched 
                      ? const BorderSide(color: Colors.white, width: 2) 
                      : BorderSide.none,
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Color Legend
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(processedData.length, (i) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors[i % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  processedData[i].key.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _chainBadge(String name, double value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.brandAccent.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(color: AppColors.brandAccent, fontSize: 9, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            _fmtLargeNum(value),
            style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _chainRow(String chain, double tvl, double pct, Responsive res) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final labelWidth = 100.0;
          return Row(
            children: [
              SizedBox(
                width: labelWidth,
                child: Row(
                  children: [
                    _buildChainLogo(chain),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        chain.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBright.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutQuart,
                      height: 20,
                      width: (constraints.maxWidth - labelWidth - 10 - 70) * (pct / 100),
                      decoration: BoxDecoration(
                        color: AppColors.brandAccent.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${pct.toStringAsFixed(1)}%',
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white, 
                          fontSize: 8.5, 
                          fontWeight: FontWeight.w900,
                          shadows: [const Shadow(color: Colors.black45, blurRadius: 2)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 60,
                child: Text(
                  _fmtLargeNum(tvl),
                  textAlign: TextAlign.right,
                  style: GoogleFonts.jetBrainsMono(color: AppColors.brandAccent, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ABOUT SECTION — description
  // ═══════════════════════════════════════════════════════════
  Widget _buildAboutSection(ProtocolDetail d, Responsive res) {
    if (d.description.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(res.spacing(16)),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBright.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: AppColors.brandAccent),
              const SizedBox(width: 8),
              Text(
                'About ${d.name}',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            d.description,
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FOOTER
  // ═══════════════════════════════════════════════════════════
  Widget _buildFooter(Responsive res) {
    return Center(
      child: Text(
        'Data powered by DefiLlama & Hyperliquid API',
        style: GoogleFonts.jetBrainsMono(
          color: AppColors.textSecondary.withOpacity(0.4),
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _buildChainLogo(String chain) {
    final chainSlug = chain.toLowerCase().replaceAll(' ', '-');
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          'https://icons.llamao.fi/icons/chains/rsz_$chainSlug.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.brandAccent,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  String _fmtLargeNum(double val) {
    if (val >= 1e9) return '\$${(val / 1e9).toStringAsFixed(2)}B';
    if (val >= 1e6) return '\$${(val / 1e6).toStringAsFixed(2)}M';
    if (val >= 1e3) return '\$${(val / 1e3).toStringAsFixed(0)}K';
    return '\$${val.toStringAsFixed(0)}';
  }
}

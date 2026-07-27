import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/fee_intelligence_model.dart';
import '../services/fee_intelligence_service.dart';
import '../utils/app_colors.dart';
import '../utils/common_widgets.dart';
import '../utils/responsive.dart';
import '../widgets/error_state_widget.dart';


class FeeProtocolDetailScreen extends StatefulWidget {
  final FeeTopProtocol protocol;
  final bool isRevenue;
  final String? dataType;

  const FeeProtocolDetailScreen({
    super.key,
    required this.protocol,
    this.isRevenue = false,
    this.dataType,
  });

  @override
  State<FeeProtocolDetailScreen> createState() => _FeeProtocolDetailScreenState();
}

class _FeeProtocolDetailScreenState extends State<FeeProtocolDetailScreen> {
  final FeeIntelligenceService _service = FeeIntelligenceService();
  final ScrollController _chartScrollController = ScrollController();

  bool _isLoading = true;
  String _errorMessage = '';
  List<DateTime> _dates = [];
  List<double> _chartValues = [];

  String _selectedRange = '90d'; // 7d, 30d, 90d, 1y, all
  String _chartMode = 'area';    // area, bar

  Widget _buildChartShimmer(Responsive res) {
    return AppCard(
      padding: EdgeInsets.all(res.spacing(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: res.spacing(100),
                    height: res.spacing(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: res.spacing(6)),
                  Container(
                    width: res.spacing(180),
                    height: res.spacing(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: res.spacing(12)),
          Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
          SizedBox(height: res.spacing(10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: res.spacing(140),
                height: res.spacing(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Container(
                width: res.spacing(80),
                height: res.spacing(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          SizedBox(height: res.spacing(24)),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) => 
                  Container(
                    width: double.infinity,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.05),
                    margin: EdgeInsets.symmetric(horizontal: res.spacing(12)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tooltip tracking: index of the spot currently showing tooltip
  int? _hoveredSpotIndex;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _chartScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _hoveredSpotIndex = null;
    });

    try {
      final res = await _service.fetchCompare(
        [widget.protocol.slug],
        range: _selectedRange,
        isRevenue: widget.isRevenue,
        dataType: widget.dataType,
      );

      final slug = widget.protocol.slug;
      if (res.series.containsKey(slug)) {
        setState(() {
          _dates = res.labels;
          _chartValues = res.series[slug] ?? [];
          _isLoading = false;
        });

        // Auto Scroll chart to the very end (latest values on right)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_chartScrollController.hasClients) {
            _chartScrollController.jumpTo(_chartScrollController.position.maxScrollExtent);
          }
        });
      } else {
        setState(() {
          _dates = [];
          _chartValues = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _fmtMoney(double val) {
    if (val == 0) return '\$0';
    if (val >= 1e9) {
      return '\$${(val / 1e9).toStringAsFixed(2)}B';
    } else if (val >= 1e6) {
      return '\$${(val / 1e6).toStringAsFixed(2)}M';
    } else if (val >= 1e3) {
      return '\$${(val / 1e3).toStringAsFixed(2)}K';
    }
    return '\$${val.toStringAsFixed(2)}';
  }

  String _fmtPct(double val) {
    final sign = val > 0 ? '+' : '';
    return '$sign${val.toStringAsFixed(2)}%';
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
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.brandAccent,
              size: res.fontSize(20),
            ),
          ),
          titleSpacing: 0,
          title: Text(
            widget.dataType == 'holders-revenue'
                ? 'Holders Revenue / ${widget.protocol.name}'
                : (widget.isRevenue 
                    ? 'Revenue Intelligence / ${widget.protocol.name}' 
                    : 'Fee Intelligence / ${widget.protocol.name}'),
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white,
              fontSize: res.fontSize(14),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _loadHistory,
          color: AppColors.brandAccent,
          backgroundColor: AppColors.background,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(res.spacing(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(res),
                  SizedBox(height: res.spacing(12)),
                  _buildUnifiedMetrics(res),
                  SizedBox(height: res.spacing(12)),
                  _buildChartCard(res),
                  SizedBox(height: res.spacing(12)),
                  _buildSubProtocolsCard(res),
                  SizedBox(height: res.spacing(24)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  APP HEADER CARD
  // ════════════════════════════════════════════════════════════
  Widget _buildHeaderCard(Responsive res) {
    final p = widget.protocol;
    return AppCard(
      padding: EdgeInsets.all(res.spacing(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo
          Container(
            width: res.value(mobile: 44.0, tablet: 52.0),
            height: res.value(mobile: 44.0, tablet: 52.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceBright.withOpacity(0.3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: p.logo != null && p.logo!.isNotEmpty
                  ? Image.network(
                      p.logo!,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.token,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                    )
                  : const Icon(
                      Icons.token,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
            ),
          ),
          SizedBox(width: res.spacing(12)),

          // Info (Name & Chain tags)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        p.name,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: res.fontSize(18),
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        p.protocolType.toUpperCase(),
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.textSecondary,
                          fontSize: res.fontSize(8.5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Chains list
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: p.chains.map((chain) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        chain,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: res.fontSize(9.5),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Sub-protocols badge on right if any
          if (p.children.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.brandAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.brandAccent.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Text(
                    '${p.children.length} sub-protocols',
                    style: GoogleFonts.inter(
                      color: AppColors.brandAccent,
                      fontSize: res.fontSize(10),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.open_in_new,
                    color: AppColors.brandAccent,
                    size: res.fontSize(11),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  METRICS ROW 1 (PRIMARY)
  // ════════════════════════════════════════════════════════════
  // ════════════════════════════════════════════════════════════
  //  UNIFIED DASHBOARD METRICS GRID (3x3 Layout)
  // ════════════════════════════════════════════════════════════
  Widget _buildUnifiedMetrics(Responsive res) {
    final p = widget.protocol;

    final cell1 = _buildGridCell(
      title: widget.dataType == 'holders-revenue' ? 'HOLDERS REVENUE 24H' : (widget.isRevenue ? 'REVENUE 24H' : 'FEES 24H'),
      value: _fmtMoney(p.fees24h),
      change: p.change1d,
      res: res,
    );
    final cell2 = _buildGridCell(
      title: widget.dataType == 'holders-revenue' ? 'HOLDERS REVENUE 7D' : (widget.isRevenue ? 'REVENUE 7D' : 'FEES 7D'),
      value: _fmtMoney(p.fees7d),
      change: p.change7d,
      res: res,
    );
    final cell3 = _buildGridCell(
      title: widget.dataType == 'holders-revenue' ? 'HOLDERS REVENUE 30D' : (widget.isRevenue ? 'REVENUE 30D' : 'FEES 30D'),
      value: _fmtMoney(p.fees30d),
      change: p.change30d,
      res: res,
    );

    final cell4 = _buildGridCell(
      title: widget.dataType == 'holders-revenue' ? 'HOLDERS REVENUE 1Y' : (widget.isRevenue ? 'REVENUE 1Y' : 'FEES 1Y'),
      value: _fmtMoney(p.fees1y),
      res: res,
    );
    final cell5 = _buildGridCell(
      title: 'ALL TIME',
      value: _fmtMoney(p.feesAllTime),
      res: res,
    );
    final cell6 = _buildGridCell(
      title: 'ANNUALIZED',
      value: _fmtMoney(p.annualized1y > 0 ? p.annualized1y : (p.fees24h * 365.25)),
      res: res,
    );

    final cell7 = _buildGridCell(
      title: 'AVG/DAY (1Y)',
      value: _fmtMoney(p.average1y > 0 ? p.average1y : (p.fees1y / 365.25)),
      res: res,
    );
    final cell8 = _buildGridCell(
      title: '1D CHANGE',
      value: _fmtPct(p.change1d),
      isPercentOnly: true,
      change: p.change1d,
      res: res,
    );
    final cell9 = _buildGridCell(
      title: '30D CHANGE',
      value: _fmtPct(p.change30d),
      isPercentOnly: true,
      change: p.change30d,
      res: res,
    );

    return AppCard(
      padding: EdgeInsets.symmetric(horizontal: res.spacing(12), vertical: res.spacing(16)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth > 700;
          if (isWide) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: cell1),
                    _verticalDivider(res),
                    Expanded(child: cell2),
                    _verticalDivider(res),
                    Expanded(child: cell3),
                    _verticalDivider(res),
                    Expanded(child: cell4),
                    _verticalDivider(res),
                    Expanded(child: cell5),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: res.spacing(8)),
                  child: Divider(color: Colors.white.withOpacity(0.05), height: 1),
                ),
                Row(
                  children: [
                    Expanded(child: cell6),
                    _verticalDivider(res),
                    Expanded(child: cell7),
                    _verticalDivider(res),
                    Expanded(child: cell8),
                    _verticalDivider(res),
                    Expanded(child: cell9),
                    _verticalDivider(res),
                    const Spacer(),
                  ],
                ),
              ],
            );
          } else {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: cell1),
                    _verticalDivider(res),
                    Expanded(child: cell2),
                    _verticalDivider(res),
                    Expanded(child: cell3),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: res.spacing(10)),
                  child: Divider(color: Colors.white.withOpacity(0.05), height: 1),
                ),
                Row(
                  children: [
                    Expanded(child: cell4),
                    _verticalDivider(res),
                    Expanded(child: cell5),
                    _verticalDivider(res),
                    Expanded(child: cell6),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: res.spacing(10)),
                  child: Divider(color: Colors.white.withOpacity(0.05), height: 1),
                ),
                Row(
                  children: [
                    Expanded(child: cell7),
                    _verticalDivider(res),
                    Expanded(child: cell8),
                    _verticalDivider(res),
                    Expanded(child: cell9),
                  ],
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _verticalDivider(Responsive res) {
    return Container(
      width: 1,
      height: res.spacing(38),
      margin: EdgeInsets.symmetric(horizontal: res.spacing(6)),
      color: Colors.white.withOpacity(0.05),
    );
  }

  Widget _buildGridCell({
    required String title,
    required String value,
    double? change,
    bool isPercentOnly = false,
    required Responsive res,
  }) {
    final isUp = change != null && change >= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: res.fontSize(8),
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              color: isPercentOnly && change != null
                  ? (isUp ? AppColors.trendGreen : AppColors.trendRed)
                  : Colors.white,
              fontSize: res.fontSize(13.5),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (change != null && !isPercentOnly) ...[
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: isUp ? AppColors.trendGreen : AppColors.trendRed,
                size: res.fontSize(12),
              ),
              Text(
                '${change.abs().toStringAsFixed(2)}%',
                style: GoogleFonts.inter(
                  color: isUp ? AppColors.trendGreen : AppColors.trendRed,
                  fontSize: res.fontSize(9),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  //  CHART CARD & CONTROLS
  // ════════════════════════════════════════════════════════════
  Widget _buildChartCard(Responsive res) {
    if (_isLoading) {
      return SizedBox(
        height: 380,
        child: Shimmer.fromColors(
          baseColor: const Color(0xFF1E222D),
          highlightColor: const Color(0xFF2E3340),
          child: _buildChartShimmer(res),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return ErrorStateWidget(
        errorMessage: _errorMessage,
        onRetry: _loadHistory,
      );
    }

    if (_chartValues.isEmpty) {
      return AppCard(
        height: 250,
        child: Center(
          child: Text(
            widget.dataType == 'holders-revenue' ? 'No historical holders revenue data found' : (widget.isRevenue ? 'No historical revenue data found' : 'No historical fee data found'),
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    // Chart dimensions
    final screenW = MediaQuery.of(context).size.width - res.spacing(24);
    const yAxisW = 76.0;
    final scrollAreaW = screenW - yAxisW;

    final n = _chartValues.length;
    final double pxPerBar;
    switch (_selectedRange) {
      case '7d':
        pxPerBar = scrollAreaW / 7;
        break;
      case '30d':
        pxPerBar = (scrollAreaW / 30).clamp(16.0, 48.0);
        break;
      case '90d':
        pxPerBar = (scrollAreaW / 90).clamp(6.0, 24.0);
        break;
      case '1y':
        pxPerBar = (scrollAreaW / 365).clamp(3.0, 10.0);
        break;
      default:
        pxPerBar = (scrollAreaW / n).clamp(3.0, 24.0);
    }

    final canvasW = (n * pxPerBar).clamp(scrollAreaW, scrollAreaW * 15);

    double minY = _chartValues.reduce((a, b) => a < b ? a : b);
    double maxY = _chartValues.reduce((a, b) => a > b ? a : b);
    if (minY == maxY) {
      minY = minY * 0.9;
      maxY = maxY * 1.1;
    }
    final range = maxY - minY;
    final double interval = range > 0 ? range / 5 : (maxY > 0 ? maxY / 5 : 1.0);
    final chartMinY = (minY - interval * 0.2).clamp(0.0, double.infinity);
    final chartMaxY = maxY + interval * 0.2;

    return AppCard(
      padding: EdgeInsets.all(res.spacing(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.dataType == 'holders-revenue' ? 'Holders Revenue History' : (widget.isRevenue ? 'Revenue History' : 'Fee History'),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: res.fontSize(14),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${n} daily data points · scroll to zoom · drag to pan',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: res.fontSize(9),
                    ),
                  ),
                ],
              ),
              // Download/Export or toggle options
              const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
          const SizedBox(height: 8),

          // Toggles row (Time ranges on left, Chart modes on right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRangeToggles(),
              _buildModeToggles(),
            ],
          ),
          const SizedBox(height: 16),

          // Sized box wrapper for chart & floating Y scale
          SizedBox(
            height: 250,
            child: Stack(
              children: [
                _ChartWithPinnedYAxis(
                  height: 250,
                  yAxisW: yAxisW,
                  canvasW: canvasW,
                  scrollController: _chartScrollController,
                  yAxisWidget: _buildYAxisScale(chartMinY, chartMaxY, interval),
                  chartBuilder: (chartWidth) => Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: _chartMode == 'bar'
                        ? _buildBarChart(chartMinY, chartMaxY, interval)
                        : _buildAreaChart(chartMinY, chartMaxY, interval),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeToggles() {
    final ranges = {
      '7d': '7D',
      '30d': '30D',
      '90d': '90D',
      '1y': '1Y',
      'all': 'All',
    };

    return Container(
      height: 28,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.surfaceBright),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ranges.entries.map((entry) {
          final isSelected = _selectedRange == entry.key;
          return GestureDetector(
            onTap: () {
              if (_selectedRange != entry.key) {
                setState(() {
                  _selectedRange = entry.key;
                });
                _loadHistory();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 155),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.surfaceBright : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                entry.value,
                style: GoogleFonts.jetBrainsMono(
                  color: isSelected ? AppColors.brandAccent : AppColors.textSecondary,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModeToggles() {
    return Container(
      height: 28,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.surfaceBright),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modePill('Area', _chartMode == 'area', () => setState(() => _chartMode = 'area')),
          _modePill('Bar', _chartMode == 'bar', () => setState(() => _chartMode = 'bar')),
        ],
      ),
    );
  }

  Widget _modePill(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 155),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.surfaceBright : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: active ? AppColors.brandAccent : AppColors.textSecondary,
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  FLOATING Y-AXIS SCALE
  // ════════════════════════════════════════════════════════════
  Widget _buildYAxisScale(double minY, double maxY, double interval) {
    return LineChart(
      LineChartData(
        minX: 0, maxX: 1,
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: const [FlSpot(0, 0), FlSpot(1, 0)],
            color: Colors.transparent,
            barWidth: 0,
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
              reservedSize: 74,
              interval: interval,
              getTitlesWidget: (v, meta) {
                if (v == meta.max || v == meta.min) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Text(
                    _fmtMoney(v),
                    textAlign: TextAlign.right,
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white.withValues(alpha: 0.38),
                      fontSize: 8.5,
                    ),
                  ),
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

  // ════════════════════════════════════════════════════════════
  //  LINE / AREA CHART DEFINITION
  // ════════════════════════════════════════════════════════════
  Widget _buildAreaChart(double minY, double maxY, double interval) {
    final spots = List.generate(
      _chartValues.length,
      (i) => FlSpot(i.toDouble(), _chartValues[i]),
    );

    final showingIndicators = _hoveredSpotIndex != null
        ? [
            ShowingTooltipIndicators([
              _CenteredLineBarSpot(
                LineChartBarData(spots: spots),
                0,
                spots[_hoveredSpotIndex!],
                (minY + maxY) / 2, // Lock vertically centered
              ),
            ])
          ]
        : <ShowingTooltipIndicators>[];

    return LineChart(
      LineChartBarData(
        spots: spots,
      ).spots.isEmpty
          ? LineChartData()
          : LineChartData(
              minX: 0,
              maxX: (spots.length - 1).toDouble(),
              minY: minY,
              maxY: maxY,
              showingTooltipIndicators: showingIndicators,
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Colors.white.withValues(alpha: 0.05),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: _chartAxisTitles(),
              lineTouchData: LineTouchData(
                enabled: true,
                handleBuiltInTouches: false,
                touchCallback: (event, touchResponse) {
                  // If finger lift/up or cancel, ignore to avoid tearing down the tooltips
                  if (event is FlTapUpEvent ||
                      event is FlPanEndEvent ||
                      event is FlPanCancelEvent ||
                      event is FlTapCancelEvent ||
                      event is FlLongPressEnd) {
                    return;
                  }

                  if (touchResponse != null && touchResponse.lineBarSpots != null) {
                    final spotsList = touchResponse.lineBarSpots!;
                    if (spotsList.isNotEmpty) {
                      final spot = spotsList.first;
                      setState(() {
                        _hoveredSpotIndex = spot.spotIndex;
                      });
                    }
                  }
                },
                getTouchedSpotIndicator: (barData, spotsIndices) {
                  return spotsIndices.map((idx) {
                    return TouchedSpotIndicatorData(
                      FlLine(
                        color: AppColors.brandAccent.withValues(alpha: 0.5),
                        strokeWidth: 1.5,
                        dashArray: [4, 3],
                      ),
                      FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            color: AppColors.brandAccent,
                            radius: 4,
                            strokeColor: Colors.black,
                            strokeWidth: 1.0,
                          );
                        },
                      ),
                    );
                  }).toList();
                },
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppColors.surfaceBright,
                  tooltipRoundedRadius: 6,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((ts) {
                      final idx = ts.spotIndex;
                      if (idx < 0 || idx >= _dates.length) return null;
                      final date = _dates[idx];
                      final value = _chartValues[idx];

                      return LineTooltipItem(
                        '',
                        const TextStyle(),
                        children: [
                          TextSpan(
                            text: '${_fmtMoney(value)}\n',
                            style: GoogleFonts.jetBrainsMono(
                              color: AppColors.brandAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: '${date.day} ${_mon(date.month)} ${date.year}',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.2,
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
                        AppColors.brandAccent.withValues(alpha: 0.2),
                        AppColors.brandAccent.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      duration: const Duration(milliseconds: 150),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  BAR CHART DEFINITION
  // ════════════════════════════════════════════════════════════
  Widget _buildBarChart(double minY, double maxY, double interval) {
    final spots = List.generate(
      _chartValues.length,
      (i) => FlSpot(i.toDouble(), _chartValues[i]),
    );

    final showingIndicators = _hoveredSpotIndex != null ? [_hoveredSpotIndex!] : <int>[];

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withValues(alpha: 0.05),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: _chartAxisTitles(),
        barTouchData: BarTouchData(
          enabled: true,
          handleBuiltInTouches: false,
          touchCallback: (event, touchResponse) {
            if (event is FlTapUpEvent ||
                event is FlPanEndEvent ||
                event is FlPanCancelEvent ||
                event is FlTapCancelEvent ||
                event is FlLongPressEnd) {
              return; // ignore lift end dismisses
            }

            if (touchResponse != null && touchResponse.spot != null) {
              final spot = touchResponse.spot!;
              setState(() {
                _hoveredSpotIndex = spot.touchedBarGroupIndex;
              });
            }
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceBright,
            direction: TooltipDirection.top,
            fitInsideVertically: true,
            fitInsideHorizontally: true,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final idx = group.x;
              if (idx < 0 || idx >= _dates.length) return null;
              final date = _dates[idx];

              return BarTooltipItem(
                '',
                const TextStyle(),
                children: [
                  TextSpan(
                    text: '${_fmtMoney(rod.toY)}\n',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.brandAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: '${date.day} ${_mon(date.month)} ${date.year}',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        barGroups: List.generate(_chartValues.length, (i) {
          return BarChartGroupData(
            x: i,
            showingTooltipIndicators: _hoveredSpotIndex == i ? [0] : [],
            barRods: [
              BarChartRodData(
                toY: _chartValues[i],
                color: AppColors.brandAccent,
                width: 3.5,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
              ),
            ],
          );
        }),
      ),
      duration: const Duration(milliseconds: 150),
    );
  }

  FlTitlesData _chartAxisTitles() {
    final n = _dates.length;
    // Calculate label frequency based on total spots to prevent overlap
    final int labelFrequency = n > 300
        ? 60
        : n > 150
            ? 30
            : n > 60
                ? 14
                : n > 14
                    ? 5
                    : 2;

    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Pinned on left stack
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          getTitlesWidget: (value, _) {
            final idx = value.toInt();
            if (idx < 0 || idx >= _dates.length) return const SizedBox();
            if (idx % labelFrequency != 0 && idx != _dates.length - 1) return const SizedBox();

            final dt = _dates[idx];
            final label = '${_mon(dt.month)} \'${dt.year.toString().substring(2)}';

            return Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                label,
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white.withValues(alpha: 0.38),
                  fontSize: 8,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _mon(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month.clamp(1, 12) - 1];
  }

  // ════════════════════════════════════════════════════════════
  //  SUB PROTOCOLS SLIST PILLS
  // ════════════════════════════════════════════════════════════
  Widget _buildSubProtocolsCard(Responsive res) {
    final p = widget.protocol;
    if (p.children.isEmpty) return const SizedBox.shrink();

    return AppCard(
      padding: EdgeInsets.all(res.spacing(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sub-Protocols (${p.children.length})',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: res.fontSize(13),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(p.children.length, (idx) {
              final childName = p.children[idx];
              final childSlug = p.childrenSlugs.length > idx ? p.childrenSlugs[idx] : '';

              return GestureDetector(
                onTap: () {
                  if (childSlug.isNotEmpty) {
                    // Navigate to a new details screen representing this child slug!
                    // Wait, we need the child's FeeTopProtocol object. We can mock it or construct a basic instance since we have slug and name.
                    // When the detail screen builds it will fetch history for exactly this childSlug!
                    final childProtocol = FeeTopProtocol(
                      name: childName,
                      slug: childSlug,
                      category: p.category,
                      chains: p.chains,
                      logo: null,
                      fees24h: 0.0,
                      change1d: 0.0,
                      change7d: 0.0,
                      change30d: 0.0,
                      fees7d: 0.0,
                      fees30d: 0.0,
                      fees1y: 0.0,
                      feesAllTime: 0.0,
                      children: [],
                      childrenSlugs: [],
                      protocolType: 'protocol',
                      annualized1y: 0.0,
                      average1y: 0.0,
                    );

                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, __, ___) => FeeProtocolDetailScreen(
                          protocol: childProtocol, 
                          isRevenue: widget.isRevenue,
                          dataType: widget.dataType,
                        ),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('No details available for $childName')),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border.all(color: AppColors.surfaceBright),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    childName,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: res.fontSize(10.5),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  CHART WITH STATIC Y AXIS (REUSED PATTERN)
// ════════════════════════════════════════════════════════════
class _ChartWithPinnedYAxis extends StatelessWidget {
  final double height;
  final double yAxisW;
  final double canvasW;
  final ScrollController? scrollController;
  final Widget yAxisWidget;
  final Widget Function(double width) chartBuilder;

  const _ChartWithPinnedYAxis({
    required this.height,
    required this.yAxisW,
    required this.canvasW,
    this.scrollController,
    required this.yAxisWidget,
    required this.chartBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left pinned Y-axis
          SizedBox(
            width: yAxisW,
            child: yAxisWidget,
          ),
          // Scrollable canvas area
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: scrollController,
              child: SizedBox(
                width: canvasW,
                child: chartBuilder(canvasW),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CenteredLineBarSpot extends LineBarSpot {
  final double centeredY;

  _CenteredLineBarSpot(super.bar, super.barIndex, super.spot, this.centeredY);

  @override
  double get y => centeredY;
}

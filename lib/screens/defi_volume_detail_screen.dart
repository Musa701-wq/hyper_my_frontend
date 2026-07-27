import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/fee_intelligence_model.dart';
import '../services/fee_intelligence_service.dart';
import '../utils/app_colors.dart';
import '../utils/common_widgets.dart';
import '../utils/responsive.dart';
import '../widgets/error_state_widget.dart';

class DefiVolumeDetailScreen extends StatefulWidget {
  final FeeTopProtocol protocol;

  const DefiVolumeDetailScreen({
    super.key,
    required this.protocol,
  });

  @override
  State<DefiVolumeDetailScreen> createState() => _DefiVolumeDetailScreenState();
}

class _DefiVolumeDetailScreenState extends State<DefiVolumeDetailScreen> {
  final FeeIntelligenceService _service = FeeIntelligenceService();
  final ScrollController _chartScrollController = ScrollController();

  bool _isLoading = true;
  String _errorMessage = '';
  List<DateTime> _dates = [];
  List<double> _chartValues = [];

  String _selectedRange = '90d';
  String _chartMode = 'area';

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
      final res = await _service.fetchProtocolDetail(
        widget.protocol.slug,
        range: _selectedRange,
      );

      setState(() {
        _dates = res.history.points.map((p) => p.date).toList();
        _chartValues = res.history.points.map((p) => p.value).toList();
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_chartScrollController.hasClients) {
          _chartScrollController.jumpTo(_chartScrollController.position.maxScrollExtent);
        }
      });
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
    final isChain = widget.protocol.protocolType == 'chain';

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
            '${widget.protocol.name} Volume',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.brandAccent,
              fontSize: res.fontSize(15),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: _isLoading && _dates.isEmpty
            ? _buildScreenShimmer(res)
            : _errorMessage.isNotEmpty && _dates.isEmpty
                ? ErrorStateWidget(
                    errorMessage: _errorMessage,
                    onRetry: _loadHistory,
                  )
                : RefreshIndicator(
                    onRefresh: _loadHistory,
                    color: AppColors.brandAccent,
                    backgroundColor: const Color(0xFF16191E),
                    child: ListView(
                      padding: EdgeInsets.symmetric(horizontal: res.spacing(14), vertical: res.spacing(10)),
                      children: [
                        _buildProtocolHeader(res, isChain),
                        const SizedBox(height: 14),
                        _buildDashboardMetricsGrid(res),
                        const SizedBox(height: 14),
                        _buildChartSection(res),
                        const SizedBox(height: 14),
                        if (widget.protocol.children.isNotEmpty) 
                          _buildSubprotocolsSection(res),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildProtocolHeader(Responsive res, bool isChain) {
    return AppCard(
      padding: EdgeInsets.all(res.spacing(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.protocol.logo ?? '',
              width: 44,
              height: 44,
              errorBuilder: (_, __, ___) => Container(
                width: 44,
                height: 44,
                color: AppColors.surfaceBright.withOpacity(0.12),
                child: const Icon(Icons.token_outlined, color: AppColors.brandAccent, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.protocol.name,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: res.fontSize(17),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.brandAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.protocol.category.toUpperCase(),
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.brandAccent,
                          fontSize: res.fontSize(8.5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isChain
                            ? 'L1/L2 Ecosystem'
                            : (widget.protocol.chains.isNotEmpty
                                ? 'Chains: ${widget.protocol.chains.join(', ')}'
                                : 'Multi-chain deployment'),
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: res.fontSize(10),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardMetricsGrid(Responsive res) {
    final showAvg = widget.protocol.average1y > 0;
    
    return GridView.count(
      crossAxisCount: res.isMobile ? 2 : 4,
      crossAxisSpacing: res.spacing(10),
      mainAxisSpacing: res.spacing(10),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard('24H VOLUME', _fmtMoney(widget.protocol.fees24h), _buildChangeRow(widget.protocol.change1d, res), res),
        _buildMetricCard('7D VOLUME', _fmtMoney(widget.protocol.fees7d), _buildChangeRow(widget.protocol.change7d, res), res),
        _buildMetricCard('30D VOLUME', _fmtMoney(widget.protocol.fees30d), null, res),
        _buildMetricCard(
          showAvg ? '1Y AVERAGE (DAILY)' : '1Y VOLUME',
          _fmtMoney(showAvg ? widget.protocol.average1y : widget.protocol.fees1y),
          null,
          res,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, Widget? bottomWidget, Responsive res) {
    return AppCard(
      padding: EdgeInsets.all(res.spacing(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: res.fontSize(8.5),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontSize: res.fontSize(16),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (bottomWidget != null) ...[
            const SizedBox(height: 6),
            bottomWidget,
          ],
        ],
      ),
    );
  }

  Widget _buildChangeRow(double value, Responsive res) {
    final isUp = value >= 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
          color: isUp ? AppColors.trendGreen : AppColors.trendRed,
          size: res.fontSize(14),
        ),
        Text(
          _fmtPct(value),
          style: GoogleFonts.inter(
            color: isUp ? AppColors.trendGreen : AppColors.trendRed,
            fontSize: res.fontSize(9.5),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection(Responsive res) {
    return AppCard(
      padding: EdgeInsets.all(res.spacing(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historical Volume Trend',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: res.fontSize(13),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Protocol performance timeline analytics',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: res.fontSize(9.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildChartModeToggle(res),
              const SizedBox(width: 8),
              _buildRangeSelector(res),
            ],
          ),
          if (!_isLoading && _chartValues.isNotEmpty) ...[
            SizedBox(height: res.spacing(12)),
            Divider(color: Colors.white.withOpacity(0.04), height: 1),
            SizedBox(height: res.spacing(8)),
            _buildHoverDetailsRow(res),
          ],
          SizedBox(height: res.spacing(18)),
          _isLoading
              ? SizedBox(
                  height: res.spacing(180),
                  child: const Center(child: CircularProgressIndicator(color: AppColors.brandAccent, strokeWidth: 2)),
                )
              : _chartValues.isEmpty
                  ? SizedBox(
                      height: res.spacing(180),
                      child: Center(
                        child: Text(
                          'No history available for range',
                          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: res.fontSize(11)),
                        ),
                      ),
                    )
                  : _buildSelectedChart(res),
        ],
      ),
    );
  }

  Widget _buildHoverDetailsRow(Responsive res) {
    final index = _hoveredSpotIndex ?? (_chartValues.length - 1);
    if (index < 0 || index >= _chartValues.length) return const SizedBox.shrink();

    final date = _dates[index];
    final value = _chartValues[index];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DateFormat('MMMM d, yyyy').format(date).toUpperCase(),
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.textSecondary,
            fontSize: res.fontSize(9.5),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          _fmtMoney(value),
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.brandAccent,
            fontSize: res.fontSize(12),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildChartModeToggle(Responsive res) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.08),
        border: Border.all(color: AppColors.surfaceBright.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _chartMode = 'area'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _chartMode == 'area' ? AppColors.brandAccent : Colors.transparent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(7),
                  bottomLeft: Radius.circular(7),
                ),
              ),
              child: Text(
                'LINE',
                style: GoogleFonts.inter(
                  color: _chartMode == 'area' ? Colors.black : AppColors.textSecondary,
                  fontSize: res.fontSize(9.5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _chartMode = 'bar'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _chartMode == 'bar' ? AppColors.brandAccent : Colors.transparent,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(7),
                  bottomRight: Radius.circular(7),
                ),
              ),
              child: Text(
                'BAR',
                style: GoogleFonts.inter(
                  color: _chartMode == 'bar' ? Colors.black : AppColors.textSecondary,
                  fontSize: res.fontSize(9.5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSelector(Responsive res) {
    final ranges = ['7D', '30D', '90D', '1Y', 'ALL'];
    final current = _selectedRange.toUpperCase();
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.08),
        border: Border.all(color: AppColors.surfaceBright.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          dropdownColor: const Color(0xFF14171C),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 14),
          style: GoogleFonts.jetBrainsMono(color: AppColors.brandAccent, fontSize: res.fontSize(10), fontWeight: FontWeight.bold),
          isDense: true,
          onChanged: (v) {
            if (v != null) {
              setState(() {
                _selectedRange = v.toLowerCase();
              });
              _loadHistory();
            }
          },
          items: ranges.map((r) => DropdownMenuItem(
            value: r,
            child: Text(
              r,
              style: GoogleFonts.jetBrainsMono(
                color: r == current ? AppColors.brandAccent : AppColors.textSecondary,
                fontSize: res.fontSize(10),
                fontWeight: r == current ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildSelectedChart(Responsive res) {
    if (_chartMode == 'bar') {
      return _buildBarChart(res);
    }
    return _buildLineChart(res);
  }

  Widget _buildLineChart(Responsive res) {
    final spots = _chartValues.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    double minY = _chartValues.reduce((a, b) => a < b ? a : b);
    double maxY = _chartValues.reduce((a, b) => a > b ? a : b);
    if (minY == maxY) {
      minY = minY * 0.9;
      maxY = maxY * 1.1;
    } else {
      minY = minY * 0.95;
      maxY = maxY * 1.05;
    }
    if (minY < 0) minY = 0;

    final step = (maxY - minY) / 3 > 0 ? (maxY - minY) / 3 : 1.0;
    final yLabels = [minY, minY + step, minY + 2 * step, maxY];
    final chartWidth = (spots.length * 8.5).clamp(320.0, 1200.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          height: res.spacing(180) - 20,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: yLabels.reversed.map((val) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  _fmtMoney(val),
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary.withOpacity(0.5),
                    fontSize: res.fontSize(8.5),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _chartScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: chartWidth,
              height: res.spacing(180),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: step,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.white.withOpacity(0.03),
                      strokeWidth: 1,
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchCallback: (FlTouchEvent event, response) {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.lineBarSpots == null ||
                          response.lineBarSpots!.isEmpty) {
                        return;
                      }
                      setState(() {
                        _hoveredSpotIndex = response.lineBarSpots!.first.spotIndex;
                      });
                    },
                    handleBuiltInTouches: true,
                    getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                      return spotIndexes.map((spotIndex) {
                        return TouchedSpotIndicatorData(
                          FlLine(color: AppColors.brandAccent.withOpacity(0.5), strokeWidth: 1.5),
                          FlDotData(
                            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                              radius: 4,
                              color: AppColors.brandAccent,
                              strokeWidth: 1,
                              strokeColor: Colors.black,
                            ),
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
                                text: DateFormat('MMM dd, yyyy').format(date),
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
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (spots.length / 4).clamp(1, double.infinity),
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= _dates.length) return const SizedBox.shrink();
                          final date = _dates[idx];
                          final label = DateFormat('MMM d').format(date);
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              label,
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary.withOpacity(0.5),
                                fontSize: res.fontSize(8.5),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: spots.length.toDouble() - 1,
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.brandAccent,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.brandAccent.withOpacity(0.12),
                            AppColors.brandAccent.withOpacity(0.0)
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(Responsive res) {
    double minY = _chartValues.reduce((a, b) => a < b ? a : b);
    double maxY = _chartValues.reduce((a, b) => a > b ? a : b);
    if (minY == maxY) {
      minY = minY * 0.9;
      maxY = maxY * 1.1;
    } else {
      minY = minY * 0.95;
      maxY = maxY * 1.05;
    }
    if (minY < 0) minY = 0;

    final step = (maxY - minY) / 3 > 0 ? (maxY - minY) / 3 : 1.0;
    final yLabels = [minY, minY + step, minY + 2 * step, maxY];
    final chartWidth = (_chartValues.length * 9.5).clamp(320.0, 1200.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          height: res.spacing(180) - 20,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: yLabels.reversed.map((val) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  _fmtMoney(val),
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary.withOpacity(0.5),
                    fontSize: res.fontSize(8.5),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _chartScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: chartWidth,
              height: res.spacing(180),
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: step,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.white.withOpacity(0.03),
                      strokeWidth: 1,
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchCallback: (FlTouchEvent event, response) {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.spot == null) {
                        return;
                      }
                      setState(() {
                        _hoveredSpotIndex = response.spot!.touchedBarGroupIndex;
                      });
                    },
                    handleBuiltInTouches: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: null,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (_chartValues.length / 4).clamp(1, double.infinity),
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= _dates.length) return const SizedBox.shrink();
                          final date = _dates[idx];
                          final label = DateFormat('MMM d').format(date);
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              label,
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary.withOpacity(0.5),
                                fontSize: res.fontSize(8.5),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: minY,
                  maxY: maxY,
                  barGroups: _chartValues.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final val = entry.value;
                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: val,
                          color: AppColors.brandAccent.withOpacity(0.7),
                          width: 5,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(2),
                            topRight: Radius.circular(2),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubprotocolsSection(Responsive res) {
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
          Divider(color: Colors.white.withOpacity(0.05), height: 1),
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
                        pageBuilder: (context, __, ___) => DefiVolumeDetailScreen(
                          protocol: childProtocol,
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
                    color: AppColors.surface,
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

  Widget _buildScreenShimmer(Responsive res) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: res.spacing(14), vertical: res.spacing(10)),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFF1E222D),
        highlightColor: const Color(0xFF3A3F4E),
        period: const Duration(milliseconds: 1500),
        child: Column(
          children: [
            Container(height: 72, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: res.spacing(10),
              mainAxisSpacing: res.spacing(10),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: List.generate(4, (index) => Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              )),
            ),
            const SizedBox(height: 14),
            Container(
              height: res.spacing(240),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            )
          ],
        ),
      ),
    );
  }
}

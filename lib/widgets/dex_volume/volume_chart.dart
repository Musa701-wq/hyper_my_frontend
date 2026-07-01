import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/dex_volume_model.dart';
import '../../utils/app_colors.dart';

class VolumeChartWidget extends StatefulWidget {
  final List<DexVolumeChartPoint> data;
  final String selectedScope;
  final String selectedTimeRange;
  final String selectedChartType;
  final Function(String) onChartTypeChanged;
  final Function(String)? onTimeRangeChanged;

  const VolumeChartWidget({
    super.key,
    required this.data,
    required this.selectedScope,
    required this.selectedTimeRange,
    required this.selectedChartType,
    required this.onChartTypeChanged,
    this.onTimeRangeChanged,
  });

  @override
  State<VolumeChartWidget> createState() => _VolumeChartWidgetState();
}

class _VolumeChartWidgetState extends State<VolumeChartWidget> {
  final ScrollController _scrollController = ScrollController();
  double _zoomScale = 1.0;
  double _scaleStart = 1.0;

  static const double _minZoom = 1.0;
  static const double _maxZoom = 8.0;

  @override
  void didUpdateWidget(covariant VolumeChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTimeRange != widget.selectedTimeRange ||
        oldWidget.selectedScope != widget.selectedScope ||
        oldWidget.data.length != widget.data.length) {
      _zoomScale = 1.0;
      _scrollToEnd();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _scrollController.position.hasContentDimensions) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _setZoom(double value) {
    setState(() => _zoomScale = value.clamp(_minZoom, _maxZoom).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator(color: AppColors.brandAccent)),
      );
    }

    final double baseWidth = MediaQuery.of(context).size.width - 32;

    // Balanced zoom multipliers
    double pointWidth = 5.0;
    if (widget.selectedTimeRange == 'D') pointWidth = 25.0;
    if (widget.selectedTimeRange == 'W') pointWidth = 20.0;
    if (widget.selectedTimeRange == 'M') pointWidth = 15.0;

    final double baseChartContentWidth = (widget.data.length * pointWidth).clamp(baseWidth, 2000.0).toDouble();
    final double chartContentWidth = baseChartContentWidth * _zoomScale;
    final double effectivePointWidth = chartContentWidth / widget.data.length;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildHeader()),
                      _buildTypeToggles(),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.onTimeRangeChanged != null) _buildTimeRangeToggle(),
                const SizedBox(height: 12),
                SizedBox(
                  height: 300,
                  child: Row(
                    children: [
                      _buildFixedYAxis(),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          child: GestureDetector(
                            onScaleStart: (details) {
                              _scaleStart = _zoomScale;
                            },
                            onScaleUpdate: (details) {
                              if (details.pointerCount < 2) return;
                              _setZoom(_scaleStart * details.scale);
                            },
                            child: SizedBox(
                              width: chartContentWidth,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 40, right: 20),
                                child: widget.selectedChartType == 'Bar'
                                  ? BarChart(_buildBarData(effectivePointWidth))
                                  : LineChart(_buildLineData(effectivePointWidth)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DEX Volume — ${widget.selectedTimeRange}',
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Total volume (${widget.selectedScope})',
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeToggles() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['Area', 'Bar'].map((type) {
          final bool isActive = widget.selectedChartType == type;
          return GestureDetector(
            onTap: () => widget.onChartTypeChanged(type),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF10B981) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                type,
                style: GoogleFonts.jetBrainsMono(
                  color: isActive ? Colors.black : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeRangeToggle() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: ['D', 'W', 'M', 'Y'].map((range) {
          final bool isActive = widget.selectedTimeRange == range;
          return Expanded(
            child: GestureDetector(
              onTap: () => widget.onTimeRangeChanged?.call(range),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF10B981) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  range,
                  style: GoogleFonts.jetBrainsMono(
                    color: isActive ? Colors.black : AppColors.textSecondary,
                    fontSize: 12,
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

  Widget _buildFixedYAxis() {
    double maxVal = widget.data.map((e) => e.volume).reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) maxVal = 1e6;

    return Container(
      width: 58,
      padding: const EdgeInsets.only(left: 8, bottom: 30),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxVal,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            show: true,
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  if (value >= meta.max * 0.98 || value <= meta.min) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      _formatPrice(value),
                      style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 7),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [LineChartBarData(spots: [], show: false)],
        ),
      ),
    );
  }

  LineChartData _buildLineData(double effectivePointWidth) {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _calculateInterval(),
        getDrawingHorizontalLine: (value) => FlLine(
          color: AppColors.surfaceBright.withOpacity(0.05),
          strokeWidth: 1,
        ),
      ),
      titlesData: _titlesData(effectivePointWidth),
      borderData: FlBorderData(show: false),
      minY: 0,
      lineBarsData: [
        LineChartBarData(
          spots: widget.data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.volume)).toList(),
          isCurved: true,
          color: const Color(0xFF10B981),
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF10B981).withOpacity(0.15),
                const Color(0xFF10B981).withOpacity(0.0),
              ],
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipColor: (_) => const Color(0xFF16191E).withOpacity(0.95),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final date = widget.data[spot.x.toInt()].timestamp;
              return LineTooltipItem(
                '${DateFormat('MMM d, yyyy').format(date)}\n\$${(spot.y / 1e6).toStringAsFixed(2)}M',
                GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  BarChartData _buildBarData(double effectivePointWidth) {
    return BarChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _calculateInterval(),
        getDrawingHorizontalLine: (value) => FlLine(
          color: AppColors.surfaceBright.withOpacity(0.05),
          strokeWidth: 1,
        ),
      ),
      titlesData: _titlesData(effectivePointWidth),
      borderData: FlBorderData(show: false),
      minY: 0,
      barGroups: widget.data.asMap().entries.map((entry) {
        return BarChartGroupData(
          x: entry.key,
          barRods: [
            BarChartRodData(
              toY: entry.value.volume,
              color: const Color(0xFF10B981),
              width: effectivePointWidth * 0.6, // Use effective width to handle sparse data
              borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
            ),
          ],
        );
      }).toList(),
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
           fitInsideHorizontally: true,
           fitInsideVertically: true,
           getTooltipColor: (_) => const Color(0xFF16191E).withOpacity(0.95),
           tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
           tooltipMargin: 8,
           getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (group.x.toInt() >= widget.data.length) return null;
              final date = widget.data[group.x.toInt()].timestamp;
              return BarTooltipItem(
                '${DateFormat('MMM d, yyyy').format(date)}\n\$${(rod.toY / 1e6).toStringAsFixed(2)}M',
                GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              );
           }
        ),
        handleBuiltInTouches: true,
      )
    );
  }

  FlTitlesData _titlesData(double effectivePointWidth) {
    return FlTitlesData(
      show: true,
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: _calculateTitleInterval(),
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= widget.data.length) return const SizedBox.shrink();

            final date = widget.data[index].timestamp;

            final bool isFirstPoint = index == 0;
            final bool isYearTransition = index > 0 && widget.data[index - 1].timestamp.year != date.year;
            final bool isMonthTransition = index > 0 && widget.data[index - 1].timestamp.month != date.month;

            // Logic for showing labels
            bool shouldShow = false;

            if (widget.selectedTimeRange == 'M') {
              // Skip logic: only show if year transition, first point, or every 2nd month
              final bool skipThis = !isFirstPoint && !isYearTransition && (index % 2 != 0);
              if (skipThis && effectivePointWidth < 30) return const SizedBox.shrink();
              shouldShow = true;
            } else if (widget.selectedTimeRange == 'D' || widget.selectedTimeRange == 'W') {
              // Special skip for first point if transition is too close
              if (isFirstPoint && widget.data.length > 5) {
                int nextTransitionIndex = -1;
                for (int i = 1; i < widget.data.length && i < 15; i++) {
                   if (widget.data[i].timestamp.month != date.month) {
                     nextTransitionIndex = i;
                     break;
                   }
                }
                if (nextTransitionIndex != -1 && nextTransitionIndex < 8) return const SizedBox.shrink();
              }
              shouldShow = isFirstPoint || isMonthTransition;
            } else if (widget.data.length < 20) {
              shouldShow = true;
            } else {
              shouldShow = index % (widget.data.length > 100 ? 12 : (widget.data.length > 50 ? 6 : 2)) == 0;
            }

            if (!shouldShow) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('MMM').format(date),
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textSecondary,
                      fontSize: 8,
                    ),
                  ),
                  if (isFirstPoint || isYearTransition)
                    Text(
                      DateFormat('yyyy').format(date),
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.textSecondary.withOpacity(0.5),
                        fontSize: 7,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  double _calculateInterval() {
    if (widget.data.isEmpty) return 1e6;
    double maxVal = widget.data.map((e) => e.volume).reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return 1e6;
    return maxVal / 5;
  }

  double _calculateTitleInterval() {
    // We now handle transitions in getTitlesWidget, so interval is 1
    return 1;
  }

  String _formatPrice(double value) {
    if (value >= 1e9) return '\$${(value / 1e9).toStringAsFixed(1)}B';
    if (value >= 1e6) return '\$${(value / 1e6).toStringAsFixed(1)}M';
    if (value >= 1e3) return '\$${(value / 1e3).toStringAsFixed(0)}K';
    return '\$${value.toStringAsFixed(0)}';
  }
}

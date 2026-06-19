import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/dex_volume_model.dart';
import '../../utils/app_colors.dart';

class TrendChartWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<TrendItem> trend;
  final Color color;
  final bool filterCurrent;

  const TrendChartWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trend,
    required this.color,
    this.filterCurrent = false,
  });

  @override
  State<TrendChartWidget> createState() => _TrendChartWidgetState();
}

class _TrendChartWidgetState extends State<TrendChartWidget> {
  String _style = 'Bar';

  @override
  Widget build(BuildContext context) {
    if (widget.trend.isEmpty) return const SizedBox.shrink();

    List<TrendItem> displayTrend = widget.trend;
    if (widget.filterCurrent && displayTrend.isNotEmpty) {
      displayTrend = displayTrend.sublist(0, displayTrend.length - 1);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBright.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStyleToggle(),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                _buildFixedYAxis(displayTrend),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: (displayTrend.length * 45.0).clamp(MediaQuery.of(context).size.width - 64, 2000.0),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: _style == 'Bar' 
                          ? BarChart(_buildBarData(displayTrend))
                          : LineChart(_buildLineData(displayTrend)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleToggle() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['Area', 'Bar'].map((type) {
          final bool isActive = _style == type;
          return GestureDetector(
            onTap: () => setState(() => _style = type),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? widget.color : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                type,
                style: GoogleFonts.jetBrainsMono(
                  color: isActive ? Colors.black : AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  BarChartData _buildBarData(List<TrendItem> trend) {
    return BarChartData(
      gridData: const FlGridData(show: false),
      titlesData: _titlesData(trend),
      borderData: FlBorderData(show: false),
      barGroups: trend.asMap().entries.map((entry) {
        return BarChartGroupData(
          x: entry.key,
          barRods: [
            BarChartRodData(
              toY: entry.value.volume,
              color: widget.color,
              width: 18.0, // Increased for a more solid, premium look
              borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
            ),
          ],
        );
      }).toList(),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => const Color(0xFF16191E),
          fitInsideVertically: true, // Ensure tooltip doesn't hide at the top
          fitInsideHorizontally: true,
          tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            return BarTooltipItem(
              '${trend[group.x.toInt()].label}\n${_formatPrice(rod.toY)}',
              GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            );
          },
        ),
      ),
    );
  }

  LineChartData _buildLineData(List<TrendItem> trend) {
    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: _titlesData(trend),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: trend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.volume)).toList(),
          isCurved: true,
          color: widget.color,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                widget.color.withValues(alpha: 0.3),
                widget.color.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => const Color(0xFF16191E),
          fitInsideVertically: true,
          fitInsideHorizontally: true,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                '${trend[spot.x.toInt()].label}\n${_formatPrice(spot.y)}',
                GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildFixedYAxis(List<TrendItem> trend) {
    if (trend.isEmpty) return const SizedBox.shrink();
    double maxVal = trend.map((e) => e.volume).reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) maxVal = 1e6;
    maxVal = maxVal * 1.15; // Add 15% headroom for tooltips
    
    return Container(
      width: 45,
      padding: const EdgeInsets.only(bottom: 24, top: 0),
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
                reservedSize: 45,
                getTitlesWidget: (value, meta) {
                  if (value >= meta.max * 0.98 || value <= meta.min) return const SizedBox.shrink();
                  return Text(
                    _formatPrice(value),
                    style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 7),
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

  FlTitlesData _titlesData(List<TrendItem> trend) {
    return FlTitlesData(
      show: true,
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          interval: 1, // Show every label since we have scroll now
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= trend.length) return const SizedBox.shrink();
            
            final item = trend[index];
            String displayLabel = item.label;
            
            // Try formatting more cleanly if it's a date-like label
            if (item.label.contains('-')) {
               try {
                 final parts = item.label.split('-');
                 int year = int.parse(parts[0]);
                 int month = int.parse(parts[1]);
                 if (year < 100) year += 2000;
                 final dt = DateTime(year, month);
                 displayLabel = DateFormat('MMM \'yy').format(dt);
               } catch (_) {}
            }
            
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                displayLabel,
                style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 8),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatPrice(double value) {
    if (value >= 1e9) return '\$${(value / 1e9).toStringAsFixed(1)}B';
    if (value >= 1e6) return '\$${(value / 1e6).toStringAsFixed(1)}M';
    return '\$${(value / 1e3).toStringAsFixed(0)}K';
  }
}

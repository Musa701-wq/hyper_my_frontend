import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/protocol_model.dart';
import '../../utils/app_colors.dart';

class CategoryDistributionChart extends StatefulWidget {
  final List<CategoryDistribution> data;

  const CategoryDistributionChart({super.key, required this.data});

  @override
  State<CategoryDistributionChart> createState() => _CategoryDistributionChartState();
}

class _CategoryDistributionChartState extends State<CategoryDistributionChart> {
  int _touchedIndex = -1;
  bool _showBarChart = false;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const SizedBox.shrink();

    final grandTotal = widget.data.fold<double>(0, (sum, e) => sum + e.tvl);
    final displayData = widget.data.take(8).toList(); 
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBright.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TVL by Category',
                style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              // View Toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceBright.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildToggleItem(Icons.pie_chart_outline, 'PIE', !_showBarChart, () => setState(() => _showBarChart = false)),
                    const SizedBox(width: 4),
                    _buildToggleItem(Icons.leaderboard_rounded, 'BARS', _showBarChart, () => setState(() => _showBarChart = true)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_showBarChart)
            _buildBarChart(displayData, grandTotal)
          else
            _buildDonutView(displayData, grandTotal),
          const SizedBox(height: 32),
          // Detailed Legend with percentages
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: List.generate(displayData.length, (i) {
              final item = displayData[i];
              final color = _categoryColors[i % _categoryColors.length];
              final isTouched = _touchedIndex == i;
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isTouched 
                      ? color.withOpacity(0.15) 
                      : AppColors.surfaceBright.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isTouched 
                        ? color.withOpacity(0.4) 
                        : AppColors.surfaceBright.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.category.toUpperCase(),
                      style: GoogleFonts.jetBrainsMono(
                        color: isTouched ? Colors.white : AppColors.textSecondary,
                        fontSize: 9,
                        fontWeight: isTouched ? FontWeight.bold : FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.percentage.toStringAsFixed(1)}%',
                      style: GoogleFonts.jetBrainsMono(
                        color: isTouched ? color : Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildToggleItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.brandAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive ? [
            BoxShadow(
              color: AppColors.brandAccent.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Row(
          children: [
            Icon(
              icon, 
              size: 14, 
              color: isActive ? Colors.black : AppColors.textSecondary
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                label,
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

  Widget _buildDonutView(List<CategoryDistribution> displayData, double grandTotal) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 320;
        final donutSize = isNarrow ? 160.0 : 180.0;
        
        return Column(
          children: [
            Center(
              child: SizedBox(
                height: donutSize,
                width: donutSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _touchedIndex = -1;
                                return;
                              }
                              _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 0,
                        centerSpaceRadius: isNarrow ? 50 : 60,
                        sections: _buildSections(displayData, grandTotal),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(grandTotal),
                          style: GoogleFonts.jetBrainsMono(
                            color: Colors.white,
                            fontSize: isNarrow ? 12 : 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'TOTAL TVL',
                          style: GoogleFonts.jetBrainsMono(
                            color: AppColors.textSecondary.withOpacity(0.7),
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildBarChart(List<CategoryDistribution> displayData, double grandTotal) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final labelWidth = 65.0; // Fixed width for category labels
        final barAreaWidth = availableWidth - labelWidth - 10;

        return Stack(
          children: [
            // Background Grid Lines
            Positioned.fill(
              left: labelWidth + 5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (index) => Container(
                  width: 1,
                  color: Colors.white.withOpacity(0.05),
                )),
              ),
            ),
            
            // Bars and Labels
            Column(
              children: displayData.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final color = _categoryColors[i % _categoryColors.length];
                final pct = grandTotal > 0 ? (item.tvl / grandTotal) : 0.0;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      // Category Label
                      SizedBox(
                        width: labelWidth,
                        child: Text(
                          item.category.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.jetBrainsMono(
                            color: AppColors.textSecondary.withOpacity(0.7),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Bar and Pct Label
                      Expanded(
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            // Progress Bar
                            Stack(
                              children: [
                                Container(
                                  height: 18,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceBright.withOpacity(0.03),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 1000),
                                  curve: Curves.easeOutQuart,
                                  height: 18,
                                  width: barAreaWidth * pct,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Pct Label inside or right of the bar
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '${(pct * 100).toStringAsFixed(1)}%',
                                style: GoogleFonts.jetBrainsMono(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.2,
                                  shadows: [
                                    const Shadow(color: Colors.black45, blurRadius: 2, offset: Offset(0, 1))
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        );
      }
    );
  }

  List<PieChartSectionData> _buildSections(List<CategoryDistribution> data, double total) {
    return data.asMap().entries.map((entry) {
      final i = entry.key;
      final item = entry.value;
      final isTouched = _touchedIndex == i;
      final percentage = total > 0 ? (item.tvl / total) * 100 : 0.0;
      final radius = isTouched ? 65.0 : 50.0;
      final fontSize = isTouched ? 13.0 : 11.0;
      final color = _categoryColors[i % _categoryColors.length];
      final showTitle = percentage > 5 || isTouched;

      return PieChartSectionData(
        color: color,
        value: item.tvl,
        title: showTitle ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: radius,
        titleStyle: GoogleFonts.jetBrainsMono(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: isTouched
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.category,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.fullTvl,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}% of total',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8,
                        fontWeight: FontWeight.normal,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.4,
      );
    }).toList();
  }

  static const _categoryColors = [
    Color(0xFF2EE2BA),
    Color(0xFF7C3AED),
    Color(0xFFD97706),
    Color(0xFF0D9488),
    Color(0xFF60A5FA),
    Color(0xFFF43F5E),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFFF97316),
    Color(0xFF6366F1),
  ];
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const SizedBox.shrink();

    final topData = widget.data.take(5).toList();
    if (topData.isEmpty) return const SizedBox.shrink();

    final total = topData.fold<double>(0, (sum, e) => sum + e.tvl);

    if (total <= 0) {
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
            Text(
              'Category Distribution',
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'No category data available yet.',
                style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    final otherTvl = widget.data.length > 5
        ? widget.data.skip(5).fold<double>(0, (sum, e) => sum + e.tvl)
        : 0.0;

    List<CategoryDistribution> displayData = [...topData];
    if (otherTvl > 0) {
      final otherPct = (otherTvl / total) * 100;
      displayData.add(CategoryDistribution(
        category: 'Other',
        tvl: otherTvl,
        percentage: otherPct,
      ));
    }

    final grandTotal = total + otherTvl;

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
          Text(
            'Category Distribution',
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'TVL breakdown by protocol category',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 260,
            child: PieChart(
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
                sectionsSpace: 2,
                centerSpaceRadius: 55,
                sections: _buildSections(displayData, grandTotal),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceBright.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: List.generate(displayData.length, (i) {
                final item = displayData[i];
                final isSelected = _touchedIndex == i;
                final color = _categoryColors[i % _categoryColors.length];
                final isLast = i == displayData.length - 1;
                return GestureDetector(
                  onTap: () => setState(() => _touchedIndex = _touchedIndex == i ? -1 : i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
                      borderRadius: isLast && !isSelected
                          ? const BorderRadius.vertical(bottom: Radius.circular(10))
                          : (i == 0 && !isSelected
                              ? const BorderRadius.vertical(top: Radius.circular(10))
                              : BorderRadius.zero),
                      border: isLast
                          ? null
                          : Border(
                              bottom: BorderSide(
                                color: isSelected ? color.withValues(alpha: 0.3) : AppColors.surfaceBright.withValues(alpha: 0.12),
                              ),
                            ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Text(
                            item.category,
                            style: GoogleFonts.jetBrainsMono(
                              color: isSelected ? Colors.white : Colors.white,
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withValues(alpha: 0.2) : AppColors.surfaceBright.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.formattedTvl,
                                style: GoogleFonts.jetBrainsMono(
                                  color: isSelected ? color : Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '(${item.percentage.toStringAsFixed(1)}%)',
                                style: GoogleFonts.jetBrainsMono(
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
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

      return PieChartSectionData(
        color: color,
        value: item.tvl,
        title: '${percentage.toStringAsFixed(1)}%',
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
                  color: color.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
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
                      item.formattedTvl,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}% of total',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8,
                        fontWeight: FontWeight.normal,
                        color: Colors.white.withValues(alpha: 0.7),
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

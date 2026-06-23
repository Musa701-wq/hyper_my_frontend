import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/dex_volume_model.dart';
import '../../utils/app_colors.dart';

class MonthlyVolumeTable extends StatelessWidget {
  final List<TrendItem> monthlyTrend;
  final double? sixMonthAvg;

  const MonthlyVolumeTable({
    super.key,
    required this.monthlyTrend,
    this.sixMonthAvg,
  });

  String _formatValue(double val) {
    return '\$${NumberFormat('#,###').format(val.toInt())}';
  }

  String _fmtPct(double n) {
    return '${n >= 0 ? "+" : ""}${n.toStringAsFixed(2)}%';
  }

  @override
  Widget build(BuildContext context) {
    // Show all months but focus on last 12
    final sortedTrend = List<TrendItem>.from(monthlyTrend);
    sortedTrend.sort((a, b) =>
        b.toDateTime().compareTo(a.toDateTime())); // Newest first

    final last12Months = sortedTrend.take(12).toList();
    final double maxVol = monthlyTrend.isEmpty ? 0 : monthlyTrend.map((e) =>
    e.volume).reduce((a, b) => a > b ? a : b);

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Volume — Performance Breakdown',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Historical performance vs averages',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.textSecondary.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.surfaceBright),
              _buildHeader(),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: last12Months.length,
                itemBuilder: (context, index) {
                  final item = last12Months[index];
                  final date = item.toDateTime();

                  // Find previous month volume for MoM
                  double? momChange;
                  final prevMonth = monthlyTrend.firstWhere(
                        (e) =>
                        e.toDateTime().isAtSameMomentAs(
                        DateTime.utc(date.year, date.month - 1, 1)),
                    orElse: () => TrendItem(label: '', volume: 0),
                  );
                  if (prevMonth.volume > 0) {
                    momChange =
                        ((item.volume - prevMonth.volume) / prevMonth.volume) *
                            100;
                  }

                  // vs 6M Average
                  double? vsAvg;
                  if (sixMonthAvg != null && sixMonthAvg! > 0) {
                    vsAvg = ((item.volume - sixMonthAvg!) / sixMonthAvg!) * 100;
                  }

                  final bool isCurrentMonth = date.month == DateTime
                      .now()
                      .month && date.year == DateTime
                      .now()
                      .year;
                  final bool isATH = item.volume >= maxVol && maxVol > 0;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isCurrentMonth
                          ? const Color(0xFF10B981).withOpacity(0.05)
                          : isATH ? Colors.amber.withOpacity(0.05) : null,
                      border: Border(bottom: BorderSide(color: AppColors
                          .surfaceBright.withOpacity(0.1))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            item.label,
                            style: GoogleFonts.jetBrainsMono(
                                color: isCurrentMonth
                                    ? const Color(0xFF10B981)
                                    : Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            _formatValue(item.volume),
                            textAlign: TextAlign.right,
                            style: GoogleFonts.jetBrainsMono(
                                color: isATH ? Colors.amber : Colors.white
                                    .withOpacity(0.9),
                                fontSize: 11
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            momChange != null ? _fmtPct(momChange) : '—',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.jetBrainsMono(
                              color: (momChange ?? 0) >= 0 ? const Color(
                                  0xFF10B981) : const Color(0xFFF43F5E),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            vsAvg != null ? _fmtPct(vsAvg) : '—',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.jetBrainsMono(
                              color: (vsAvg ?? 0) >= 0
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF43F5E),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withOpacity(0.2),
      child: Row(
        children: [
          Expanded(flex: 2,
              child: Text('MONTH', style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.bold))),
          Expanded(flex: 3,
              child: Text('VOLUME', textAlign: TextAlign.right,
                  style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.bold))),
          Expanded(flex: 2,
              child: Text('MOM', textAlign: TextAlign.right,
                  style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.bold))),
          Expanded(flex: 2,
              child: Text('VS 6M AVG', textAlign: TextAlign.right,
                  style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }}

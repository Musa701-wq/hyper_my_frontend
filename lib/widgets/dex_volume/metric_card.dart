import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final double value;
  final double? change;
  final bool isCumulative;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.change,
    this.isCumulative = false,
  });

  String _formatValue(double val) {
    if (val >= 1e9) {
      return '\$${(val / 1e9).toStringAsFixed(2)}B';
    } else if (val >= 1e6) {
      return '\$${(val / 1e6).toStringAsFixed(2)}M';
    } else {
      return '\$${val.toStringAsFixed(2)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.brandAccent;
    final isUp = (change ?? 0) >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCumulative
                      ? Icons.bar_chart_rounded
                      : (isUp ? Icons.trending_up : Icons.trending_down),
                  color: accent,
                  size: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatValue(value),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (!isCumulative && change != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: isUp ? AppColors.trendGreen : AppColors.trendRed,
                  size: 16,
                ),
                const SizedBox(width: 2),
                Text(
                  '${change! >= 0 ? '+' : ''}${change!.toStringAsFixed(2)}%',
                  style: GoogleFonts.inter(
                    color: isUp ? AppColors.trendGreen : AppColors.trendRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

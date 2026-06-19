import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';

class AdoptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value;
  final double? growth;

  const AdoptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    this.growth,
  });

  String _formatValue(double val) {
    if (val >= 1e9) return '\$${(val / 1e9).toStringAsFixed(2)}B';
    if (val >= 1e6) return '\$${(val / 1e6).toStringAsFixed(2)}M';
    return '\$${val.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
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
            title.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatValue(value),
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
             subtitle,
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
          if (growth != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                 Icon(
                  growth! >= 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: growth! >= 0 ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                  size: 16,
                ),
                Text(
                  '${growth! >= 0 ? '+' : ''}${growth!.toStringAsFixed(2)}%',
                  style: GoogleFonts.jetBrainsMono(
                    color: growth! >= 0 ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
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

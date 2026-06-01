import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class FundingLegendDialog extends StatelessWidget {
  const FundingLegendDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF161A22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBright.withValues(alpha: 0.6)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Funding Rate Legend',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildLegendItem('>80%', 'Extremely overleveraged longs — strong buy pressure', AppColors.trendGreen),
            _buildLegendItem('60-80%', 'Heavy long positioning — bullish sentiment', AppColors.trendGreen.withValues(alpha: 0.8)),
            _buildLegendItem('51-60%', 'Long skew — more traders expect price up', AppColors.trendGreen.withValues(alpha: 0.6)),
            _buildLegendItem('49-51%', 'Neutral funding — balanced long/short split', AppColors.textSecondary),
            _buildLegendItem('40-49%', 'Short skew — more traders expect price down', AppColors.trendRed.withValues(alpha: 0.6)),
            _buildLegendItem('20-40%', 'Heavy short positioning — bearish sentiment', AppColors.trendRed.withValues(alpha: 0.8)),
            _buildLegendItem('<20%', 'Extremely overleveraged shorts — strong sell pressure', AppColors.trendRed),
            const SizedBox(height: 20),
            Text(
              'Derived from 8H funding. Extreme values can signal squeeze risk. Not financial advice.',
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String range, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              range,
              style: GoogleFonts.jetBrainsMono(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.textPrimary.withValues(alpha: 0.9),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

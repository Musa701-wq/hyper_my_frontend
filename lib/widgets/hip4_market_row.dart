import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/hip4_model.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import 'hip4_probability_bar.dart';
import 'hip4_detail_dialog.dart';

class Hip4MarketRow extends StatelessWidget {
  final Hip4Market market;
  final int index;

  const Hip4MarketRow({super.key, required this.market, required this.index});

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);
    final expiryStr = market.expiry != null 
        ? DateFormat('MMM dd, yyyy, HH:mm').format(market.expiry!.toLocal()) + ' UTC'
        : '--';

    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (context) => Hip4DetailDialog(market: market),
      ),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // # Rank
            SizedBox(
              width: 28,
              child: Text(
                '${index + 1}',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textSecondary.withValues(alpha: 0.4),
                  fontSize: res.fontSize(10),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Market Name + Description — NO ICON, full width
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    market.name,
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textPrimary,
                      fontSize: res.fontSize(12),
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    market.description,
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                      fontSize: res.fontSize(9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),

            // Class Badge
            SizedBox(
              width: 100,
              child: Center(child: _buildClassBadge(market.marketClass, res)),
            ),
            const SizedBox(width: 20),

            // Probability Bar (biggest column)
            Expanded(
              flex: 6,
              child: Hip4ProbabilityBar(outcomes: market.outcomes, height: 10),
            ),
            const SizedBox(width: 20),

            // Expiry
            SizedBox(
              width: 150,
              child: Text(
                expiryStr,
                textAlign: TextAlign.right,
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  fontSize: res.fontSize(9),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassBadge(String marketClass, Responsive res) {
    Color textColor;
    Color borderColor;
    String label = marketClass;

    switch (marketClass) {
      case 'priceBinary':
        textColor = const Color(0xFF38B2AC);
        borderColor = const Color(0xFF38B2AC);
        break;
      case 'priceBucket':
        textColor = const Color(0xFF4299E1);
        borderColor = const Color(0xFF4299E1);
        break;
      case 'question':
        textColor = const Color(0xFFED8936);
        borderColor = const Color(0xFFED8936);
        break;
      default:
        textColor = const Color(0xFF718096);
        borderColor = const Color(0xFF718096);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor.withValues(alpha: 0.7), width: 1),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.jetBrainsMono(
          color: textColor,
          fontSize: res.fontSize(8),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

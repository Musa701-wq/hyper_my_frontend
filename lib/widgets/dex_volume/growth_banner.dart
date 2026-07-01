import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/app_colors.dart';
import '../../utils/responsive.dart';

class GrowthBanner extends StatelessWidget {
  final String title;
  final double growth;

  const GrowthBanner({
    super.key,
    required this.title,
    required this.growth,
  });

  @override
  Widget build(BuildContext context) {
    final bool isNegative = growth < 0;
    final Color statusColor = isNegative ? const Color(0xFFF43F5E) : const Color(0xFF10B981);
    final res = Responsive(context);

    return Container(
      width: double.infinity,
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
            padding: EdgeInsets.symmetric(horizontal: res.spacing(12), vertical: res.spacing(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    color: statusColor.withOpacity(0.7),
                    fontSize: res.fontSize(9),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: res.spacing(6)),
                Row(
                  children: [
                    Icon(
                      isNegative ? Icons.trending_down : Icons.trending_up,
                      color: statusColor,
                      size: res.fontSize(16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${growth.toStringAsFixed(2)}%',
                          maxLines: 1,
                          style: GoogleFonts.jetBrainsMono(
                            color: statusColor,
                            fontSize: res.fontSize(16),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: res.spacing(4)),
                Text(
                  isNegative ? 'Declining vs prior period' : 'Growing vs prior period',
                  style: GoogleFonts.jetBrainsMono(
                    color: statusColor.withOpacity(0.5),
                    fontSize: res.fontSize(9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

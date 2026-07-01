import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive.dart';

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
    final res = Responsive(context);

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
            padding: EdgeInsets.all(res.spacing(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary.withOpacity(0.5),
                    fontSize: res.fontSize(9),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                SizedBox(height: res.spacing(4)),
                Text(
                  _formatValue(value),
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white,
                    fontSize: res.fontSize(14),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: res.spacing(4)),
                Text(
                  subtitle,
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary.withOpacity(0.5),
                    fontSize: res.fontSize(9),
                  ),
                ),
                if (growth != null) ...[
                  SizedBox(height: res.spacing(8)),
                  Row(
                    children: [
                      Icon(
                        growth! >= 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: growth! >= 0 ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                        size: res.fontSize(14),
                      ),
                      Text(
                        '${growth! >= 0 ? '+' : ''}${growth!.toStringAsFixed(2)}%',
                        style: GoogleFonts.jetBrainsMono(
                          color: growth! >= 0 ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                          fontSize: res.fontSize(9),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
    const accentColor = Color(0xFF2EE2BA);
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
          // Top accent bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, Colors.transparent],
                  stops: [0.35, 1.0],
                ),
              ),
            ),
          ),
          // Background Glow
          Positioned(
            top: -20, right: -20,
            child: Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [accentColor.withOpacity(0.05), Colors.transparent],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatValue(value),
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (!isCumulative && change != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        change! >= 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: change! >= 0 ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                        size: 16,
                      ),
                      Text(
                        '${change! >= 0 ? '+' : ''}${change!.toStringAsFixed(2)}%',
                        style: GoogleFonts.jetBrainsMono(
                          color: change! >= 0 ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                          fontSize: 12,
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

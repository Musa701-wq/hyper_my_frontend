import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final Color color = isNegative ? const Color(0xFFF43F5E) : const Color(0xFF10B981);
    final Color bgColor = isNegative ? const Color(0xFFF43F5E).withValues(alpha: 0.1) : const Color(0xFF10B981).withValues(alpha: 0.1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              color: color.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isNegative ? Icons.trending_down : Icons.trending_up,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '${growth.toStringAsFixed(2)}%',
                style: GoogleFonts.jetBrainsMono(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isNegative ? 'Declining vs prior period' : 'Growing vs prior period',
            style: GoogleFonts.jetBrainsMono(
              color: color.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

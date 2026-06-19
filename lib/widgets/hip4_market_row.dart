import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/hip4_model.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';

// Shared coin icon used by both the old row and the new panel cells
class Hip4CoinIcon extends StatelessWidget {
  final Hip4Market market;
  final double size;

  const Hip4CoinIcon({super.key, required this.market, required this.size});

  @override
  Widget build(BuildContext context) {
    final url = market.underlying != null && market.marketClass != 'question'
        ? 'https://app.hyperliquid.xyz/coins/${market.underlying}.svg'
        : null;

    if (url == null) return _fallback();

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.surfaceBright,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: SvgPicture.network(
          url,
          fit: BoxFit.cover,
          placeholderBuilder: (_) => _fallback(),
          errorBuilder: (_, _, _) => _fallback(),
        ),
      ),
    );
  }

  Widget _fallback() {
    final iconChar = market.marketClass == 'question' ? 'Q' : '?';
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.surfaceBright,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        iconChar,
        style: GoogleFonts.jetBrainsMono(
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// Shared class badge used by both the old row and the new panel cells
class Hip4ClassBadge extends StatelessWidget {
  final String marketClass;
  final Responsive res;

  const Hip4ClassBadge({super.key, required this.marketClass, required this.res});

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color borderColor;

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
        marketClass,
        style: GoogleFonts.jetBrainsMono(
          color: textColor,
          fontSize: res.fontSize(8),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Keep Hip4MarketRow for any legacy usage
class Hip4MarketRow extends StatelessWidget {
  final Hip4Market market;
  final int index;

  const Hip4MarketRow({super.key, required this.market, required this.index});

  @override
  Widget build(BuildContext context) {
    // No longer used directly — layout is handled by Hip4MarketsPanel
    return const SizedBox.shrink();
  }
}

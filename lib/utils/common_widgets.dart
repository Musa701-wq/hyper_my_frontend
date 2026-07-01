import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'responsive.dart';

class DotGridPainter extends CustomPainter {
  final Color dotColor;
  final double spacing;

  DotGridPainter({required this.dotColor, this.spacing = 30.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PulseDot extends StatefulWidget {
  final Color color;
  const PulseDot({super.key, this.color = AppColors.trendGreen});

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(_a.value),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(_a.value * 0.5),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base colorful shadow/glow
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background, // Base solid background
              gradient: RadialGradient(
                center: const Alignment(0, 1.0), // Start from bottom center
                radius: 0.8, // Make it subtle and stay in the lower half
                colors: [
                  AppColors.brandAccent.withOpacity(0.1), // Greenish glow
                  AppColors.background.withOpacity(0.0), // Fade out
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
        ),
        // Dot Grid Pattern
        Positioned.fill(
          child: CustomPaint(
            painter: DotGridPainter(
              dotColor: AppColors.surfaceBright.withOpacity(0.5),
              spacing: 35.0,
            ),
          ),
        ),
        // The actual foreground content
        child,
      ],
    );
  }
}

// ─── Section label ─────────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.jetBrainsMono(
        color: AppColors.textSecondary.withOpacity(0.5),
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.0,
      ),
    );
  }
}

// ─── Generic card container matching profile style ─────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final double borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.height,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.15),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: child,
    );
  }
}

// ─── Stat card matching Profile screen design ──────────────────
class StatCardWidget extends StatelessWidget {
  final String label;
  final String value;
  final String? badge;
  final bool badgeUp;
  final bool showBadge;
  final Color? accentColor;

  const StatCardWidget({
    super.key,
    required this.label,
    required this.value,
    this.badge,
    this.badgeUp = true,
    this.showBadge = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final res = Responsive(context);
    final accent = accentColor ?? AppColors.brandAccent;

    return Container(
      padding: EdgeInsets.all(res.spacing(12)),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              if (showBadge && badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: (badgeUp ? AppColors.brandAccent : AppColors.lossRed).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge!,
                    style: GoogleFonts.jetBrainsMono(
                      color: badgeUp ? AppColors.brandAccent : AppColors.lossRed,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white,
                    fontSize: res.fontSize(18),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 14,
                height: 2,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

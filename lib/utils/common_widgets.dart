import 'package:flutter/material.dart';
import 'app_colors.dart';

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
          color: widget.color.withValues(alpha: _a.value),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _a.value * 0.5),
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
                  AppColors.brandAccent.withValues(alpha: 0.1), // Greenish glow
                  AppColors.background.withValues(alpha: 0.0), // Fade out
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
              dotColor: AppColors.surfaceBright.withValues(alpha: 0.5),
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

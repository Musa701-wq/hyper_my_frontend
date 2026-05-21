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

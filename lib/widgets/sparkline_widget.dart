import 'package:flutter/material.dart';
import 'dart:math' as math;

class SparklineWidget extends StatelessWidget {
  final Color color;
  final List<double>? data;
  final double width;
  final double height;
  final String? seed;
  final double changePct;

  const SparklineWidget({
    super.key,
    required this.color,
    this.data,
    this.width = 60,
    this.height = 30,
    this.seed,
    this.changePct = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(
          color: color,
          data: data ?? _generateMockData(),
        ),
      ),
    );
  }

  List<double> _generateMockData() {
    if (seed == null) {
      return [0.4, 0.6, 0.3, 0.5, 0.7, 0.4, 0.6, 0.8];
    }
    // Generate more jagged deterministic data based on seed and changePct
    final List<double> values = [];
    final int hash = seed.hashCode;
    final random = math.Random(hash);
    
    // Calculate a trend bias based on the 24h change percentage
    // Map -20% to +20% change to -0.05 to +0.05 step bias
    final double bias = (changePct / 100).clamp(-0.1, 0.1) * 0.5;
    
    double current = changePct > 0 ? 0.3 : 0.7; // Start low for uptrend, high for downtrend
    values.add(current);
    
    final int points = 12; // More points for jaggedness
    for (int i = 0; i < points - 1; i++) {
      // Add random jaggedness + trend bias
      final double step = (random.nextDouble() - 0.5) * 0.5 + bias;
      current = (current + step).clamp(0.05, 0.95);
      values.add(current);
    }
    return values;
  }
}

class _SparklinePainter extends CustomPainter {
  final Color color;
  final List<double> data;

  _SparklinePainter({required this.color, required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 // Thinner line as requested
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final xStep = size.width / (data.length - 1);
    
    // Normalize data to fit in height (assume data is 0.0 to 1.0)
    // We invert Y because 0 is top
    path.moveTo(0, size.height * (1 - data[0]));

    for (int i = 1; i < data.length; i++) {
        final x = i * xStep;
        final y = size.height * (1 - data[i]);
        
        // Use quadraticBezierTo for smoother lines
        final prevX = (i - 1) * xStep;
        final prevY = size.height * (1 - data[i - 1]);
        final midX = (prevX + x) / 2;
        path.quadraticBezierTo(prevX, prevY, midX, (prevY + y) / 2);
        if (i == data.length - 1) {
          path.lineTo(x, y);
        }
    }

    canvas.drawPath(path, paint);

    // Add a subtle gradient fill below the sparkline
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.2),
          color.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

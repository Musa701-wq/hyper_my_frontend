import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shared shimmer styling used across Home, Order Book, Portfolio, etc.
class ShimmerSkeleton extends StatelessWidget {
  final Widget child;

  const ShimmerSkeleton({super.key, required this.child});

  static Widget pill(double width, double height, {double radius = 6}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  static Widget box(double width, double height, {double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1E222D),
      highlightColor: const Color(0xFF3A3F4E),
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }
}

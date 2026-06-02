import 'package:flutter/material.dart';

class Responsive {
  final BuildContext context;
  Responsive(this.context);

  double get width => MediaQuery.of(context).size.width;
  double get height => MediaQuery.of(context).size.height;

  bool get isMobile => width < 600;
  bool get isTablet => width >= 600 && width < 1200;
  bool get isDesktop => width >= 1200;

  /// Helper for responsive font sizes
  double fontSize(double size) {
    if (isMobile) return size;
    if (isTablet) return size * 1.2;
    return size * 1.4;
  }

  /// Helper for responsive spacing
  double spacing(double space) {
    if (isMobile) return space;
    if (isTablet) return space * 1.5;
    return space * 2.0;
  }

  /// Helper for table column widths
  double columnWidth(double width) {
    if (isMobile) return width;
    if (isTablet) return width * 1.3;
    return width * 1.5;
  }

  bool get isWide => width > 800;
  Orientation get orientation => MediaQuery.of(context).orientation;

  /// Helper for responsive padding
  double horizontalPadding(double padding) {
    if (isMobile) return padding;
    if (isTablet) return padding * 2.0;
    return padding * 3.0;
  }

  /// Returns a value based on device type
  T value<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }

  /// Integer count for grids
  int gridColumnCount({int mobile = 1, int tablet = 2, int desktop = 3}) {
    if (isDesktop) return desktop;
    if (isTablet) return tablet;
    return mobile;
  }
}


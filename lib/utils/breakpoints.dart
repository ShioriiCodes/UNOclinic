import 'package:flutter/material.dart';

/// Desktop breakpoints: small, medium, large.
/// Ensures all pages receive bounded constraints and supports responsive layout.
class Breakpoints {
  /// Tablet width upper bound.
  static const double tablet = 1024;

  /// Small desktop (e.g. 600–900px content width)
  static const double small = 600;

  /// Medium desktop (e.g. 900–1400px)
  static const double medium = 900;

  /// Large desktop (1400px+)
  static const double large = 1400;

  static double contentWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  static bool isSmall(BuildContext context) {
    return contentWidth(context) < medium;
  }

  static bool isTabletOrSmaller(BuildContext context) {
    return contentWidth(context) <= tablet;
  }

  static bool isMedium(BuildContext context) {
    final w = contentWidth(context);
    return w >= medium && w < large;
  }

  static bool isLarge(BuildContext context) {
    return contentWidth(context) >= large;
  }

  /// Responsive padding: smaller on small screens.
  static EdgeInsets pagePadding(BuildContext context) {
    if (isSmall(context)) return const EdgeInsets.all(16);
    if (isMedium(context)) return const EdgeInsets.all(24);
    return const EdgeInsets.all(32);
  }

  /// Horizontal gap between sections (e.g. two-column layout).
  static double sectionGap(BuildContext context) {
    if (isSmall(context)) return 16;
    if (isMedium(context)) return 24;
    return 32;
  }

  /// Max width for the global search bar.
  static double searchMaxWidth(BuildContext context) {
    if (isSmall(context)) return 240;
    if (isMedium(context)) return 320;
    return 400;
  }
}

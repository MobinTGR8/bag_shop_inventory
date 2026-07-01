import 'package:flutter/widgets.dart';

/// Small responsive helpers for consistent padding and layout.
///
/// The goal is: keep screens readable on wide displays (web/tablet/desktop)
/// while staying compact on phones.
class AppBreakpoints {
  AppBreakpoints._();

  static const double compact = 600;
  static const double medium = 1024;
  static const double expanded = 1440;

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool isCompact(BuildContext context) => width(context) < compact;

  static bool isMedium(BuildContext context) =>
      width(context) >= compact && width(context) < medium;

  static bool isExpanded(BuildContext context) => width(context) >= medium;

  static double maxContentWidth(BuildContext context) {
    final w = width(context);
    if (w >= expanded) return 1200;
    if (w >= medium) return 1000;
    if (w >= compact) return 720;
    return double.infinity;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final w = width(context);
    if (w >= expanded) return const EdgeInsets.all(28);
    if (w >= medium) return const EdgeInsets.all(24);
    return const EdgeInsets.all(16);
  }

  static int gridColumns(
    double availableWidth, {
    int compactColumns = 2,
    int mediumColumns = 3,
    int expandedColumns = 4,
  }) {
    if (availableWidth >= medium) return expandedColumns;
    if (availableWidth >= compact) return mediumColumns;
    return compactColumns;
  }
}

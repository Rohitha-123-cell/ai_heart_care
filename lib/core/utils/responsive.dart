import 'package:flutter/material.dart';

class Responsive {
  static double width(BuildContext context) => MediaQuery.of(context).size.width;

  static double height(BuildContext context) => MediaQuery.of(context).size.height;

  static bool isMobile(BuildContext context) => width(context) < 700;

  static bool isTablet(BuildContext context) =>
      width(context) >= 700 && width(context) < 1100;

  static bool isDesktop(BuildContext context) => width(context) >= 1100;

  static double font(BuildContext context, double size) => width(context) * size;

  static double maxContentWidth(BuildContext context) {
    if (isDesktop(context)) return 1280;
    if (isTablet(context)) return 920;
    return width(context);
  }

  static EdgeInsets pagePadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 40, vertical: 32);
    }
    if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 28, vertical: 24);
    }
    return const EdgeInsets.symmetric(horizontal: 20, vertical: 18);
  }
}

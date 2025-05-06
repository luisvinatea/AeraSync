import 'package:flutter/material.dart';

class ResponsiveUtil {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 900;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900;

  static double contentPadding(BuildContext context) => isMobile(context)
      ? 12
      : isTablet(context)
          ? 24
          : 36;

  static Widget responsiveBuilder({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    required Widget desktop,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    } else {
      return desktop;
    }
  }
}

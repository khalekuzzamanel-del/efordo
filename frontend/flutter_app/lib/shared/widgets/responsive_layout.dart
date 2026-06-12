import 'package:flutter/material.dart';

import '../../app/theme/responsive_breakpoints.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (ResponsiveBreakpoints.isDesktop(width) && desktop != null) {
      return desktop!;
    }
    if (ResponsiveBreakpoints.isTablet(width) && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}

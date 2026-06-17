import 'package:flutter/widgets.dart';

class ResponsiveBreakpoints {
  static const double compact = 600;
  static const double medium = 900;
  static const double expanded = 1200;
}

extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;

  bool get isCompact => screenWidth < ResponsiveBreakpoints.compact;
  bool get isMedium =>
      screenWidth >= ResponsiveBreakpoints.compact &&
      screenWidth < ResponsiveBreakpoints.medium;
  bool get isExpanded => screenWidth >= ResponsiveBreakpoints.medium;

  double get responsiveHorizontalPadding {
    if (screenWidth >= ResponsiveBreakpoints.expanded) return 32;
    if (screenWidth >= ResponsiveBreakpoints.medium) return 24;
    return 16;
  }

  double get responsiveMaxContentWidth {
    if (screenWidth >= ResponsiveBreakpoints.expanded) return 1180;
    if (screenWidth >= ResponsiveBreakpoints.medium) return 960;
    return double.infinity;
  }
}

class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Alignment alignment;
  final double? maxWidth;

  const ResponsiveContent({
    super.key,
    required this.child,
    this.padding,
    this.alignment = Alignment.topCenter,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedMaxWidth = maxWidth ?? context.responsiveMaxContentWidth;
    final resolvedPadding =
        padding ??
        EdgeInsets.symmetric(horizontal: context.responsiveHorizontalPadding);

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: resolvedMaxWidth),
        child: Padding(padding: resolvedPadding, child: child),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Centers content and applies a max width for desktop/web, while keeping
/// mobile layouts full-width with standard horizontal padding.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 520,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveMaxWidth = constraints.maxWidth < maxWidth
            ? constraints.maxWidth
            : maxWidth;

        return Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: padding,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import 'responsive_center.dart';

/// Standard page scaffold used across the app.
///
/// - SafeArea
/// - Optional centered and constrained body for desktop/web
/// - Consistent background
class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.centered = false,
    this.maxWidth = 960,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    this.floatingActionButton,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final bool centered;
  final double maxWidth;
  final EdgeInsets padding;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final content = centered
        ? ResponsiveCenter(
            maxWidth: maxWidth,
            padding: padding,
            child: body,
          )
        : Padding(padding: padding, child: body);

    return Scaffold(
      appBar: appBar,
      body: SafeArea(child: content),
      floatingActionButton: floatingActionButton,
    );
  }
}

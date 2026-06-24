import 'package:flutter/material.dart';

/// Scrollable body for screens or sheets that may overflow with large text.
class AccessibleScrollBody extends StatelessWidget {
  const AccessibleScrollBody({
    super.key,
    required this.child,
    this.padding,
    this.center = false,
    this.minHeight,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool center;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedMinHeight = minHeight ?? constraints.maxHeight;

        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: resolvedMinHeight),
            child: center ? Center(child: child) : child,
          ),
        );
      },
    );
  }
}

/// Wraps bottom-sheet content so it scrolls when text scale is large.
class AccessibleSheetBody extends StatelessWidget {
  const AccessibleSheetBody({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 24),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: padding,
        child: child,
      ),
    );
  }
}

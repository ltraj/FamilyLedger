import 'package:flutter/material.dart';

/// The Reports screen's first-load placeholder: gray section-shaped
/// blocks where the sections will appear. Shown only before the first
/// data arrives — filter changes reuse the previous data instead of
/// flashing back to this (see `skipLoadingOnReload` in `ReportsScreen`).
class ReportSkeleton extends StatelessWidget {
  const ReportSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blockColor = theme.colorScheme.surfaceContainerHigh;

    Widget block(double height) => Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: blockColor,
        borderRadius: BorderRadius.circular(20),
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      children: [block(180), block(64), block(64), block(64), block(64)],
    );
  }
}

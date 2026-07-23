import 'package:family_ledger/core/utils/currency_formatter.dart';
import 'package:family_ledger/features/settings/providers/settings_view_model.dart';
import 'package:family_ledger/projections/reports/report_breakdowns.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Plain-widget charts for Section 7 and the person detail screen — no
/// chart package, just proportional boxes, so there's nothing to theme
/// twice and nothing decorative. All values arrive pre-computed; these
/// widgets only scale and label them.

/// Vertical bars, one per month, horizontally scrollable when the range
/// is long. Bars scale against the series maximum.
class MonthlyBarChart extends StatelessWidget {
  const MonthlyBarChart({super.key, required this.points, this.barColor});

  final List<TrendPoint> points;
  final Color? barColor;

  static const double _chartHeight = 120;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (points.isEmpty) return const SizedBox.shrink();

    var max = 0.0;
    for (final point in points) {
      if (point.value > max) max = point.value;
    }

    final color = barColor ?? theme.colorScheme.primary;

    return SizedBox(
      height: _chartHeight + 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // Newest month nearest the left edge would read backwards; keep
        // oldest-first and start scrolled to the end (most recent).
        reverse: true,
        itemCount: points.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final point = points[points.length - 1 - index];
          final fraction = max == 0 ? 0.0 : point.value / max;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                _compactAmount(point.value),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 30,
                height: (_chartHeight * fraction).clamp(2.0, _chartHeight),
                decoration: BoxDecoration(
                  color: point.value == 0
                      ? theme.colorScheme.surfaceContainerHighest
                      : color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _monthLabel(point.month),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Horizontal proportional bars, one per category, largest first.
class CategoryBarList extends ConsumerWidget {
  const CategoryBarList({super.key, required this.items, this.maxItems = 8});

  final List<CategoryAmount> items;
  final int maxItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    if (items.isEmpty) return const SizedBox.shrink();

    final currencySymbol = ref.watch(currencySymbolProvider);

    final shown = items.take(maxItems).toList();
    final max = shown.first.amount;

    return Column(
      children: [
        for (final item in shown)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        item.category?.name ?? 'No category',
                        style: theme.textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CurrencyFormatter.format(
                        item.amount,
                        symbol: currencySymbol,
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 8,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        FractionallySizedBox(
                          widthFactor: max == 0
                              ? 0
                              : (item.amount / max).clamp(0.02, 1.0),
                          child: Container(color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

String _compactAmount(double value) {
  if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
  return value.toStringAsFixed(0);
}

const List<String> _shortMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _monthLabel(DateTime month) =>
    "${_shortMonths[month.month - 1]} '${month.year % 100}";

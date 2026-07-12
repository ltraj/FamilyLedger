import 'package:family_ledger/core/utils/balance_colors.dart';
import 'package:family_ledger/features/reports/widgets/report_bar_charts.dart';
import 'package:family_ledger/projections/reports/reports_overview.dart';
import 'package:flutter/material.dart';

/// Section 7: the three charts worth having — monthly expenses, monthly
/// advances, and per-category spending. Each series is a getter on
/// [ReportsOverview] over already-computed sections, so the charts can
/// never disagree with the tables. Charts that would show a single
/// meaningless bar (fewer than two months of data) are skipped.
class SpendingTrendsSection extends StatelessWidget {
  const SpendingTrendsSection({super.key, required this.overview});

  final ReportsOverview overview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final expensesTrend = overview.monthlyExpensesTrend;
    final advancesTrend = overview.monthlyAdvancesTrend;
    final categorySpending = overview.categorySpending;

    final showMonthlyCharts = expensesTrend.length >= 2;

    if (!showMonthlyCharts && categorySpending.isEmpty) {
      return Text(
        'Trends appear once there is spending across more than one month.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showMonthlyCharts) ...[
          const _ChartHeader('Monthly Expenses'),
          MonthlyBarChart(
            points: expensesTrend,
            barColor: BalanceColors.negative,
          ),
          const SizedBox(height: 16),
          const _ChartHeader('Monthly Advances'),
          MonthlyBarChart(
            points: advancesTrend,
            barColor: BalanceColors.positive,
          ),
          const SizedBox(height: 16),
        ],
        if (categorySpending.isNotEmpty) ...[
          const _ChartHeader('Category Spending'),
          CategoryBarList(items: categorySpending),
        ],
      ],
    );
  }
}

class _ChartHeader extends StatelessWidget {
  const _ChartHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

import 'package:family_ledger/core/utils/balance_colors.dart';
import 'package:family_ledger/core/utils/currency_formatter.dart';
import 'package:family_ledger/projections/reports/monthly_report.dart';
import 'package:flutter/material.dart';

/// Section 4: month-by-month movements with a cumulative running balance.
/// Oldest month first so the running balance reads top to bottom.
class MonthlyAnalysisSection extends StatelessWidget {
  const MonthlyAnalysisSection({super.key, required this.reports});

  final List<MonthlyReport> reports;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (reports.isEmpty) {
      return Text(
        'No transactions in this period.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      children: [
        for (final report in reports)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _MonthTile(report: report),
          ),
      ],
    );
  }
}

class _MonthTile extends StatelessWidget {
  const _MonthTile({required this.report});

  final MonthlyReport report;

  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final netColor = BalanceColors.forBalance(
      context,
      hasTransactions: true,
      balance: report.netChange,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_months[report.month.month - 1]} ${report.month.year}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${report.netChange >= 0 ? '+' : ''}'
                '${CurrencyFormatter.format(report.netChange)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: netColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _MonthFigure(
                label: 'Advances',
                value: CurrencyFormatter.format(report.advances),
              ),
              _MonthFigure(
                label: 'Expenses',
                value: CurrencyFormatter.format(report.expenses),
              ),
              _MonthFigure(
                label: 'Returned',
                value: CurrencyFormatter.format(report.moneyReturned),
              ),
              _MonthFigure(
                label: 'Running balance',
                value: CurrencyFormatter.format(report.runningBalance),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthFigure extends StatelessWidget {
  const _MonthFigure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

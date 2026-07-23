import 'package:family_ledger/core/utils/currency_formatter.dart';
import 'package:family_ledger/features/settings/providers/settings_view_model.dart';
import 'package:family_ledger/projections/reports/top_lists_report.dart';
import 'package:family_ledger/projections/transaction_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Section 5: the extremes of the filtered period. Rows whose record
/// doesn't exist in the data are omitted entirely rather than rendered
/// with placeholders.
class TopListsSection extends ConsumerWidget {
  const TopListsSection({super.key, required this.report});

  final TopListsReport report;

  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currencySymbol = ref.watch(currencySymbolProvider);

    String transactionLine(TransactionDetails details) {
      final category = details.category?.name;
      return '${details.person.name}'
          '${category == null ? '' : ' · $category'} · '
          '${CurrencyFormatter.format(details.transaction.amount.abs(), symbol: currencySymbol)}';
    }

    final rows = <Widget>[
      if (report.highestExpense case final expense?)
        _TopRow(
          icon: Icons.trending_down,
          label: 'Highest Expense',
          value: transactionLine(expense),
        ),
      if (report.highestAdvance case final advance?)
        _TopRow(
          icon: Icons.trending_up,
          label: 'Highest Advance',
          value: transactionLine(advance),
        ),
      if (report.largestTransaction case final largest?)
        _TopRow(
          icon: Icons.receipt_long_outlined,
          label: 'Largest Transaction',
          value: transactionLine(largest),
        ),
      if (report.mostActivePerson case final active?)
        _TopRow(
          icon: Icons.bolt_outlined,
          label: 'Most Active Person',
          value:
              '${active.person.name} · ${active.transactionCount} transactions',
        ),
      if (report.mostUsedCategory case final category?)
        _TopRow(
          icon: Icons.category_outlined,
          label: 'Most Used Category',
          value:
              '${category.category.name} · '
              '${category.transactionCount} transactions',
        ),
      if (report.largestExpenseMonth case final month?)
        _TopRow(
          icon: Icons.calendar_month_outlined,
          label: 'Largest Monthly Expense',
          value:
              '${_months[month.month.month - 1]} ${month.month.year} · '
              '${CurrencyFormatter.format(month.expenses, symbol: currencySymbol)}',
        ),
    ];

    if (rows.isEmpty) {
      return Text(
        'No transactions in this period.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(children: rows);
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:family_ledger/core/utils/balance_colors.dart';
import 'package:family_ledger/core/utils/currency_formatter.dart';
import 'package:family_ledger/features/reports/widgets/report_stat_row.dart';
import 'package:family_ledger/projections/reports/own_pocket_report.dart';
import 'package:flutter/material.dart';

/// Section 6: where the user's own money went — overall, by month, by
/// person, and by category. Hidden behind a friendly all-clear message
/// when nothing was ever paid out of pocket.
class OwnPocketSection extends StatelessWidget {
  const OwnPocketSection({super.key, required this.report});

  final OwnPocketReport report;

  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (report.isEmpty) {
      return Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 20,
            color: BalanceColors.positive,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Every expense in this period was covered by advance money — '
              'nothing came from your own pocket.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReportStatRow(
          label: 'Total from your own pocket',
          value: CurrencyFormatter.format(report.total),
          emphasized: true,
          valueColor: BalanceColors.negative,
        ),
        if (report.monthly.isNotEmpty) ...[
          const _SubHeader('By month'),
          for (final point in report.monthly)
            ReportStatRow(
              label: '${_months[point.month.month - 1]} ${point.month.year}',
              value: CurrencyFormatter.format(point.value),
            ),
        ],
        if (report.perPerson.isNotEmpty) ...[
          const _SubHeader('By person'),
          for (final entry in report.perPerson)
            ReportStatRow(
              label: entry.person.name,
              value: CurrencyFormatter.format(entry.amount),
            ),
        ],
        if (report.perCategory.isNotEmpty) ...[
          const _SubHeader('By category'),
          for (final entry in report.perCategory)
            ReportStatRow(
              label: entry.category?.name ?? 'No category',
              value: CurrencyFormatter.format(entry.amount),
            ),
        ],
      ],
    );
  }
}

class _SubHeader extends StatelessWidget {
  const _SubHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
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

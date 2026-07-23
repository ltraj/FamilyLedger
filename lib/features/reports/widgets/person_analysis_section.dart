import 'package:family_ledger/core/utils/balance_colors.dart';
import 'package:family_ledger/core/utils/currency_formatter.dart';
import 'package:family_ledger/core/utils/friendly_date.dart';
import 'package:family_ledger/features/people/widgets/person_avatar.dart';
import 'package:family_ledger/features/reports/screens/person_report_screen.dart';
import 'package:family_ledger/features/settings/providers/settings_view_model.dart';
import 'package:family_ledger/projections/reports/person_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Section 2: one expandable card per person. Tapping the header opens
/// the full [PersonReportScreen]; the inline grid shows the filtered
/// period's figures.
class PersonAnalysisSection extends StatelessWidget {
  const PersonAnalysisSection({super.key, required this.reports});

  final List<PersonReport> reports;

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const _SectionEmptyMessage(
        'No one has transactions in this period.',
      );
    }

    return Column(
      children: [
        for (final report in reports)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _PersonReportCard(report: report),
          ),
      ],
    );
  }
}

class _PersonReportCard extends ConsumerWidget {
  const _PersonReportCard({required this.report});

  final PersonReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PersonReportScreen(person: report.person),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PersonAvatar(person: report.person, radius: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.person.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${report.transactionCount} transactions · '
                          '${FriendlyDate.format(report.firstTransactionDate)}'
                          ' – '
                          '${FriendlyDate.format(report.latestTransactionDate)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(
                      report.currentBalance,
                      symbol: currencySymbol,
                    ),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: BalanceColors.forBalance(
                        context,
                        hasTransactions: true,
                        balance: report.currentBalance,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _MiniStat(
                    label: 'Advance',
                    value: CurrencyFormatter.format(
                      report.advanceReceived,
                      symbol: currencySymbol,
                    ),
                  ),
                  _MiniStat(
                    label: 'Expenses',
                    value: CurrencyFormatter.format(
                      report.expenses,
                      symbol: currencySymbol,
                    ),
                  ),
                  _MiniStat(
                    label: 'Returned',
                    value: CurrencyFormatter.format(
                      report.moneyReturned,
                      symbol: currencySymbol,
                    ),
                  ),
                  _MiniStat(
                    label: 'Avg / txn',
                    value: CurrencyFormatter.format(
                      report.averageTransaction,
                      symbol: currencySymbol,
                    ),
                  ),
                  if (report.largestExpense != null)
                    _MiniStat(
                      label: 'Largest expense',
                      value: CurrencyFormatter.format(
                        report.largestExpense!,
                        symbol: currencySymbol,
                      ),
                    ),
                  if (report.largestAdvance != null)
                    _MiniStat(
                      label: 'Largest advance',
                      value: CurrencyFormatter.format(
                        report.largestAdvance!,
                        symbol: currencySymbol,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

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

class _SectionEmptyMessage extends StatelessWidget {
  const _SectionEmptyMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

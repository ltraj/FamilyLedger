import 'package:family_ledger/core/utils/balance_colors.dart';
import 'package:family_ledger/core/utils/currency_formatter.dart';
import 'package:family_ledger/features/dashboard/widgets/recent_activity_tile.dart';
import 'package:family_ledger/features/people/widgets/person_avatar.dart';
import 'package:family_ledger/features/reports/providers/reports_view_model.dart';
import 'package:family_ledger/features/reports/widgets/report_bar_charts.dart';
import 'package:family_ledger/features/reports/widgets/report_stat_row.dart';
import 'package:family_ledger/features/settings/providers/settings_view_model.dart';
import 'package:family_ledger/features/transactions/screens/transaction_screen.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/projections/reports/person_report_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One person's full-history report, opened from Section 2.
///
/// Reactive through `personReportDetailProvider` — add a transaction for
/// this person anywhere in the app and this screen recomputes. Tapping a
/// timeline entry jumps to the person's Transaction screen for editing.
class PersonReportScreen extends ConsumerWidget {
  const PersonReportScreen({super.key, required this.person});

  final PersonModel person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(personReportDetailProvider(person.id!));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            PersonAvatar(person: person, radius: 16),
            const SizedBox(width: 10),
            Flexible(
              child: Text(person.name, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Could not load this report: $error'),
        ),
        data: (detail) => detail.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    '${person.name} has no transactions yet, so there is '
                    'nothing to report.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              )
            : _PersonReportBody(person: person, detail: detail),
      ),
    );
  }
}

class _PersonReportBody extends ConsumerWidget {
  const _PersonReportBody({required this.person, required this.detail});

  final PersonModel person;
  final PersonReportDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currencySymbol = ref.watch(currencySymbolProvider);

    void openTransactions() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TransactionScreen(person: person),
        ),
      );
    }

    Widget sectionCard({required String title, required Widget child}) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        color: theme.colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        sectionCard(
          title: 'Overview',
          child: Column(
            children: [
              ReportStatRow(
                label: 'Current Balance',
                value: CurrencyFormatter.format(
                  detail.currentBalance,
                  symbol: currencySymbol,
                ),
                emphasized: true,
                valueColor: BalanceColors.forBalance(
                  context,
                  hasTransactions: true,
                  balance: detail.currentBalance,
                ),
              ),
              ReportStatRow(
                label: 'Total Expenses',
                value: CurrencyFormatter.format(
                  detail.totalExpenses,
                  symbol: currencySymbol,
                ),
              ),
              ReportStatRow(
                label: 'Average Monthly Expense',
                value: CurrencyFormatter.format(
                  detail.averageMonthlyExpense,
                  symbol: currencySymbol,
                ),
              ),
            ],
          ),
        ),
        if (detail.monthlySpendingTrend.length >= 2)
          sectionCard(
            title: 'Monthly Spending',
            child: MonthlyBarChart(
              points: detail.monthlySpendingTrend,
              barColor: BalanceColors.negative,
            ),
          ),
        if (detail.categoryUsage.isNotEmpty)
          sectionCard(
            title: 'Category Usage',
            child: CategoryBarList(items: detail.categoryUsage),
          ),
        if (detail.largestExpenses.isNotEmpty)
          sectionCard(
            title: 'Largest Expenses',
            child: Column(
              children: [
                for (final details in detail.largestExpenses)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RecentActivityTile(
                      details: details,
                      onTap: openTransactions,
                    ),
                  ),
              ],
            ),
          ),
        if (detail.largestAdvances.isNotEmpty)
          sectionCard(
            title: 'Largest Advances',
            child: Column(
              children: [
                for (final details in detail.largestAdvances)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RecentActivityTile(
                      details: details,
                      onTap: openTransactions,
                    ),
                  ),
              ],
            ),
          ),
        sectionCard(
          title: 'Timeline',
          child: Column(
            children: [
              for (final details in detail.timeline)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: RecentActivityTile(
                    details: details,
                    onTap: openTransactions,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

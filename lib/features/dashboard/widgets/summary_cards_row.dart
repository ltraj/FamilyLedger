import 'package:family_ledger/core/utils/balance_colors.dart';
import 'package:family_ledger/core/utils/currency_formatter.dart';
import 'package:family_ledger/features/dashboard/providers/dashboard_view_model.dart';
import 'package:family_ledger/features/dashboard/widgets/summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef _SummaryFigures = ({
  double advanceHeld,
  double owedToMe,
  double netPosition,
  int activePeople,
  double thisMonthExpenses,
});

/// The five summary cards: Advance Held, People Owe Me, Net Position,
/// Active People, This Month's Expenses.
///
/// Selects only these five figures out of the full `DashboardSummary`
/// (via a record, which has built-in value equality), so this row does
/// not rebuild when something elsewhere in the summary changes — e.g. a
/// new attention item — without affecting any of these five numbers.
class SummaryCardsRow extends ConsumerWidget {
  const SummaryCardsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final figures = ref.watch(
      dashboardViewModelProvider.select<_SummaryFigures?>((async) {
        final summary = async.valueOrNull;
        if (summary == null) return null;
        return (
          advanceHeld: summary.totalAdvanceHeld,
          owedToMe: summary.totalOwedToMe,
          netPosition: summary.netPosition,
          activePeople: summary.activePersonCount,
          thisMonthExpenses: summary.thisMonthExpenses,
        );
      }),
    );

    if (figures == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = switch (constraints.maxWidth) {
          >= 700 => 5,
          >= 420 => 3,
          _ => 2,
        };

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            SummaryCard(
              label: 'Advance Held',
              value: CurrencyFormatter.format(figures.advanceHeld),
              icon: Icons.savings_outlined,
              valueColor: BalanceColors.positive,
            ),
            SummaryCard(
              label: 'People Owe Me',
              value: CurrencyFormatter.format(figures.owedToMe),
              icon: Icons.request_quote_outlined,
              valueColor: BalanceColors.negative,
            ),
            SummaryCard(
              label: 'Net Position',
              value: CurrencyFormatter.format(figures.netPosition),
              icon: Icons.account_balance_outlined,
              valueColor: figures.netPosition >= 0
                  ? BalanceColors.positive
                  : BalanceColors.negative,
            ),
            SummaryCard(
              label: 'Active People',
              value: '${figures.activePeople}',
              icon: Icons.groups_outlined,
            ),
            SummaryCard(
              label: "This Month's Expenses",
              value: CurrencyFormatter.format(figures.thisMonthExpenses),
              icon: Icons.trending_down_outlined,
              valueColor: BalanceColors.negative,
            ),
          ],
        );
      },
    );
  }
}

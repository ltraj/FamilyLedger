import 'package:family_ledger/core/utils/currency_formatter.dart';
import 'package:family_ledger/features/settings/providers/settings_view_model.dart';
import 'package:family_ledger/projections/dashboard_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Calculated-only figures: no AI, no charts, just facts already present
/// in [DashboardSummary]. Hides itself entirely if there's nothing to
/// show (a brand new ledger with no data yet).
class QuickInsightsSection extends ConsumerWidget {
  const QuickInsightsSection({super.key, required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final insights = _buildInsights(currencySymbol);

    if (insights.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Insights',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            for (final insight in insights) _InsightRow(insight: insight),
          ],
        ),
      ),
    );
  }

  List<_Insight> _buildInsights(String currencySymbol) {
    final highestAdvance = summary.highestAdvancePerson;
    final mostOwing = summary.mostOwingPerson;
    final mostActive = summary.mostActivePersonThisMonth;
    final mostUsedCategory = summary.mostUsedCategory;
    final largestExpense = summary.largestExpenseThisMonth;

    return [
      if (highestAdvance != null)
        _Insight(
          label: 'Highest remaining advance',
          value:
              '${highestAdvance.person.name} · '
              '${CurrencyFormatter.format(highestAdvance.balance, symbol: currencySymbol)}',
          icon: Icons.trending_up,
        ),
      if (mostOwing != null)
        _Insight(
          label: 'Owes you the most',
          value:
              '${mostOwing.person.name} · '
              '${CurrencyFormatter.format(-mostOwing.balance, symbol: currencySymbol)}',
          icon: Icons.trending_down,
        ),
      if (mostActive != null)
        _Insight(
          label: 'Most active this month',
          value: mostActive.person.name,
          icon: Icons.bolt_outlined,
        ),
      if (mostUsedCategory != null)
        _Insight(
          label: 'Most used category',
          value: mostUsedCategory.name,
          icon: Icons.category_outlined,
        ),
      if (largestExpense != null)
        _Insight(
          label: "Largest expense this month",
          value:
              '${largestExpense.person.name} · '
              '${CurrencyFormatter.format(largestExpense.transaction.amount, symbol: currencySymbol)}',
          icon: Icons.receipt_long_outlined,
        ),
    ];
  }
}

class _Insight {
  const _Insight({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.insight});

  final _Insight insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(insight.icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  insight.value,
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

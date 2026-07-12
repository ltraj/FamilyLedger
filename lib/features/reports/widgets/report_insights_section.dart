import 'package:family_ledger/projections/reports/report_insight.dart';
import 'package:flutter/material.dart';

/// Section 8: the engine's calculated statements, one row each. The
/// widget renders whatever `ReportEngine._buildInsights` produced —
/// nothing is composed or concluded here.
class ReportInsightsSection extends StatelessWidget {
  const ReportInsightsSection({super.key, required this.insights});

  final List<ReportInsight> insights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (insights.isEmpty) {
      return Text(
        'Insights appear once there is enough data to support them.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      children: [
        for (final insight in insights)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _iconFor(insight.kind),
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(insight.message, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
      ],
    );
  }

  IconData _iconFor(ReportInsightKind kind) => switch (kind) {
    ReportInsightKind.spending => Icons.trending_down,
    ReportInsightKind.person => Icons.person_outline,
    ReportInsightKind.category => Icons.category_outlined,
    ReportInsightKind.ownPocket => Icons.account_balance_wallet_outlined,
    ReportInsightKind.balance => Icons.account_balance_outlined,
  };
}

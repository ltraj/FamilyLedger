import 'package:family_ledger/core/utils/currency_formatter.dart';
import 'package:family_ledger/features/people/widgets/person_avatar.dart';
import 'package:family_ledger/features/settings/providers/settings_view_model.dart';
import 'package:family_ledger/projections/attention_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One card in the Dashboard's Attention Center: who needs action, and
/// why. Tapping opens their Transaction screen.
class AttentionCard extends ConsumerWidget {
  const AttentionCard({super.key, required this.item, required this.onTap});

  final AttentionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final summary = item.personSummary;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: _containerColorFor(item.reason, theme.colorScheme),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              PersonAvatar(person: summary.person, radius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.person.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _detailFor(item, currencySymbol),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _containerColorFor(AttentionReason reason, ColorScheme scheme) {
    return switch (reason) {
      AttentionReason.negativeBalance => scheme.errorContainer,
      AttentionReason.lowRemainingAdvance ||
      AttentionReason.temporaryPersonPending ||
      AttentionReason.longInactive ||
      AttentionReason.recentlyEditedTransaction => scheme.tertiaryContainer,
    };
  }

  String _detailFor(AttentionItem item, String currencySymbol) {
    final balance = item.personSummary.balance;
    return switch (item.reason) {
      AttentionReason.negativeBalance =>
        'Owes ${CurrencyFormatter.format(-balance, symbol: currencySymbol)}',
      AttentionReason.lowRemainingAdvance =>
        'Only ${CurrencyFormatter.format(balance, symbol: currencySymbol)} advance remaining',
      AttentionReason.temporaryPersonPending =>
        'Temporary contact with an open balance',
      // Prepared, not produced yet — see AttentionReason's doc comment.
      AttentionReason.longInactive => 'Inactive for a while',
      AttentionReason.recentlyEditedTransaction => 'Recently edited',
    };
  }
}

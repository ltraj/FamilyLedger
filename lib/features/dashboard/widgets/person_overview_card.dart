import 'package:family_ledger/core/utils/balance_colors.dart';
import 'package:family_ledger/core/utils/currency_formatter.dart';
import 'package:family_ledger/core/utils/friendly_date.dart';
import 'package:family_ledger/features/people/widgets/person_avatar.dart';
import 'package:family_ledger/projections/person_summary.dart';
import 'package:flutter/material.dart';

/// A person's at-a-glance card in the Dashboard's People Overview: avatar,
/// name, balance, and last activity — read-only (no management actions;
/// those live on the People screen's `PersonCard`). Tapping opens their
/// Transaction screen.
class PersonOverviewCard extends StatelessWidget {
  const PersonOverviewCard({
    super.key,
    required this.summary,
    required this.onTap,
  });

  final PersonSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balanceColor = BalanceColors.forBalance(
      context,
      hasTransactions: summary.hasTransactions,
      balance: summary.balance,
    );

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              PersonAvatar(person: summary.person, radius: 22),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _statsLine(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                CurrencyFormatter.format(summary.balance),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: balanceColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statsLine() {
    if (!summary.hasTransactions) return 'No transactions';
    final countLabel = summary.transactionCount == 1
        ? '1 transaction'
        : '${summary.transactionCount} transactions';
    final lastDate = summary.lastTransactionDate;
    return lastDate == null
        ? countLabel
        : '$countLabel · ${FriendlyDate.format(lastDate)}';
  }
}

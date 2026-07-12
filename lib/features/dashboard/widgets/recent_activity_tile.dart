import 'package:family_ledger/core/utils/balance_calculator.dart';
import 'package:family_ledger/core/utils/balance_colors.dart';
import 'package:family_ledger/core/utils/currency_formatter.dart';
import 'package:family_ledger/core/utils/relative_date.dart';
import 'package:family_ledger/features/people/widgets/person_avatar.dart';
import 'package:family_ledger/features/transactions/models/transaction_type_label.dart';
import 'package:family_ledger/projections/transaction_details.dart';
import 'package:flutter/material.dart';

/// One entry in the Dashboard's Recent Activity feed: unlike
/// `TransactionCard` (used on a single person's own Transaction screen),
/// this shows whose transaction it is, since entries span every person.
/// Tapping opens that person's Transaction screen.
class RecentActivityTile extends StatelessWidget {
  const RecentActivityTile({
    super.key,
    required this.details,
    required this.onTap,
  });

  final TransactionDetails details;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transaction = details.transaction;
    final signedAmount = BalanceCalculator.signedAmount(transaction);

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
              PersonAvatar(person: details.person, radius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${details.person.name} · ${transaction.transactionType.label}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${details.category?.name ?? 'No category'} · '
                      '${RelativeDate.format(transaction.date)}',
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _signedAmountLabel(signedAmount),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: BalanceColors.forBalance(
                        context,
                        hasTransactions: true,
                        balance: signedAmount,
                      ),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bal ${CurrencyFormatter.format(details.runningBalanceAfter)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

  String _signedAmountLabel(double signedAmount) {
    final formatted = CurrencyFormatter.format(signedAmount);
    return signedAmount >= 0 ? '+$formatted' : formatted;
  }
}

import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/core/utils/balance_colors.dart';
import 'package:family_ledger/core/utils/currency_formatter.dart';
import 'package:family_ledger/core/utils/friendly_date.dart';
import 'package:family_ledger/features/people/widgets/person_avatar.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:flutter/material.dart';

/// Top section of the Transaction screen: avatar, name, a large balance
/// indicator, transaction count, and last transaction date.
class PersonBalanceHeader extends StatelessWidget {
  const PersonBalanceHeader({
    super.key,
    required this.person,
    required this.balance,
    required this.transactionCount,
    required this.lastTransactionDate,
  });

  final PersonModel person;
  final double balance;
  final int transactionCount;
  final DateTime? lastTransactionDate;

  bool get _hasTransactions => transactionCount > 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balanceColor = BalanceColors.forBalance(
      context,
      hasTransactions: _hasTransactions,
      balance: balance,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          PersonAvatar(person: person, radius: 32),
          const SizedBox(height: 12),
          Text(
            person.name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            person.type == PersonType.permanent ? 'Permanent' : 'Temporary',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              CurrencyFormatter.format(balance),
              key: ValueKey(balance),
              style: theme.textTheme.displaySmall?.copyWith(
                color: balanceColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _statsLine(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _statsLine() {
    if (!_hasTransactions) return 'No activity yet';

    final countLabel = transactionCount == 1
        ? '1 transaction'
        : '$transactionCount transactions';
    final lastDate = lastTransactionDate;

    return lastDate == null
        ? countLabel
        : '$countLabel · ${FriendlyDate.format(lastDate)}';
  }
}

import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/core/utils/balance_colors.dart';
import 'package:family_ledger/core/utils/currency_formatter.dart';
import 'package:family_ledger/core/utils/friendly_date.dart';
import 'package:family_ledger/features/people/widgets/person_avatar.dart';
import 'package:family_ledger/features/settings/providers/settings_view_model.dart';
import 'package:family_ledger/projections/person_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _PersonCardAction { edit, regenerateAvatar, archive, restore, delete }

/// A single person's card on the People screen: avatar, name, type,
/// balance, and quick stats, with an overflow menu for edit/archive/
/// restore/delete actions.
class PersonCard extends ConsumerWidget {
  const PersonCard({
    super.key,
    required this.summary,
    required this.onOpenTransactions,
    required this.onEdit,
    required this.onRegenerateAvatar,
    required this.onArchive,
    required this.onRestore,
    required this.onDelete,
  });

  final PersonSummary summary;

  /// Tapping the card body opens this person's Transaction screen —
  /// editing moved to the overflow menu (see [onEdit]) so the card's
  /// primary action is navigation, matching the Transaction module.
  final VoidCallback onOpenTransactions;
  final VoidCallback onEdit;
  final VoidCallback onRegenerateAvatar;
  final VoidCallback onArchive;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final person = summary.person;
    final isArchived = person.status == PersonStatus.archived;

    final balanceColor = BalanceColors.forBalance(
      context,
      hasTransactions: summary.hasTransactions,
      balance: summary.balance,
    );

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenTransactions,
        child: Opacity(
          opacity: isArchived ? 0.65 : 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PersonAvatar(person: person, radius: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              person.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isArchived) ...[
                            const SizedBox(width: 8),
                            const _ArchivedBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        person.type == PersonType.permanent
                            ? 'Permanent'
                            : 'Temporary',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  CurrencyFormatter.format(
                                    summary.balance,
                                    symbol: currencySymbol,
                                  ),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: balanceColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _statsLine(summary),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _PersonCardMenu(
                            isArchived: isArchived,
                            onEdit: onEdit,
                            onRegenerateAvatar: onRegenerateAvatar,
                            onArchive: onArchive,
                            onRestore: onRestore,
                            onDelete: onDelete,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _statsLine(PersonSummary summary) {
    if (!summary.hasTransactions) return 'No transactions yet';

    final countLabel = summary.transactionCount == 1
        ? '1 transaction'
        : '${summary.transactionCount} transactions';
    final lastDate = summary.lastTransactionDate;

    return lastDate == null
        ? countLabel
        : '$countLabel · ${FriendlyDate.format(lastDate)}';
  }
}

class _ArchivedBadge extends StatelessWidget {
  const _ArchivedBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Archived',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _PersonCardMenu extends StatelessWidget {
  const _PersonCardMenu({
    required this.isArchived,
    required this.onEdit,
    required this.onRegenerateAvatar,
    required this.onArchive,
    required this.onRestore,
    required this.onDelete,
  });

  final bool isArchived;
  final VoidCallback onEdit;
  final VoidCallback onRegenerateAvatar;
  final VoidCallback onArchive;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_PersonCardAction>(
      tooltip: 'More options',
      icon: const Icon(Icons.more_vert),
      onSelected: (action) {
        switch (action) {
          case _PersonCardAction.edit:
            onEdit();
          case _PersonCardAction.regenerateAvatar:
            onRegenerateAvatar();
          case _PersonCardAction.archive:
            onArchive();
          case _PersonCardAction.restore:
            onRestore();
          case _PersonCardAction.delete:
            onDelete();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _PersonCardAction.edit,
          child: ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('Edit'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: _PersonCardAction.regenerateAvatar,
          child: ListTile(
            leading: Icon(Icons.auto_awesome_outlined),
            title: Text('New avatar color'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (!isArchived)
          const PopupMenuItem(
            value: _PersonCardAction.archive,
            child: ListTile(
              leading: Icon(Icons.archive_outlined),
              title: Text('Archive'),
              contentPadding: EdgeInsets.zero,
            ),
          )
        else
          const PopupMenuItem(
            value: _PersonCardAction.restore,
            child: ListTile(
              leading: Icon(Icons.unarchive_outlined),
              title: Text('Restore'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        const PopupMenuItem(
          value: _PersonCardAction.delete,
          child: ListTile(
            leading: Icon(Icons.delete_outline),
            title: Text('Delete'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

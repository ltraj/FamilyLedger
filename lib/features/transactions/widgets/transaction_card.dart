import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/core/utils/balance_calculator.dart';
import 'package:family_ledger/core/utils/balance_colors.dart';
import 'package:family_ledger/core/utils/currency_formatter.dart';
import 'package:family_ledger/core/utils/friendly_date.dart';
import 'package:family_ledger/features/transactions/models/transaction_type_label.dart';
import 'package:family_ledger/models/category_model.dart';
import 'package:family_ledger/projections/transaction_details.dart';
import 'package:flutter/material.dart';

/// A single transaction's compact card in the timeline: type, category,
/// signed amount, running balance, remark, date/time, and an attachment
/// indicator for when attachments are supported.
class TransactionCard extends StatelessWidget {
  const TransactionCard({
    super.key,
    required this.details,
    required this.onTap,
    required this.onDelete,
  });

  final TransactionDetails details;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transaction = details.transaction;
    final signedAmount = BalanceCalculator.signedAmount(transaction);
    final remark = transaction.remark;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _TypeChip(type: transaction.transactionType),
                        if (details.category != null)
                          _CategoryChip(category: details.category!),
                      ],
                    ),
                  ),
                  if (transaction.attachmentPath != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.attach_file,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: 'Delete',
                    visualDensity: VisualDensity.compact,
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 8, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _signedAmountLabel(signedAmount),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: BalanceColors.forBalance(
                                context,
                                hasTransactions: true,
                                balance: signedAmount,
                              ),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (remark != null && remark.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              remark,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Balance ${CurrencyFormatter.format(details.runningBalanceAfter)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _dateTimeLabel(transaction.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
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
    );
  }

  String _signedAmountLabel(double signedAmount) {
    final formatted = CurrencyFormatter.format(signedAmount);
    return signedAmount >= 0 ? '+$formatted' : formatted;
  }

  String _dateTimeLabel(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${FriendlyDate.format(date)} · $hour:$minute';
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final TransactionType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final CategoryModel category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _parseCategoryColor(category.color) ?? theme.colorScheme.surfaceContainerHighest;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category.name,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Color? _parseCategoryColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final withAlpha = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
    final value = int.tryParse(withAlpha, radix: 16);
    return value == null ? null : Color(value);
  }
}

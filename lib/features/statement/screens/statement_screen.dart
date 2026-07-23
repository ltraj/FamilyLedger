import 'package:family_ledger/core/utils/balance_colors.dart';
import 'package:family_ledger/core/utils/currency_formatter.dart';
import 'package:family_ledger/core/utils/friendly_date.dart';
import 'package:family_ledger/features/settings/providers/settings_view_model.dart';
import 'package:family_ledger/features/statement/providers/statement_period_controller.dart';
import 'package:family_ledger/features/statement/providers/statement_view_model.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/projections/statement/person_statement.dart';
import 'package:family_ledger/projections/statement/statement_line_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A short, jargon-free monthly summary of one person's ledger activity —
/// meant to read in a few seconds or be screenshotted and sent to them
/// directly, unlike the Transaction screen's card list.
class StatementScreen extends ConsumerWidget {
  const StatementScreen({super.key, required this.person});

  final PersonModel person;

  int get _personId => person.id!;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(statementPeriodProvider(_personId));
    final statementAsync = ref.watch(statementViewModelProvider(_personId));
    final controller = ref.read(statementPeriodProvider(_personId).notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Statement')),
      body: Column(
        children: [
          _PeriodSelector(
            label: period.label,
            onPrevious: controller.previousMonth,
            onNext: controller.nextMonth,
          ),
          Expanded(
            child: statementAsync.when(
              data: (statement) => _StatementBody(statement: statement),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Could not load this statement: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous month',
            onPressed: onPrevious,
          ),
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next month',
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _StatementBody extends ConsumerWidget {
  const _StatementBody({required this.statement});

  final PersonStatement statement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasActivity =
        statement.gaveLine != null || statement.spentLine != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${statement.person.name} — ${statement.periodLabel}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (!hasActivity)
                  Text(
                    'Nothing to report this month.',
                    style: theme.textTheme.bodyLarge,
                  )
                else ...[
                  if (statement.gaveLine != null)
                    Text(statement.gaveLine!, style: theme.textTheme.bodyLarge),
                  if (statement.spentLine != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      statement.spentLine!,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ],
                const SizedBox(height: 6),
                Text(
                  statement.balanceLine,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _balanceColor(context, statement.balanceStatus),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (statement.items.isNotEmpty) ...[
          const SizedBox(height: 12),
          _DetailsSection(items: statement.items),
        ],
      ],
    );
  }

  Color _balanceColor(BuildContext context, BalanceStatus status) {
    return switch (status) {
      BalanceStatus.positive => BalanceColors.positive,
      BalanceStatus.negative => BalanceColors.negative,
      BalanceStatus.settled => Theme.of(context).colorScheme.onSurfaceVariant,
    };
  }
}

class _DetailsSection extends ConsumerWidget {
  const _DetailsSection({required this.items});

  final List<StatementLineItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: const Text('Show details'),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: [
            for (final item in items) _DetailRow(item: item),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends ConsumerWidget {
  const _DetailRow({required this.item});

  final StatementLineItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final isGiven = item.direction == StatementDirection.given;
    final remark = item.remark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  FriendlyDate.format(item.date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Text(item.description, style: theme.textTheme.bodyMedium),
              ),
              Text(
                CurrencyFormatter.format(item.amount, symbol: currencySymbol),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isGiven ? BalanceColors.positive : BalanceColors.negative,
                ),
              ),
            ],
          ),
          if (remark != null)
            Padding(
              padding: const EdgeInsets.only(left: 72, top: 2),
              child: Text(
                remark,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

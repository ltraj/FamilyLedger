import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/features/transactions/models/transaction_date_range.dart';
import 'package:family_ledger/features/transactions/models/transaction_sort_option.dart';
import 'package:family_ledger/features/transactions/models/transaction_type_label.dart';
import 'package:family_ledger/features/transactions/providers/transaction_query_controller.dart';
import 'package:family_ledger/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the combined sort + filter bottom sheet for one person's
/// Transaction screen.
Future<void> showTransactionSortFilterSheet(
  BuildContext context,
  int personId,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => _SortFilterSheet(personId: personId),
  );
}

class _SortFilterSheet extends ConsumerWidget {
  const _SortFilterSheet({required this.personId});

  final int personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final query = ref.watch(transactionQueryProvider(personId));
    final controller = ref.read(transactionQueryProvider(personId).notifier);
    final categoriesAsync = ref.watch(categoriesListProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sort & Filter', style: theme.textTheme.titleMedium),
                if (query.hasActiveFilter)
                  TextButton(
                    onPressed: controller.clearFilters,
                    child: const Text('Clear filters'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Sort by', style: theme.textTheme.labelLarge),
            RadioGroup<TransactionSortOption>(
              groupValue: query.sort,
              onChanged: (value) {
                if (value != null) controller.setSort(value);
              },
              child: Column(
                children: [
                  for (final option in TransactionSortOption.values)
                    RadioListTile<TransactionSortOption>(
                      value: option,
                      title: Text(option.label),
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('Type', style: theme.textTheme.labelLarge),
            RadioGroup<TransactionType?>(
              groupValue: query.typeFilter,
              onChanged: controller.setTypeFilter,
              child: Column(
                children: [
                  const RadioListTile<TransactionType?>(
                    value: null,
                    title: Text('All'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  for (final type in TransactionType.values)
                    RadioListTile<TransactionType?>(
                      value: type,
                      title: Text(type.label),
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('Category', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            categoriesAsync.when(
              data: (categories) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: query.categoryFilter == null,
                    onSelected: (_) => controller.setCategoryFilter(null),
                  ),
                  for (final category in categories)
                    if (category.id != null)
                      ChoiceChip(
                        label: Text(category.name),
                        selected: query.categoryFilter == category.id,
                        onSelected: (_) =>
                            controller.setCategoryFilter(category.id),
                      ),
                ],
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            Text('Date range', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDateRange(context, controller, query),
                    icon: const Icon(Icons.date_range_outlined, size: 18),
                    label: Text(_dateRangeLabel(query.dateRange)),
                  ),
                ),
                if (query.dateRange != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Clear date range',
                    icon: const Icon(Icons.close),
                    onPressed: () => controller.setDateRange(null),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateRangeLabel(TransactionDateRange? range) {
    if (range == null) return 'Select date range';
    String format(DateTime date) =>
        '${date.day}/${date.month}/${date.year}';
    return '${format(range.start)} – ${format(range.end)}';
  }

  Future<void> _pickDateRange(
    BuildContext context,
    TransactionQueryController controller,
    TransactionQuery query,
  ) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: query.dateRange == null
          ? null
          : DateTimeRange(start: query.dateRange!.start, end: query.dateRange!.end),
      currentDate: now,
    );
    if (picked == null) return;
    controller.setDateRange(
      TransactionDateRange(start: picked.start, end: picked.end),
    );
  }
}

import 'package:family_ledger/features/people/models/person_filter_option.dart';
import 'package:family_ledger/features/people/models/person_sort_option.dart';
import 'package:family_ledger/features/people/providers/people_query_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens a bottom sheet listing every `PersonSortOption`, updating
/// `peopleQueryProvider` when one is picked.
Future<void> showPersonSortSheet(BuildContext context, WidgetRef ref) {
  final current = ref.read(peopleQueryProvider).sort;

  return showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => _OptionSheet<PersonSortOption>(
      title: 'Sort by',
      options: PersonSortOption.values,
      current: current,
      labelOf: (option) => option.label,
      onSelected: (option) {
        ref.read(peopleQueryProvider.notifier).setSort(option);
        Navigator.of(sheetContext).pop();
      },
    ),
  );
}

/// Opens a bottom sheet listing every `PersonFilterOption`, updating
/// `peopleQueryProvider` when one is picked.
Future<void> showPersonFilterSheet(BuildContext context, WidgetRef ref) {
  final current = ref.read(peopleQueryProvider).filter;

  return showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => _OptionSheet<PersonFilterOption>(
      title: 'Filter',
      options: PersonFilterOption.values,
      current: current,
      labelOf: (option) => option.label,
      onSelected: (option) {
        ref.read(peopleQueryProvider.notifier).setFilter(option);
        Navigator.of(sheetContext).pop();
      },
    ),
  );
}

class _OptionSheet<T> extends StatelessWidget {
  const _OptionSheet({
    required this.title,
    required this.options,
    required this.current,
    required this.labelOf,
    required this.onSelected,
  });

  final String title;
  final List<T> options;
  final T current;
  final String Function(T option) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          RadioGroup<T>(
            groupValue: current,
            onChanged: (value) {
              if (value != null) onSelected(value);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in options)
                  RadioListTile<T>(value: option, title: Text(labelOf(option))),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

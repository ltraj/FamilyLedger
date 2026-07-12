import 'dart:async';

import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/features/people/providers/people_view_model.dart';
import 'package:family_ledger/features/reports/models/report_date_preset.dart';
import 'package:family_ledger/features/reports/providers/report_filter_controller.dart';
import 'package:family_ledger/features/transactions/models/transaction_date_range.dart';
import 'package:family_ledger/features/transactions/models/transaction_type_label.dart';
import 'package:family_ledger/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Reports screen's global filter bar: search field plus a
/// horizontally scrollable row of filter chips (date preset, person,
/// category, transaction type, clear-all).
///
/// Pinned above the sections via [ReportFilterBarDelegate] so it stays
/// visible while scrolling. Pure selection UI — it only reads option
/// lists and writes to `reportFilterProvider`; every recalculation
/// happens downstream in `ReportsViewModel`.
class ReportFilterBar extends ConsumerStatefulWidget {
  const ReportFilterBar({super.key});

  /// Total height the persistent header reserves.
  static const double height = 108;

  @override
  ConsumerState<ReportFilterBar> createState() => _ReportFilterBarState();
}

class _ReportFilterBarState extends ConsumerState<ReportFilterBar> {
  late final TextEditingController _searchController;
  Timer? _searchDebounce;

  /// Every search keystroke triggers a full `ReportEngine` pass over all
  /// transactions, so raw per-character updates would run the engine
  /// several times per typed word on a large ledger. This delay batches a
  /// burst of typing into one recomputation.
  static const Duration searchDebounce = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    // Seed from the provider so the remembered search text survives
    // leaving and re-entering the Reports tab.
    _searchController = TextEditingController(
      text: ref.read(reportFilterProvider).searchText,
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(searchDebounce, () {
      ref.read(reportFilterProvider.notifier).setSearchText(text);
    });
  }

  /// Clearing is a deliberate single action, not a typing burst — apply
  /// it immediately (and drop any pending debounced update, which would
  /// otherwise resurrect the old query after the clear).
  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    ref.read(reportFilterProvider.notifier).setSearchText('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = ref.watch(reportFilterProvider);
    final controller = ref.read(reportFilterProvider.notifier);

    final peopleAsync = ref.watch(peopleViewModelProvider);
    final categoriesAsync = ref.watch(categoriesListProvider);

    final people = [
      for (final summary in peopleAsync.valueOrNull ?? const [])
        summary.person,
    ];
    final categories = categoriesAsync.valueOrNull ?? const [];

    final selectedPersonName = filter.personId == null
        ? null
        : people
              .where((person) => person.id == filter.personId)
              .map((person) => person.name)
              .firstOrNull;
    final selectedCategoryName = filter.categoryId == null
        ? null
        : categories
              .where((category) => category.id == filter.categoryId)
              .map((category) => category.name)
              .firstOrNull;

    return Material(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search person, category, or remark',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: filter.searchText.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          tooltip: 'Clear search',
                          onPressed: _clearSearch,
                        ),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _MenuFilterChip<ReportDatePreset>(
                    icon: Icons.calendar_today_outlined,
                    label: filter.datePreset == ReportDatePreset.allTime
                        ? 'All Time'
                        : filter.datePreset.label,
                    isActive: filter.datePreset != ReportDatePreset.allTime,
                    options: [
                      for (final preset in ReportDatePreset.values)
                        (value: preset, label: preset.label),
                    ],
                    onSelected: (preset) async {
                      if (preset == ReportDatePreset.custom) {
                        await _pickCustomRange(controller);
                      } else {
                        controller.setPreset(preset);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _MenuFilterChip<int?>(
                    icon: Icons.person_outline,
                    label: selectedPersonName ?? 'Person',
                    isActive: filter.personId != null,
                    options: [
                      (value: null, label: 'All people'),
                      for (final person in people)
                        (value: person.id, label: person.name),
                    ],
                    onSelected: controller.setPerson,
                  ),
                  const SizedBox(width: 8),
                  _MenuFilterChip<int?>(
                    icon: Icons.category_outlined,
                    label: selectedCategoryName ?? 'Category',
                    isActive: filter.categoryId != null,
                    options: [
                      (value: null, label: 'All categories'),
                      for (final category in categories)
                        (value: category.id, label: category.name),
                    ],
                    onSelected: controller.setCategory,
                  ),
                  const SizedBox(width: 8),
                  _MenuFilterChip<TransactionType?>(
                    icon: Icons.swap_vert,
                    label: filter.transactionType?.label ?? 'Type',
                    isActive: filter.transactionType != null,
                    options: [
                      (value: null, label: 'All types'),
                      for (final type in TransactionType.values)
                        (value: type, label: type.label),
                    ],
                    onSelected: controller.setTransactionType,
                  ),
                  if (filter.hasActiveFilters) ...[
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Icon(Icons.filter_alt_off_outlined, size: 16),
                      label: const Text('Clear'),
                      onPressed: () {
                        _searchDebounce?.cancel();
                        _searchController.clear();
                        controller.clearAll();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomRange(ReportFilterController controller) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked == null) return;

    controller.setCustomRange(
      TransactionDateRange(start: picked.start, end: picked.end),
    );
  }
}

class _MenuFilterChip<T> extends StatelessWidget {
  const _MenuFilterChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.options,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final List<({T value, String label})> options;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<({T value, String label})>(
      tooltip: label,
      onSelected: (option) => onSelected(option.value),
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem(value: option, child: Text(option.label)),
      ],
      child: Chip(
        avatar: Icon(
          icon,
          size: 16,
          color: isActive
              ? theme.colorScheme.onSecondaryContainer
              : theme.colorScheme.onSurfaceVariant,
        ),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: isActive
            ? theme.colorScheme.secondaryContainer
            : null,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/// Pins [ReportFilterBar] to the top of the Reports scroll view.
class ReportFilterBarDelegate extends SliverPersistentHeaderDelegate {
  const ReportFilterBarDelegate();

  @override
  double get minExtent => ReportFilterBar.height;

  @override
  double get maxExtent => ReportFilterBar.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return const ReportFilterBar();
  }

  @override
  bool shouldRebuild(covariant ReportFilterBarDelegate oldDelegate) => false;
}

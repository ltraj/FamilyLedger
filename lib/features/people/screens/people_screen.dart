import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/features/people/models/people_exceptions.dart';
import 'package:family_ledger/features/people/models/person_filter_option.dart';
import 'package:family_ledger/features/people/providers/filtered_people_provider.dart';
import 'package:family_ledger/features/people/providers/people_query_controller.dart';
import 'package:family_ledger/features/people/providers/people_view_model.dart';
import 'package:family_ledger/features/people/widgets/add_edit_person_dialog.dart';
import 'package:family_ledger/features/people/widgets/person_card.dart';
import 'package:family_ledger/features/people/widgets/person_empty_state.dart';
import 'package:family_ledger/features/people/widgets/person_section.dart';
import 'package:family_ledger/features/people/widgets/person_sort_filter_sheet.dart';
import 'package:family_ledger/features/transactions/screens/transaction_screen.dart';
import 'package:family_ledger/projections/person_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _OverflowAction { sort, filter }

/// Top-level People screen: search, sort/filter, two expandable sections
/// (Permanent / Temporary), and a FAB to add a new person.
class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearching() => setState(() => _isSearching = true);

  void _stopSearching() {
    setState(() => _isSearching = false);
    _searchController.clear();
    ref.read(peopleQueryProvider.notifier).setSearchText('');
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(peopleQueryProvider);
    final peopleAsync = ref.watch(filteredPeopleProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Search people',
                  border: InputBorder.none,
                ),
                onChanged: (value) =>
                    ref.read(peopleQueryProvider.notifier).setSearchText(value),
              )
            : const Text('People'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? 'Close search' : 'Search',
            onPressed: _isSearching ? _stopSearching : _startSearching,
          ),
          PopupMenuButton<_OverflowAction>(
            tooltip: 'More options',
            onSelected: (action) {
              switch (action) {
                case _OverflowAction.sort:
                  showPersonSortSheet(context, ref);
                case _OverflowAction.filter:
                  showPersonFilterSheet(context, ref);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _OverflowAction.sort,
                child: ListTile(
                  leading: Icon(Icons.sort),
                  title: Text('Sort'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _OverflowAction.filter,
                child: ListTile(
                  leading: Icon(Icons.filter_list),
                  title: Text('Filter'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.sort, size: 18),
                  label: Text(query.sort.label),
                  onPressed: () => showPersonSortSheet(context, ref),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.filter_list, size: 18),
                  label: Text(query.filter.label),
                  onPressed: () => showPersonFilterSheet(context, ref),
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: peopleAsync.when(
                data: (summaries) => _PeopleList(
                  key: const ValueKey('data'),
                  summaries: summaries,
                  filter: query.filter,
                ),
                loading: () => const Center(
                  key: ValueKey('loading'),
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => _ErrorState(
                  key: const ValueKey('error'),
                  onRetry: () => ref.invalidate(peopleViewModelProvider),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddEditPersonDialog.show(context),
        tooltip: 'Add person',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PeopleList extends ConsumerWidget {
  const _PeopleList({super.key, required this.summaries, required this.filter});

  final List<PersonSummary> summaries;
  final PersonFilterOption filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permanent = summaries
        .where((summary) => summary.person.type == PersonType.permanent)
        .toList();
    final temporary = summaries
        .where((summary) => summary.person.type == PersonType.temporary)
        .toList();

    final showPermanent = filter != PersonFilterOption.temporary;
    final showTemporary = filter != PersonFilterOption.permanent;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        if (showPermanent)
          PersonSection(
            title: 'Permanent People',
            summaries: permanent,
            cardBuilder: (context, summary) =>
                _buildCard(context, ref, summary),
            emptyState: PersonEmptyState(
              message: 'No permanent people',
              icon: Icons.home_outlined,
              onCreatePerson: () => AddEditPersonDialog.show(context),
            ),
          ),
        if (showPermanent && showTemporary) const SizedBox(height: 16),
        if (showTemporary)
          PersonSection(
            title: 'Temporary People',
            summaries: temporary,
            cardBuilder: (context, summary) =>
                _buildCard(context, ref, summary),
            emptyState: PersonEmptyState(
              message: 'No temporary people',
              onCreatePerson: () => AddEditPersonDialog.show(context),
            ),
          ),
      ],
    );
  }

  Widget _buildCard(
    BuildContext context,
    WidgetRef ref,
    PersonSummary summary,
  ) {
    return PersonCard(
      summary: summary,
      onOpenTransactions: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => TransactionScreen(person: summary.person),
        ),
      ),
      onEdit: () =>
          AddEditPersonDialog.show(context, initialPerson: summary.person),
      onRegenerateAvatar: () => ref
          .read(peopleViewModelProvider.notifier)
          .regenerateAvatarColor(summary.person),
      onArchive: () => ref
          .read(peopleViewModelProvider.notifier)
          .archivePerson(summary.person.id!),
      onRestore: () => ref
          .read(peopleViewModelProvider.notifier)
          .unarchivePerson(summary.person.id!),
      onDelete: () => _handleDelete(context, ref, summary),
    );
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    PersonSummary summary,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete person?'),
        content: Text(
          'This permanently deletes ${summary.person.name}. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(peopleViewModelProvider.notifier)
          .deletePerson(summary.person.id!);
    } on PersonHasTransactionsException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong loading people.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

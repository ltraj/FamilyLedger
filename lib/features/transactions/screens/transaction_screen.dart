import 'package:family_ledger/features/shared/widgets/empty_state_view.dart';
import 'package:family_ledger/features/statement/screens/statement_screen.dart';
import 'package:family_ledger/features/transactions/providers/filtered_transactions_provider.dart';
import 'package:family_ledger/features/transactions/providers/transaction_query_controller.dart';
import 'package:family_ledger/features/transactions/providers/transactions_view_model.dart';
import 'package:family_ledger/features/transactions/widgets/add_edit_transaction_sheet.dart';
import 'package:family_ledger/features/transactions/widgets/person_balance_header.dart';
import 'package:family_ledger/features/transactions/widgets/transaction_card.dart';
import 'package:family_ledger/features/transactions/widgets/transaction_sort_filter_sheet.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/projections/transaction_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One person's Transaction screen: balance header, searchable/filterable/
/// sortable running-balance timeline, and a FAB to add a new transaction.
///
/// Takes the [PersonModel] directly (from wherever the caller already had
/// it, typically the People screen) rather than re-fetching it by id:
/// this screen never mutates people, so a snapshot is enough, and it also
/// means the header has something to show even before any transaction has
/// been added.
class TransactionScreen extends ConsumerStatefulWidget {
  const TransactionScreen({super.key, required this.person});

  final PersonModel person;

  @override
  ConsumerState<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends ConsumerState<TransactionScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  int get _personId => widget.person.id!;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearching() => setState(() => _isSearching = true);

  void _stopSearching() {
    setState(() => _isSearching = false);
    _searchController.clear();
    ref.read(transactionQueryProvider(_personId).notifier).setSearchText('');
  }

  @override
  Widget build(BuildContext context) {
    final unfilteredAsync = ref.watch(transactionsViewModelProvider(_personId));
    final filteredAsync = ref.watch(filteredTransactionsProvider(_personId));
    final query = ref.watch(transactionQueryProvider(_personId));

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Search transactions',
                  border: InputBorder.none,
                ),
                onChanged: (value) => ref
                    .read(transactionQueryProvider(_personId).notifier)
                    .setSearchText(value),
              )
            : Text(widget.person.name),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? 'Close search' : 'Search',
            onPressed: _isSearching ? _stopSearching : _startSearching,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Sort & filter',
            onPressed: () => showTransactionSortFilterSheet(context, _personId),
          ),
          IconButton(
            icon: const Icon(Icons.summarize_outlined),
            tooltip: 'Statement',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => StatementScreen(person: widget.person),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _Header(person: widget.person, unfilteredAsync: unfilteredAsync),
          if (query.hasActiveFilter || query.searchText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ActionChip(
                  avatar: const Icon(Icons.filter_list, size: 18),
                  label: const Text('Filters active'),
                  onPressed: () =>
                      showTransactionSortFilterSheet(context, _personId),
                ),
              ),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: filteredAsync.when(
                data: (details) => _TransactionList(
                  key: const ValueKey('data'),
                  details: details,
                  hasAnyTransactions:
                      unfilteredAsync.valueOrNull?.isNotEmpty ?? false,
                  personId: _personId,
                ),
                loading: () => const Center(
                  key: ValueKey('loading'),
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  key: const ValueKey('error'),
                  child: Text(
                    'Something went wrong loading transactions.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            AddEditTransactionSheet.show(context, personId: _personId),
        tooltip: 'Add transaction',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.person, required this.unfilteredAsync});

  final PersonModel person;
  final AsyncValue<List<TransactionDetails>> unfilteredAsync;

  @override
  Widget build(BuildContext context) {
    final details = unfilteredAsync.valueOrNull ?? const <TransactionDetails>[];
    final balance = details.isEmpty ? 0.0 : details.first.runningBalanceAfter;
    final lastDate = details.isEmpty ? null : details.first.transaction.date;

    return PersonBalanceHeader(
      person: person,
      balance: balance,
      transactionCount: details.length,
      lastTransactionDate: lastDate,
    );
  }
}

class _TransactionList extends ConsumerWidget {
  const _TransactionList({
    super.key,
    required this.details,
    required this.hasAnyTransactions,
    required this.personId,
  });

  final List<TransactionDetails> details;
  final bool hasAnyTransactions;
  final int personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (details.isEmpty) {
      return Center(
        child: EmptyStateView(
          message: hasAnyTransactions
              ? 'No transactions match your search or filters.'
              : 'No transactions yet',
          buttonLabel: 'Create First Transaction',
          icon: Icons.receipt_long_outlined,
          onPressed: () =>
              AddEditTransactionSheet.show(context, personId: personId),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: details.length,
      itemBuilder: (context, index) {
        final entry = details[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TransactionCard(
            details: entry,
            onTap: () => AddEditTransactionSheet.show(
              context,
              personId: personId,
              initialTransaction: entry.transaction,
            ),
            onDelete: () => _confirmAndDelete(context, ref, entry),
          ),
        );
      },
    );
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    TransactionDetails entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text(
          'This permanently deletes this transaction and recalculates '
          'balances. This cannot be undone.',
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

    await ref
        .read(transactionsViewModelProvider(personId).notifier)
        .deleteTransaction(entry.transaction.id!);
  }
}

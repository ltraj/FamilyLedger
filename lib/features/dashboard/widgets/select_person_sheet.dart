import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/core/utils/currency_formatter.dart';
import 'package:family_ledger/features/people/providers/people_view_model.dart';
import 'package:family_ledger/features/people/widgets/person_avatar.dart';
import 'package:family_ledger/features/settings/providers/settings_view_model.dart';
import 'package:family_ledger/features/transactions/widgets/add_edit_transaction_sheet.dart';
import 'package:family_ledger/projections/person_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Dashboard's "Add Transaction" quick action: pick a person, then
/// immediately open the add-transaction sheet for them.
///
/// Reads whichever people data is already loaded (the Dashboard can only
/// be showing this action if `peopleViewModelProvider` has already
/// resolved), rather than awaiting a fresh fetch — there's nothing to
/// wait for.
Future<void> showSelectPersonThenAddTransaction(
  BuildContext context,
  WidgetRef ref,
) async {
  final activePeople = (ref.read(peopleViewModelProvider).valueOrNull ?? const [])
      .where((summary) => summary.person.status == PersonStatus.active)
      .toList();

  if (activePeople.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Add a person first.')));
    return;
  }

  final selectedPersonId = await showModalBottomSheet<int>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => _SelectPersonSheet(people: activePeople),
  );

  if (selectedPersonId == null) return;
  if (!context.mounted) return;
  await AddEditTransactionSheet.show(context, personId: selectedPersonId);
}

class _SelectPersonSheet extends ConsumerWidget {
  const _SelectPersonSheet({required this.people});

  final List<PersonSummary> people;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Select Person', style: theme.textTheme.titleMedium),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: people.length,
              itemBuilder: (context, index) {
                final summary = people[index];
                return ListTile(
                  leading: PersonAvatar(person: summary.person, radius: 18),
                  title: Text(summary.person.name),
                  subtitle: Text(
                    CurrencyFormatter.format(
                      summary.balance,
                      symbol: currencySymbol,
                    ),
                  ),
                  onTap: () => Navigator.of(context).pop(summary.person.id),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

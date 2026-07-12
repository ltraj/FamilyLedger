import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/features/transactions/screens/transaction_screen.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/models/transaction_model.dart';
import 'package:family_ledger/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';
import '../../helpers/test_repositories.dart';
import '../../helpers/widget_test_utils.dart';

/// Widget-level tests that render the real `TransactionScreen` against a
/// real (in-memory) database, the same approach used for
/// `people_screen_test.dart`.
void main() {
  late TestRepositories repos;
  late PersonModel nani;

  setUp(() async {
    repos = TestRepositories(await createTestDatabase());
    final people = await repos.people.getAll();
    nani = people.firstWhere((p) => p.name == 'Nani');
  });

  tearDown(() => repos.close());

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        peopleRepositoryProvider.overrideWithValue(repos.people),
        transactionRepositoryProvider.overrideWithValue(repos.transactions),
        categoryRepositoryProvider.overrideWithValue(repos.categories),
      ],
      child: MaterialApp(home: TransactionScreen(person: nani)),
    );
  }

  Future<void> insertTransaction({
    required double amount,
    required TransactionType type,
    String? remark,
    required DateTime date,
  }) {
    return repos.transactions.insert(
      TransactionModel(
        personId: nani.id!,
        amount: amount,
        transactionType: type,
        remark: remark,
        date: date,
        createdAt: date,
        updatedAt: date,
      ),
    );
  }

  testWidgets('shows the empty state when the person has no transactions', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('No transactions yet'), findsOneWidget);
    expect(find.text('Create First Transaction'), findsOneWidget);

    await disposeReactiveWidgetTree(tester);
  });

  testWidgets(
    'adding a transaction shows it with the correct running balance',
    (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add transaction'));
      await tester.pumpAndSettle();

      expect(find.text('Add Transaction'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, '5000');
      // Default type is Expense Paid; switch to Advance Received so the
      // signed amount is positive, matching the spec's example.
      await tester.tap(find.byType(DropdownMenu<TransactionType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Advance Received').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Add Transaction'), findsNothing);
      // Header (unsigned) and card (signed) render distinct strings.
      expect(find.text('₹5,000.00'), findsOneWidget);
      expect(find.text('+₹5,000.00'), findsOneWidget);

      await disposeReactiveWidgetTree(tester);
    },
  );

  testWidgets(
    'editing a transaction updates its amount and the running balance',
    (tester) async {
      await insertTransaction(
        amount: 5000,
        type: TransactionType.advanceReceived,
        date: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('+₹5,000.00'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Transaction'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, '3000');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('₹3,000.00'), findsOneWidget);
      expect(find.text('+₹3,000.00'), findsOneWidget);

      await disposeReactiveWidgetTree(tester);
    },
  );

  testWidgets(
    'deleting a transaction requires confirmation and then removes it',
    (tester) async {
      await insertTransaction(
        amount: 5000,
        type: TransactionType.advanceReceived,
        date: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete transaction?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('No transactions yet'), findsOneWidget);

      await disposeReactiveWidgetTree(tester);
    },
  );

  testWidgets('running balance accumulates across multiple transactions', (
    tester,
  ) async {
    await insertTransaction(
      amount: 5000,
      type: TransactionType.advanceReceived,
      date: DateTime(2026, 1, 1),
    );
    await insertTransaction(
      amount: 850,
      type: TransactionType.expensePaid,
      date: DateTime(2026, 1, 2),
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Balance ₹5,000.00'), findsOneWidget);
    expect(find.textContaining('Balance ₹4,150.00'), findsOneWidget);
    // Header shows the current (latest) balance.
    expect(find.text('₹4,150.00'), findsOneWidget);

    await disposeReactiveWidgetTree(tester);
  });

  testWidgets('search filters the visible transactions by remark', (
    tester,
  ) async {
    await insertTransaction(
      amount: 850,
      type: TransactionType.expensePaid,
      remark: 'Router bill',
      date: DateTime(2026, 1, 1),
    );
    await insertTransaction(
      amount: 300,
      type: TransactionType.expensePaid,
      remark: 'Lunch',
      date: DateTime(2026, 1, 2),
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'router');
    await tester.pumpAndSettle();

    expect(find.text('Router bill'), findsOneWidget);
    expect(find.text('Lunch'), findsNothing);

    await disposeReactiveWidgetTree(tester);
  });

  testWidgets('filtering by type shows only matching transactions', (
    tester,
  ) async {
    await insertTransaction(
      amount: 5000,
      type: TransactionType.advanceReceived,
      date: DateTime(2026, 1, 1),
    );
    await insertTransaction(
      amount: 850,
      type: TransactionType.expensePaid,
      date: DateTime(2026, 1, 2),
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Sort & filter'));
    await tester.pumpAndSettle();

    // The screen's own transaction cards are still in the tree (just
    // covered by the modal), so target the filter sheet's radio option
    // specifically rather than any "Expense Paid" text on screen.
    await tester.tap(
      find.widgetWithText(RadioListTile<TransactionType?>, 'Expense Paid'),
    );
    await tester.pumpAndSettle();
    final doneButton = find.widgetWithText(FilledButton, 'Done');
    await tester.ensureVisible(doneButton);
    await tester.pumpAndSettle();
    await tester.tap(doneButton);
    await tester.pumpAndSettle();

    expect(find.text('+₹5,000.00'), findsNothing);
    expect(find.text('-₹850.00'), findsOneWidget);

    await disposeReactiveWidgetTree(tester);
  });
}

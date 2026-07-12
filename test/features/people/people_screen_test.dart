import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/features/people/screens/people_screen.dart';
import 'package:family_ledger/models/transaction_model.dart';
import 'package:family_ledger/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';
import '../../helpers/test_repositories.dart';
import '../../helpers/widget_test_utils.dart';

/// Widget-level tests that render the real `PeopleScreen` against a real
/// (in-memory) database, standing in for a manual run of the app: there is
/// no configured desktop/web platform or Android emulator in this
/// environment to take an actual screenshot with, so this drives the same
/// widget tree and provider wiring the app uses instead.
void main() {
  late TestRepositories repos;

  setUp(() async {
    repos = TestRepositories(await createTestDatabase());
  });

  tearDown(() => repos.close());

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        peopleRepositoryProvider.overrideWithValue(repos.people),
        transactionRepositoryProvider.overrideWithValue(repos.transactions),
      ],
      child: const MaterialApp(home: PeopleScreen()),
    );
  }

  testWidgets('shows seeded Nani and Sudha under Permanent People', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Permanent People'), findsOneWidget);
    expect(find.text('Nani'), findsOneWidget);
    expect(find.text('Sudha'), findsOneWidget);
    expect(find.text('Temporary People'), findsOneWidget);
    expect(find.text('No temporary people'), findsOneWidget);

    await disposeReactiveWidgetTree(tester);
  });

  testWidgets('adding a person through the FAB dialog shows them in the list', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add person'));
    await tester.pumpAndSettle();

    expect(find.text('Add Person'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Test Helper');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Add Person'), findsNothing); // dialog closed
    expect(find.text('Test Helper'), findsOneWidget);
    expect(find.text('No temporary people'), findsNothing);

    await disposeReactiveWidgetTree(tester);
  });

  testWidgets(
    'saving a duplicate name shows an inline error and keeps the dialog open',
    (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add person'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Nani');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Add Person'), findsOneWidget); // still open
      expect(find.textContaining('already exists'), findsOneWidget);

      await disposeReactiveWidgetTree(tester);
    },
  );

  testWidgets('search filters the visible people by name in real time', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'sud');
    await tester.pumpAndSettle();

    expect(find.text('Sudha'), findsOneWidget);
    expect(find.text('Nani'), findsNothing);

    await disposeReactiveWidgetTree(tester);
  });

  testWidgets(
    'reacts automatically when a transaction is inserted directly, with '
    'no UI action and no manual refresh',
    (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('₹750.00'), findsNothing);

      final people = await repos.people.getAll();
      final nani = people.firstWhere((p) => p.name == 'Nani');
      final now = DateTime(2026, 1, 1);

      // Inserted straight through the repository — never through this
      // screen's own dialogs or PeopleViewModel's mutation methods — to
      // prove the reactive architecture (transactionsStreamProvider)
      // updates the rendered balance on its own.
      await repos.transactions.insert(
        TransactionModel(
          personId: nani.id!,
          amount: 750,
          transactionType: TransactionType.advanceReceived,
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('₹750.00'), findsOneWidget);

      await disposeReactiveWidgetTree(tester);
    },
  );
}

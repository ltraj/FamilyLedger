import 'package:family_ledger/app/app_shell.dart';
import 'package:family_ledger/app/app_tab_controller.dart';
import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/features/dashboard/screens/dashboard_screen.dart';
import 'package:family_ledger/features/dashboard/widgets/person_overview_card.dart';
import 'package:family_ledger/features/dashboard/widgets/quick_action_button.dart';
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

void main() {
  late TestRepositories repos;
  late PersonModel nani;
  late PersonModel sudha;

  setUp(() async {
    repos = TestRepositories(await createTestDatabase());
    final people = await repos.people.getAll();
    nani = people.firstWhere((p) => p.name == 'Nani');
    sudha = people.firstWhere((p) => p.name == 'Sudha');
  });

  tearDown(() => repos.close());

  List<Override> overrides() => [
    peopleRepositoryProvider.overrideWithValue(repos.people),
    transactionRepositoryProvider.overrideWithValue(repos.transactions),
    categoryRepositoryProvider.overrideWithValue(repos.categories),
  ];

  Widget buildApp() {
    return ProviderScope(
      overrides: overrides(),
      child: const MaterialApp(home: DashboardScreen()),
    );
  }

  Widget buildShell() {
    return ProviderScope(
      overrides: overrides(),
      child: const MaterialApp(home: AppShell()),
    );
  }

  Future<void> insertTransaction({
    required int personId,
    required double amount,
    required TransactionType type,
    required DateTime date,
    String? remark,
  }) {
    return repos.transactions.insert(
      TransactionModel(
        personId: personId,
        amount: amount,
        transactionType: type,
        remark: remark,
        date: date,
        createdAt: date,
        updatedAt: date,
      ),
    );
  }

  testWidgets('shows a loading indicator before data resolves', (tester) async {
    useTallTestViewport(tester);
    addTearDown(() => resetTestViewport(tester));

    await tester.pumpWidget(buildApp());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    await disposeReactiveWidgetTree(tester);
  });

  testWidgets('shows the no-people empty state when no active people exist', (
    tester,
  ) async {
    useTallTestViewport(tester);
    addTearDown(() => resetTestViewport(tester));

    await repos.people.archive(nani.id!);
    await repos.people.archive(sudha.id!);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('No people yet.'), findsOneWidget);
    expect(find.text('Create First Person'), findsOneWidget);

    await disposeReactiveWidgetTree(tester);
  });

  testWidgets(
    'shows the no-transactions empty state when people exist but nobody '
    'has transactions',
    (tester) async {
      useTallTestViewport(tester);
      addTearDown(() => resetTestViewport(tester));

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('No transactions yet.'), findsOneWidget);
      expect(find.text('Create First Transaction'), findsOneWidget);

      await disposeReactiveWidgetTree(tester);
    },
  );

  testWidgets(
    'shows summary cards, people overview, and hides Needs Attention when '
    'nothing needs it',
    (tester) async {
      useTallTestViewport(tester);
      addTearDown(() => resetTestViewport(tester));

      final now = DateTime.now();
      await insertTransaction(
        personId: nani.id!,
        amount: 5000,
        type: TransactionType.advanceReceived,
        date: now,
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Advance Held'), findsOneWidget);
      expect(find.text('People Owe Me'), findsOneWidget);
      expect(find.text('Net Position'), findsOneWidget);
      expect(find.text('Active People'), findsOneWidget);
      expect(find.text("This Month's Expenses"), findsOneWidget);

      expect(find.text('People Overview'), findsOneWidget);
      expect(find.widgetWithText(PersonOverviewCard, 'Nani'), findsOneWidget);

      // Nobody has a negative or low balance yet.
      expect(find.text('Needs Attention'), findsNothing);

      await disposeReactiveWidgetTree(tester);
    },
  );

  testWidgets(
    'shows a Needs Attention card for a person with a negative balance',
    (tester) async {
      useTallTestViewport(tester);
      addTearDown(() => resetTestViewport(tester));

      final now = DateTime.now();
      await insertTransaction(
        personId: sudha.id!,
        amount: 800,
        type: TransactionType.expensePaid,
        date: now,
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Needs Attention'), findsOneWidget);
      expect(find.text('Owes ₹800.00'), findsOneWidget);

      await disposeReactiveWidgetTree(tester);
    },
  );

  testWidgets(
    'shows Recent Activity and Quick Insights once there is a transaction',
    (tester) async {
      useTallTestViewport(tester);
      addTearDown(() => resetTestViewport(tester));

      final now = DateTime.now();
      await insertTransaction(
        personId: nani.id!,
        amount: 5000,
        type: TransactionType.advanceReceived,
        date: now,
        remark: 'Monthly advance',
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('Nani · Advance Received'), findsOneWidget);

      expect(find.text('Quick Insights'), findsOneWidget);
      expect(find.text('Highest remaining advance'), findsOneWidget);

      await disposeReactiveWidgetTree(tester);
    },
  );

  testWidgets(
    'tapping a person in People Overview opens their Transaction screen',
    (tester) async {
      useTallTestViewport(tester);
      addTearDown(() => resetTestViewport(tester));

      final now = DateTime.now();
      await insertTransaction(
        personId: nani.id!,
        amount: 5000,
        type: TransactionType.advanceReceived,
        date: now,
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(PersonOverviewCard, 'Nani'));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionScreen), findsOneWidget);

      await disposeReactiveWidgetTree(tester);
    },
  );

  testWidgets('Add Person quick action opens the add-person dialog', (
    tester,
  ) async {
    useTallTestViewport(tester);
    addTearDown(() => resetTestViewport(tester));

    // Quick actions only show once the dashboard has data to show — with
    // no transactions yet, the focused "no transactions" empty state (and
    // its own single CTA) takes over instead.
    await insertTransaction(
      personId: nani.id!,
      amount: 5000,
      type: TransactionType.advanceReceived,
      date: DateTime.now(),
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Person'));
    await tester.pumpAndSettle();

    expect(find.text('Add Person'), findsNWidgets(2)); // button + dialog title

    await disposeReactiveWidgetTree(tester);
  });

  testWidgets(
    'Add Transaction quick action opens person selection then the sheet',
    (tester) async {
      useTallTestViewport(tester);
      addTearDown(() => resetTestViewport(tester));

      final now = DateTime.now();
      await insertTransaction(
        personId: nani.id!,
        amount: 5000,
        type: TransactionType.advanceReceived,
        date: now,
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Transaction'));
      await tester.pumpAndSettle();

      expect(find.text('Select Person'), findsOneWidget);

      // "Nani" also appears on the dashboard behind this sheet (People
      // Overview, Quick Insights); target the sheet's own picker row.
      await tester.tap(find.widgetWithText(ListTile, 'Nani'));
      await tester.pumpAndSettle();

      expect(find.text('Add Transaction'), findsNWidgets(2)); // button + sheet title

      await disposeReactiveWidgetTree(tester);
    },
  );

  testWidgets('Reports quick action switches to the Reports tab', (
    tester,
  ) async {
    useTallTestViewport(tester);
    addTearDown(() => resetTestViewport(tester));

    await insertTransaction(
      personId: nani.id!,
      amount: 5000,
      type: TransactionType.advanceReceived,
      date: DateTime.now(),
    );

    await tester.pumpWidget(buildShell());
    await tester.pumpAndSettle();

    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 0);

    // The quick action button, not the bottom navigation destination of
    // the same name.
    await tester.tap(find.widgetWithText(QuickActionButton, 'Reports'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
      AppTab.reports.index,
    );

    await disposeReactiveWidgetTree(tester);
  });

  testWidgets('People quick action switches the bottom navigation tab', (
    tester,
  ) async {
    useTallTestViewport(tester);
    addTearDown(() => resetTestViewport(tester));

    final now = DateTime.now();
    await insertTransaction(
      personId: nani.id!,
      amount: 5000,
      type: TransactionType.advanceReceived,
      date: now,
    );

    await tester.pumpWidget(buildShell());
    await tester.pumpAndSettle();

    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 0);

    // "People" also labels the bottom nav destination; target the quick
    // action button specifically.
    await tester.tap(find.widgetWithText(FilledButton, 'People'));
    await tester.pumpAndSettle();

    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 1);

    await disposeReactiveWidgetTree(tester);
  });

  testWidgets(
    'reacts automatically when a transaction is inserted directly, with '
    'no UI action and no manual refresh',
    (tester) async {
      useTallTestViewport(tester);
      addTearDown(() => resetTestViewport(tester));

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('No transactions yet.'), findsOneWidget);

      await insertTransaction(
        personId: nani.id!,
        amount: 5000,
        type: TransactionType.advanceReceived,
        date: DateTime.now(),
      );
      await tester.pumpAndSettle();

      expect(find.text('No transactions yet.'), findsNothing);
      expect(find.text('Advance Held'), findsOneWidget);

      await disposeReactiveWidgetTree(tester);
    },
  );
}

import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/features/reports/models/report_date_preset.dart';
import 'package:family_ledger/features/reports/providers/report_filter_controller.dart';
import 'package:family_ledger/features/reports/providers/report_section_controller.dart';
import 'package:family_ledger/features/reports/screens/person_report_screen.dart';
import 'package:family_ledger/features/reports/screens/reports_screen.dart';
import 'package:family_ledger/features/reports/widgets/person_analysis_section.dart';
import 'package:family_ledger/features/reports/widgets/report_skeleton.dart';
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

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        peopleRepositoryProvider.overrideWithValue(repos.people),
        transactionRepositoryProvider.overrideWithValue(repos.transactions),
        categoryRepositoryProvider.overrideWithValue(repos.categories),
      ],
      child: const MaterialApp(home: ReportsScreen()),
    );
  }

  Future<void> insertTransaction({
    required int personId,
    required double amount,
    required TransactionType type,
    int? categoryId,
    String? remark,
    required DateTime date,
  }) {
    return repos.transactions.insert(
      TransactionModel(
        personId: personId,
        amount: amount,
        transactionType: type,
        categoryId: categoryId,
        remark: remark,
        date: date,
        createdAt: date,
        updatedAt: date,
      ),
    );
  }

  Future<void> seedLedger() async {
    final categories = await repos.categories.getAll();
    final firstCategory = categories.first;

    await insertTransaction(
      personId: nani.id!,
      amount: 5000,
      type: TransactionType.advanceReceived,
      date: DateTime.now().subtract(const Duration(days: 40)),
    );
    await insertTransaction(
      personId: nani.id!,
      amount: 1200,
      type: TransactionType.expensePaid,
      categoryId: firstCategory.id,
      remark: 'Groceries run',
      date: DateTime.now().subtract(const Duration(days: 10)),
    );
    await insertTransaction(
      personId: sudha.id!,
      amount: 300,
      type: TransactionType.expensePaid,
      date: DateTime.now().subtract(const Duration(days: 2)),
    );
  }

  testWidgets('shows the loading skeleton before data resolves', (
    tester,
  ) async {
    useTallTestViewport(tester);
    addTearDown(() => resetTestViewport(tester));

    await tester.pumpWidget(buildApp());
    expect(find.byType(ReportSkeleton), findsOneWidget);

    await tester.pumpAndSettle();
    await disposeReactiveWidgetTree(tester);
  });

  testWidgets('shows the no-transactions empty state on an empty ledger', (
    tester,
  ) async {
    useTallTestViewport(tester);
    addTearDown(() => resetTestViewport(tester));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No transactions yet'),
      findsOneWidget,
    );

    await disposeReactiveWidgetTree(tester);
  });

  testWidgets('renders ledger figures and expandable sections with data', (
    tester,
  ) async {
    useTallTestViewport(tester);
    addTearDown(() => resetTestViewport(tester));

    await seedLedger();

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Ledger section starts expanded.
    expect(find.text('Current Balance'), findsOneWidget);
    expect(find.text('₹3,500.00'), findsWidgets); // 5000 - 1200 - 300
    expect(find.text('Total Advance Received'), findsOneWidget);
    expect(find.text('₹5,000.00'), findsWidgets);

    // Person Analysis starts collapsed; expanding reveals person cards.
    expect(find.byType(PersonAnalysisSection), findsNothing);
    await tester.tap(find.text('Person Analysis'));
    await tester.pumpAndSettle();
    expect(find.byType(PersonAnalysisSection), findsOneWidget);
    expect(find.text('Nani'), findsWidgets);

    // Quick Insights starts expanded and states calculated facts only.
    expect(find.textContaining('You are currently holding'), findsOneWidget);

    await disposeReactiveWidgetTree(tester);
  });

  testWidgets('changing a filter updates the reports instantly', (
    tester,
  ) async {
    useTallTestViewport(tester);
    addTearDown(() => resetTestViewport(tester));

    await seedLedger();

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('3 transactions in view'), findsOneWidget);

    // Filter to Sudha only via the person chip's popup menu.
    await tester.tap(find.text('Person'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sudha').last);
    await tester.pumpAndSettle();

    expect(find.text('1 transactions in view'), findsOneWidget);

    // Clear restores everything.
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('3 transactions in view'), findsOneWidget);

    await disposeReactiveWidgetTree(tester);
  });

  testWidgets('search filters by remark text', (tester) async {
    useTallTestViewport(tester);
    addTearDown(() => resetTestViewport(tester));

    await seedLedger();

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'groceries run');
    // Search is debounced; advance past the timer before settling.
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('1 transactions in view'), findsOneWidget);

    await disposeReactiveWidgetTree(tester);
  });

  testWidgets('filters that match nothing show the empty state with a way out',
      (tester) async {
    useTallTestViewport(tester);
    addTearDown(() => resetTestViewport(tester));

    await seedLedger();

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzz-no-match');
    // Search is debounced; advance past the timer before settling.
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('No transactions match your filters.'), findsOneWidget);

    await tester.tap(find.text('Clear Filters'));
    await tester.pumpAndSettle();
    expect(find.text('3 transactions in view'), findsOneWidget);

    await disposeReactiveWidgetTree(tester);
  });

  testWidgets(
    'reacts automatically when a transaction is inserted directly, with no '
    'UI action and no manual refresh',
    (tester) async {
      useTallTestViewport(tester);
      addTearDown(() => resetTestViewport(tester));

      await seedLedger();

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('3 transactions in view'), findsOneWidget);

      await insertTransaction(
        personId: sudha.id!,
        amount: 999,
        type: TransactionType.advanceReceived,
        date: DateTime.now(),
      );
      await tester.pumpAndSettle();

      expect(find.text('4 transactions in view'), findsOneWidget);

      await disposeReactiveWidgetTree(tester);
    },
  );

  testWidgets('remembers filters and expanded sections across tab visits', (
    tester,
  ) async {
    useTallTestViewport(tester);
    addTearDown(() => resetTestViewport(tester));

    await seedLedger();

    // Same container across both "visits" — mirrors the app's root
    // ProviderScope surviving tab switches.
    final container = ProviderContainer(
      overrides: [
        peopleRepositoryProvider.overrideWithValue(repos.people),
        transactionRepositoryProvider.overrideWithValue(repos.transactions),
        categoryRepositoryProvider.overrideWithValue(repos.categories),
      ],
    );
    addTearDown(container.dispose);

    Widget appWith(Widget home) => UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: home),
    );

    await tester.pumpWidget(appWith(const ReportsScreen()));
    await tester.pumpAndSettle();

    container
        .read(reportFilterProvider.notifier)
        .setPreset(ReportDatePreset.last7Days);
    container
        .read(expandedReportSectionsProvider.notifier)
        .toggle(ReportSection.monthly);
    await tester.pumpAndSettle();

    // Only the 2-days-ago transaction falls within the last 7 days.
    expect(find.text('1 transactions in view'), findsOneWidget);

    // Leave the Reports screen entirely, then come back.
    await tester.pumpWidget(appWith(const SizedBox()));
    await tester.pumpAndSettle();
    await tester.pumpWidget(appWith(const ReportsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('1 transactions in view'), findsOneWidget);
    expect(find.text('Last 7 Days'), findsOneWidget);
    expect(
      container.read(expandedReportSectionsProvider),
      contains(ReportSection.monthly),
    );

    await disposeReactiveWidgetTree(tester);
  });

  testWidgets('tapping a person card opens the person report screen', (
    tester,
  ) async {
    useTallTestViewport(tester);
    addTearDown(() => resetTestViewport(tester));

    await seedLedger();

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Person Analysis'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sudha'));
    await tester.pumpAndSettle();

    expect(find.byType(PersonReportScreen), findsOneWidget);
    expect(find.text('Timeline'), findsOneWidget);
    expect(find.text('Current Balance'), findsOneWidget);

    await disposeReactiveWidgetTree(tester);
  });
}

import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/core/utils/currency_formatter.dart';
import 'package:family_ledger/features/settings/providers/settings_view_model.dart';
import 'package:family_ledger/features/settings/settings_screen.dart';
import 'package:family_ledger/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';
import '../../helpers/test_repositories.dart';

void main() {
  late TestRepositories repos;

  setUp(() async {
    repos = TestRepositories(await createTestDatabase());
  });

  tearDown(() async {
    await repos.close();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [settingsRepositoryProvider.overrideWithValue(repos.settings)],
      child: MaterialApp(
        home: Column(
          children: [
            const Expanded(child: SettingsScreen()),
            // A currency-formatting consumer outside SettingsScreen itself,
            // standing in for any other screen (Dashboard, People, Reports,
            // Transactions) that formats money via currencySymbolProvider —
            // proves the reactivity reaches beyond the Settings screen.
            Consumer(
              builder: (context, ref, _) => Text(
                CurrencyFormatter.format(
                  1000,
                  symbol: ref.watch(currencySymbolProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('shows the current theme and currency defaults', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('System default'), findsOneWidget);
    expect(find.text('Indian Rupee (₹)'), findsOneWidget);
    expect(find.text('₹1,000.00'), findsOneWidget);
  });

  testWidgets('changing the theme updates the setting', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ListTile, 'Theme'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(RadioListTile<AppThemeMode>, 'Dark'));
    await tester.pumpAndSettle();

    expect(find.text('Dark'), findsOneWidget);
    final settings = await repos.settings.getSettings();
    expect(settings.theme.name, 'dark');
  });

  testWidgets('changing the currency updates the formatted output', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('₹1,000.00'), findsOneWidget);

    await tester.tap(find.widgetWithText(ListTile, 'Currency'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(RadioListTile<String>, 'US Dollar (\$)'),
    );
    await tester.pumpAndSettle();

    expect(find.text('US Dollar (\$)'), findsOneWidget);
    expect(find.text('\$1,000.00'), findsOneWidget);
    expect(find.text('₹1,000.00'), findsNothing);

    final settings = await repos.settings.getSettings();
    expect(settings.currency, 'USD');
  });
}

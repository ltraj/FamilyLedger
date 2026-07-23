import 'package:family_ledger/app/app_shell.dart';
import 'package:family_ledger/core/constants/app_constants.dart';
import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/core/services/service_locator.dart';
import 'package:family_ledger/core/theme/app_theme.dart';
import 'package:family_ledger/features/settings/providers/settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Application entry point.
///
/// Wires up dependency injection, then hands off to [AppShell] for
/// navigation between the app's top-level tabs.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator();
  runApp(const ProviderScope(child: FamilyLedgerApp()));
}

/// Root widget providing Material 3 theming and the app's navigation
/// shell.
///
/// `themeMode` follows `SettingsModel.theme` reactively via
/// `settingsViewModelProvider` — changing the theme in Settings re-themes
/// the whole app immediately, no restart needed. Falls back to
/// `ThemeMode.system` while settings are still loading (e.g. the very
/// first frame at app startup) or if the load fails.
class FamilyLedgerApp extends ConsumerWidget {
  const FamilyLedgerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = AppTheme.resolveThemeMode(
      ref.watch(settingsViewModelProvider).valueOrNull?.theme ??
          AppThemeMode.system,
    );

    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: const AppShell(),
    );
  }
}

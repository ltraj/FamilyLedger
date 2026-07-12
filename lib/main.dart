import 'package:family_ledger/app/app_shell.dart';
import 'package:family_ledger/core/constants/app_constants.dart';
import 'package:family_ledger/core/services/service_locator.dart';
import 'package:family_ledger/core/theme/app_theme.dart';
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
class FamilyLedgerApp extends StatelessWidget {
  const FamilyLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const AppShell(),
    );
  }
}

import 'package:family_ledger/core/constants/enums.dart';
import 'package:flutter/material.dart';

/// Material 3 theme configuration for the application.
///
/// [resolveThemeMode] is consumed by `main.dart`'s `FamilyLedgerApp`,
/// which watches `settingsViewModelProvider` to re-theme the app
/// immediately whenever `SettingsModel.theme` changes.
abstract final class AppTheme {
  static const _seedColor = 0xFF2E7D32;

  /// Light Material 3 theme.
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(_seedColor),
      brightness: Brightness.light,
    ),
  );

  /// Dark Material 3 theme.
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(_seedColor),
      brightness: Brightness.dark,
    ),
  );

  /// Resolves the active theme from a stored preference.
  static ThemeMode resolveThemeMode(AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };
  }
}

import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/core/constants/supported_currencies.dart';
import 'package:family_ledger/features/settings/models/settings_exceptions.dart';
import 'package:family_ledger/models/settings_model.dart';
import 'package:family_ledger/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads the single app-wide [SettingsModel] row and owns every mutation
/// to it (theme, currency).
///
/// Other features (Dashboard, People, Reports, Transactions) import
/// [currencySymbolProvider] directly from here rather than reading
/// [SettingsModel] themselves — the same cross-feature-import pattern
/// Dashboard already uses for `peopleViewModelProvider`.
final settingsViewModelProvider =
    AsyncNotifierProvider<SettingsViewModel, SettingsModel>(
      SettingsViewModel.new,
    );

class SettingsViewModel extends AsyncNotifier<SettingsModel> {
  @override
  Future<SettingsModel> build() {
    return ref.watch(settingsRepositoryProvider).getSettings();
  }

  /// Updates the app's theme preference.
  Future<void> setTheme(AppThemeMode theme) async {
    final current = await future;
    await ref
        .read(settingsRepositoryProvider)
        .update(current.copyWith(theme: theme));

    ref.invalidateSelf();
    await future;
  }

  /// Updates the app's currency. [currencyCode] must be one of
  /// `SupportedCurrencies.all`'s codes.
  Future<void> setCurrency(String currencyCode) async {
    final current = await future;
    await ref
        .read(settingsRepositoryProvider)
        .update(current.copyWith(currency: currencyCode));

    ref.invalidateSelf();
    await future;
  }

  /// Sets the automatic-backup interval in days, or turns the feature off
  /// entirely with null. Throws [InvalidBackupIntervalException] (writing
  /// nothing) for a zero/negative day count.
  Future<void> setAutoBackupIntervalDays(int? days) async {
    if (days != null && days < 1) {
      throw const InvalidBackupIntervalException();
    }

    final current = await future;
    await ref
        .read(settingsRepositoryProvider)
        .update(
          days == null
              ? current.copyWith(clearAutoBackupIntervalDays: true)
              : current.copyWith(autoBackupIntervalDays: days),
        );

    ref.invalidateSelf();
    await future;
  }

  /// Remembers [directoryPath] as the automatic-backup destination so the
  /// user is never prompted for it again.
  Future<void> setAutoBackupDirectory(String directoryPath) async {
    final current = await future;
    await ref
        .read(settingsRepositoryProvider)
        .update(current.copyWith(autoBackupDirectory: directoryPath));

    ref.invalidateSelf();
    await future;
  }
}

/// The display symbol for the currently selected currency
/// (`SettingsModel.currency`), reactive to Settings changes.
///
/// Falls back to `SupportedCurrencies`' default while settings are still
/// loading (e.g. at app startup) or if the load fails, so callers never
/// need to handle an `AsyncValue` themselves just to format an amount.
final currencySymbolProvider = Provider<String>((ref) {
  final currencyCode = ref.watch(settingsViewModelProvider).valueOrNull?.currency;
  return SupportedCurrencies.symbolFor(currencyCode);
});

import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/core/constants/supported_currencies.dart';
import 'package:family_ledger/features/backup/screens/backup_screen.dart';
import 'package:family_ledger/features/settings/providers/settings_view_model.dart';
import 'package:family_ledger/features/settings/widgets/auto_backup_sheet.dart';
import 'package:family_ledger/models/settings_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings tab: Backup & Restore, automatic backup, plus the app's theme
/// and currency preferences (`SettingsModel`).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(settingsViewModelProvider);
    final settings = settingsAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Backup & Restore'),
            subtitle: const Text('Export or restore your data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BackupScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.schedule_outlined),
            title: const Text('Automatic backup'),
            subtitle: Text(_autoBackupLabel(settings)),
            trailing: const Icon(Icons.chevron_right),
            onTap: settings == null ? null : () => AutoBackupSheet.show(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            subtitle: Text(_themeLabel(settings?.theme)),
            trailing: const Icon(Icons.chevron_right),
            onTap: settings == null
                ? null
                : () => _showThemeSheet(context, ref, settings.theme),
          ),
          ListTile(
            leading: const Icon(Icons.currency_exchange_outlined),
            title: const Text('Currency'),
            subtitle: Text(_currencyLabel(settings?.currency)),
            trailing: const Icon(Icons.chevron_right),
            onTap: settings == null
                ? null
                : () => _showCurrencySheet(context, ref, settings.currency),
          ),
          if (settingsAsync.hasError)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Could not load settings.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'More settings coming in future phases',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _autoBackupLabel(SettingsModel? settings) {
    final days = settings?.autoBackupIntervalDays;
    if (days == null) return 'Off';
    final interval = days == 1 ? 'Every day' : 'Every $days days';
    return settings?.autoBackupDirectory == null
        ? '$interval · no folder chosen'
        : interval;
  }

  String _themeLabel(AppThemeMode? mode) => switch (mode) {
    AppThemeMode.light => 'Light',
    AppThemeMode.dark => 'Dark',
    AppThemeMode.system || null => 'System default',
  };

  String _currencyLabel(String? code) {
    if (code == null) return '';
    final currency = SupportedCurrencies.definitionFor(code);
    return '${currency.label} (${currency.symbol})';
  }

  Future<void> _showThemeSheet(
    BuildContext context,
    WidgetRef ref,
    AppThemeMode current,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _SettingsOptionSheet<AppThemeMode>(
        title: 'Theme',
        options: AppThemeMode.values,
        current: current,
        labelOf: _themeLabel,
        onSelected: (mode) {
          ref.read(settingsViewModelProvider.notifier).setTheme(mode);
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }

  Future<void> _showCurrencySheet(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _SettingsOptionSheet<String>(
        title: 'Currency',
        options: [for (final currency in SupportedCurrencies.all) currency.code],
        current: current,
        labelOf: _currencyLabel,
        onSelected: (code) {
          ref.read(settingsViewModelProvider.notifier).setCurrency(code);
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }
}

/// Generic radio-list bottom sheet, matching the pattern in
/// `lib/features/people/widgets/person_sort_filter_sheet.dart`'s
/// `_OptionSheet`.
class _SettingsOptionSheet<T> extends StatelessWidget {
  const _SettingsOptionSheet({
    required this.title,
    required this.options,
    required this.current,
    required this.labelOf,
    required this.onSelected,
  });

  final String title;
  final List<T> options;
  final T current;
  final String Function(T option) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          RadioGroup<T>(
            groupValue: current,
            onChanged: (value) {
              if (value != null) onSelected(value);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in options)
                  RadioListTile<T>(value: option, title: Text(labelOf(option))),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

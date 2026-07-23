import 'package:family_ledger/backup/utils/backup_rotation_policy.dart';
import 'package:family_ledger/features/backup/providers/backup_file_picker.dart';
import 'package:family_ledger/features/settings/providers/settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheet configuring automatic backup: on/off, the "every N days"
/// interval, and the remembered destination folder.
///
/// Watches [settingsViewModelProvider] (rather than taking a settings
/// snapshot) so every control reflects a change immediately — the same
/// write-through-then-rebuild flow as the theme and currency sheets, just
/// with three controls in one sheet since they only make sense together.
class AutoBackupSheet extends ConsumerWidget {
  const AutoBackupSheet({super.key});

  /// Interval used when the switch is first turned on, before the user
  /// picks their own.
  static const int defaultIntervalDays = 7;

  static const int _minIntervalDays = 1;
  static const int _maxIntervalDays = 365;

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const AutoBackupSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsViewModelProvider).valueOrNull;
    final viewModel = ref.read(settingsViewModelProvider.notifier);

    if (settings == null) {
      return const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final intervalDays = settings.autoBackupIntervalDays;
    final isEnabled = intervalDays != null;
    final directory = settings.autoBackupDirectory;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Text(
              'Automatic backup',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Back up automatically'),
            subtitle: const Text(
              'Runs when you open the app and the last backup is old enough',
            ),
            value: isEnabled,
            onChanged: (enabled) => viewModel.setAutoBackupIntervalDays(
              enabled ? defaultIntervalDays : null,
            ),
          ),
          if (isEnabled) ...[
            ListTile(
              title: const Text('Backup interval'),
              subtitle: Text(
                intervalDays == 1 ? 'Every day' : 'Every $intervalDays days',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    tooltip: 'Fewer days',
                    onPressed: intervalDays <= _minIntervalDays
                        ? null
                        : () => viewModel.setAutoBackupIntervalDays(
                            intervalDays - 1,
                          ),
                  ),
                  Text(
                    '$intervalDays',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'More days',
                    onPressed: intervalDays >= _maxIntervalDays
                        ? null
                        : () => viewModel.setAutoBackupIntervalDays(
                            intervalDays + 1,
                          ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Backup folder'),
              subtitle: Text(
                directory ?? 'Not chosen yet — required for automatic backup',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: directory == null
                    ? theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      )
                    : null,
              ),
              trailing: TextButton(
                onPressed: () => _pickFolder(ref),
                child: Text(directory == null ? 'Choose' : 'Change'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                'Only the newest ${BackupRotationPolicy.keepCount} backups '
                'are kept in this folder; older ones are removed '
                'automatically.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _pickFolder(WidgetRef ref) async {
    final path = await ref
        .read(backupFilePickerProvider)
        .pickDestinationDirectory();
    if (path == null) return;
    await ref
        .read(settingsViewModelProvider.notifier)
        .setAutoBackupDirectory(path);
  }
}

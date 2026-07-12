import 'package:family_ledger/backup/models/backup_export_exception.dart';
import 'package:family_ledger/backup/models/backup_import_exception.dart';
import 'package:family_ledger/backup/models/import_validation_result.dart';
import 'package:family_ledger/core/utils/relative_date.dart';
import 'package:family_ledger/features/backup/providers/backup_file_picker.dart';
import 'package:family_ledger/features/backup/providers/backup_info_state.dart';
import 'package:family_ledger/features/backup/providers/backup_view_model.dart';
import 'package:family_ledger/features/backup/utils/file_size_formatter.dart';
import 'package:family_ledger/features/people/providers/people_view_model.dart';
import 'package:family_ledger/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lets the user create a full backup of their data, or restore from one.
///
/// The only screen this phase adds. Reads and writes go through
/// `BackupService`/`RestoreService` exclusively — this widget picks
/// files/folders (Storage Access Framework, via `file_picker`) and shows
/// progress/errors, nothing more.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isBackingUp = false;
  bool _isRestoring = false;

  bool get _isBusy => _isBackingUp || _isRestoring;

  @override
  Widget build(BuildContext context) {
    final infoAsync = ref.watch(backupViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: infoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load: $error')),
        data: (info) => _BackupScreenBody(
          info: info,
          isBackingUp: _isBackingUp,
          isRestoring: _isRestoring,
          onExport: _isBusy ? null : _handleExport,
          onImport: _isBusy ? null : _handleImport,
        ),
      ),
    );
  }

  Future<void> _handleExport() async {
    final destinationDirectoryPath = await ref
        .read(backupFilePickerProvider)
        .pickDestinationDirectory();
    if (destinationDirectoryPath == null) return; // user cancelled

    setState(() => _isBackingUp = true);
    try {
      final result = await ref
          .read(backupViewModelProvider.notifier)
          .exportBackup(destinationDirectoryPath);

      if (!mounted) return;
      _showMessage('Backup saved (${FileSizeFormatter.format(result.fileSizeBytes)}).');
    } on BackupExportException catch (error) {
      if (!mounted) return;
      _showMessage(error.message, isError: true);
    } catch (error) {
      if (!mounted) return;
      _showMessage('Backup failed: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _handleImport() async {
    final zipFilePath = await ref
        .read(backupFilePickerProvider)
        .pickBackupZip();
    if (zipFilePath == null) return; // user cancelled

    final confirmed = await _confirmRestore();
    if (confirmed != true) return;

    setState(() => _isRestoring = true);
    try {
      final result = await ref
          .read(backupViewModelProvider.notifier)
          .restoreFromZip(zipFilePath);

      // Not covered by transactionsStreamProvider's reactivity — see
      // BackupViewModel.restoreFromZip's doc comment. People usually
      // refresh via the transaction stream as a side effect of the wipe/
      // reinsert, but that's incidental; invalidate explicitly so a
      // restore that changes people without changing transactions can't
      // leave the People tab stale.
      ref.invalidate(categoriesListProvider);
      ref.invalidate(peopleViewModelProvider);

      if (!mounted) return;
      _showMessage(
        'Restore complete: ${result.peopleCount} people, '
        '${result.transactionCount} transactions, '
        '${result.categoryCount} categories.',
      );
    } on BackupImportException catch (error) {
      if (!mounted) return;
      _showMessage(_messageFor(error), isError: true);
    } catch (error) {
      if (!mounted) return;
      _showMessage('Restore failed: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  String _messageFor(BackupImportException error) {
    return switch (error.reason) {
      ImportValidationFailureReason.corruptedArchive =>
        'This file is not a valid backup archive.',
      ImportValidationFailureReason.missingFiles =>
        'This backup is incomplete: ${error.message}',
      ImportValidationFailureReason.corruptedJson =>
        'This backup is damaged and could not be read.',
      ImportValidationFailureReason.unsupportedFormatVersion =>
        'This backup was made by a version of the app this build cannot '
            'import.',
      ImportValidationFailureReason.checksumMismatch =>
        'This backup failed its integrity check and may have been '
            'altered or corrupted.',
      ImportValidationFailureReason.duplicateIdentifiers =>
        'This backup contains duplicate records and cannot be trusted.',
      ImportValidationFailureReason.danglingReference =>
        'This backup contains inconsistent data and cannot be trusted.',
      ImportValidationFailureReason.permissionDenied =>
        'Permission was denied while reading this backup.',
    };
  }

  Future<bool?> _confirmRestore() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace all data?'),
        content: const Text(
          'Restoring this backup will permanently replace every person, '
          'category, and transaction currently in the app with what is '
          'in the backup. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Replace data'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? theme.colorScheme.error : null,
      ),
    );
  }
}

class _BackupScreenBody extends StatelessWidget {
  const _BackupScreenBody({
    required this.info,
    required this.isBackingUp,
    required this.isRestoring,
    required this.onExport,
    required this.onImport,
  });

  final BackupInfoState info;
  final bool isBackingUp;
  final bool isRestoring;
  final VoidCallback? onExport;
  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Backup Info', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                _InfoRow(
                  label: 'Last backup',
                  value: info.lastBackupDate == null
                      ? 'Never'
                      : RelativeDate.format(info.lastBackupDate!),
                ),
                _InfoRow(
                  label: 'Backup size',
                  value: info.lastBackupSizeBytes == null
                      ? '—'
                      : FileSizeFormatter.format(info.lastBackupSizeBytes!),
                ),
                _InfoRow(
                  label: 'Export destination',
                  value: info.lastBackupDestinationDirectory ?? '—',
                ),
                _InfoRow(
                  label: 'Last restore',
                  value: info.lastRestoreDate == null
                      ? 'Never'
                      : RelativeDate.format(info.lastRestoreDate!),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onExport,
          icon: isBackingUp
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_outlined),
          label: Text(isBackingUp ? 'Creating backup…' : 'Export Backup'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onImport,
          icon: isRestoring
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_outlined),
          label: Text(isRestoring ? 'Restoring…' : 'Import Backup'),
        ),
        const SizedBox(height: 16),
        Text(
          'Backups are saved as a single .zip file you can store anywhere '
          '— Downloads, Google Drive, a USB drive, an SD card. This app '
          "does not upload backups anywhere on its own.",
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

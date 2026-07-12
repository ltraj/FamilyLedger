import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin seam over `FilePicker`'s static platform API, so `BackupScreen`
/// can be widget-tested: tests override [backupFilePickerProvider] with a
/// fake returning a temp path (or null for "user cancelled") instead of
/// needing real platform channels.
class BackupFilePicker {
  const BackupFilePicker();

  /// The folder the user chose to save a backup into, or null if they
  /// cancelled the picker.
  Future<String?> pickDestinationDirectory() {
    return FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose where to save the backup',
    );
  }

  /// The backup `.zip` the user chose to restore from, or null if they
  /// cancelled the picker.
  Future<String?> pickBackupZip() async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'Choose a backup file to restore',
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    return picked?.files.single.path;
  }
}

final backupFilePickerProvider = Provider<BackupFilePicker>(
  (ref) => const BackupFilePicker(),
);

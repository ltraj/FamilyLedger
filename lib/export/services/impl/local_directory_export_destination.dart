import 'dart:io';

import 'package:family_ledger/export/services/export_destination.dart';
import 'package:path/path.dart' as p;

/// Writes an export bundle's files to a local folder on disk.
///
/// Used as a staging area: `ExportService` writes everything here first,
/// then zips the whole folder as the final step. Keeping "write files
/// somewhere" and "package them as a portable archive" as separate steps
/// means this class has no knowledge of zipping at all.
class LocalDirectoryExportDestination implements ExportDestination {
  LocalDirectoryExportDestination(this.rootPath);

  /// Absolute path to the folder files get written into.
  final String rootPath;

  @override
  Future<String> resolvePath(String relativePath) async {
    final fullPath = p.join(rootPath, relativePath);
    final directory = Directory(p.dirname(fullPath));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return fullPath;
  }
}

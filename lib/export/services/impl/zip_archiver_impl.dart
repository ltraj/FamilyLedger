import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:family_ledger/export/services/zip_archiver.dart';
import 'package:path/path.dart' as p;

class ZipArchiverImpl implements ZipArchiver {
  const ZipArchiverImpl();

  @override
  Future<void> zipDirectory({
    required String sourceDirectoryPath,
    required String outputZipPath,
  }) async {
    final encoder = ZipFileEncoder();
    encoder.create(outputZipPath);
    await encoder.addDirectory(
      Directory(sourceDirectoryPath),
      includeDirName: false,
    );
    await encoder.close();
  }

  @override
  Future<void> extractZip({
    required String zipFilePath,
    required String outputDirectoryPath,
  }) async {
    final bytes = await File(zipFilePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final extractionRoot = p.normalize(p.absolute(outputDirectoryPath));

    for (final file in archive) {
      // Path-traversal guard: an entry named e.g. `../../evil` (or an
      // absolute path) would otherwise be written OUTSIDE the extraction
      // directory — arbitrary file overwrite from a malicious archive.
      // Resolve the final path and refuse anything that escapes the root.
      final outputPath = p.normalize(
        p.join(extractionRoot, file.name),
      );
      if (!p.isWithin(extractionRoot, outputPath)) {
        throw const FormatException(
          'Archive contains an entry with an unsafe file path.',
        );
      }

      if (file.isFile) {
        final outputFile = File(outputPath);
        await outputFile.create(recursive: true);
        await outputFile.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(outputPath).create(recursive: true);
      }
    }
  }
}

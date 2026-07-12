import 'dart:io';

import 'package:family_ledger/backup/constants/backup_constants.dart';
import 'package:family_ledger/backup/models/backup_export_exception.dart';
import 'package:family_ledger/backup/models/backup_result_model.dart';
import 'package:family_ledger/backup/services/backup_service.dart';
import 'package:family_ledger/export/services/export_service.dart';
import 'package:family_ledger/export/services/impl/local_directory_export_destination.dart';
import 'package:family_ledger/export/services/zip_archiver.dart';
import 'package:family_ledger/models/backup_model.dart';
import 'package:family_ledger/repositories/app_info_repository.dart';
import 'package:family_ledger/repositories/backup_repository.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class BackupServiceImpl implements BackupService {
  BackupServiceImpl({
    required ExportService exportService,
    required ZipArchiver zipArchiver,
    required BackupRepository backupRepository,
    required AppInfoRepository appInfoRepository,
  }) : _exportService = exportService,
       _zipArchiver = zipArchiver,
       _backupRepository = backupRepository,
       _appInfoRepository = appInfoRepository;

  final ExportService _exportService;
  final ZipArchiver _zipArchiver;
  final BackupRepository _backupRepository;
  final AppInfoRepository _appInfoRepository;

  @override
  Future<BackupResultModel> createBackup({
    required String destinationDirectoryPath,
  }) async {
    // Fail fast, before the (potentially long) export runs: some
    // pickable locations aren't writable filesystem paths — virtual SAF
    // providers on Android (a Google Drive folder), read-only mounts —
    // and discovering that only after staging 100k transactions wastes
    // the whole run.
    await _ensureWritable(destinationDirectoryPath);

    final stagingDirectoryPath = await _newStagingDirectory();

    try {
      final exportResult = await _exportService.exportAll(
        LocalDirectoryExportDestination(stagingDirectoryPath),
      );

      final createdAt = DateTime.now();
      final outputZipPath = p.join(
        destinationDirectoryPath,
        BackupConstants.backupFileName(createdAt),
      );

      try {
        await _zipArchiver.zipDirectory(
          sourceDirectoryPath: exportResult.exportDirectoryPath,
          outputZipPath: outputZipPath,
        );
      } on FileSystemException catch (error) {
        throw BackupExportException(
          'Could not write the backup to the chosen location: '
          '${error.message}',
        );
      }

      final fileSizeBytes = await File(outputZipPath).length();

      await _backupRepository.insert(
        BackupModel(
          backupDate: createdAt,
          backupPath: outputZipPath,
          backupSize: fileSizeBytes,
        ),
      );
      await _appInfoRepository.recordBackup(createdAt);

      return BackupResultModel(
        zipFilePath: outputZipPath,
        fileSizeBytes: fileSizeBytes,
        createdAt: createdAt,
        peopleCount: exportResult.metadata.totalPeopleCount,
        transactionCount: exportResult.metadata.totalTransactionCount,
        categoryCount: exportResult.metadata.totalCategoryCount,
      );
    } finally {
      await _deleteQuietly(stagingDirectoryPath);
    }
  }

  Future<void> _ensureWritable(String directoryPath) async {
    final probe = File(
      p.join(
        directoryPath,
        '.family_ledger_write_probe_${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    try {
      await probe.writeAsString('probe');
      await probe.delete();
    } on FileSystemException {
      throw const BackupExportException(
        'The chosen folder cannot be written to from this app. Pick a '
        'local folder such as Downloads or Documents instead.',
      );
    }
  }

  Future<String> _newStagingDirectory() async {
    final tempDirectory = await getTemporaryDirectory();
    final path = p.join(
      tempDirectory.path,
      'family_ledger_export_${DateTime.now().microsecondsSinceEpoch}',
    );
    await Directory(path).create(recursive: true);
    return path;
  }

  Future<void> _deleteQuietly(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}

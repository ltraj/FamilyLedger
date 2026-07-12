import 'dart:io';

import 'package:family_ledger/backup/services/backup_service.dart';
import 'package:family_ledger/backup/services/impl/backup_service_impl.dart';
import 'package:family_ledger/backup/services/impl/import_validator_impl.dart';
import 'package:family_ledger/backup/services/impl/restore_service_impl.dart';
import 'package:family_ledger/backup/services/restore_service.dart';
import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/export/services/impl/export_data_collector_impl.dart';
import 'package:family_ledger/export/services/impl/export_file_writer_impl.dart';
import 'package:family_ledger/export/services/impl/export_service_impl.dart';
import 'package:family_ledger/export/services/impl/zip_archiver_impl.dart';
import 'package:family_ledger/features/backup/providers/backup_file_picker.dart';
import 'package:family_ledger/features/backup/providers/backup_service_providers.dart';
import 'package:family_ledger/features/backup/screens/backup_screen.dart';
import 'package:family_ledger/models/transaction_model.dart';
import 'package:family_ledger/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../helpers/fake_path_provider.dart';
import '../../helpers/test_database.dart';
import '../../helpers/test_repositories.dart';
import '../../helpers/widget_test_utils.dart';

/// Test double for the picker seam: returns whatever paths the test
/// scripted, or null to simulate the user cancelling the dialog.
class FakeBackupFilePicker extends BackupFilePicker {
  const FakeBackupFilePicker({this.directory, this.zipFile});

  final String? directory;
  final String? zipFile;

  @override
  Future<String?> pickDestinationDirectory() async => directory;

  @override
  Future<String?> pickBackupZip() async => zipFile;
}

void main() {
  late Directory tempRoot;
  late TestRepositories repos;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('backup_screen_test');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempRoot.path);
    repos = TestRepositories(await createTestDatabase());
  });

  tearDown(() async {
    await repos.close();
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  BackupService backupService() => BackupServiceImpl(
    exportService: ExportServiceImpl(
      collector: ExportDataCollectorImpl(
        peopleRepository: repos.people,
        categoryRepository: repos.categories,
        transactionRepository: repos.transactions,
        settingsRepository: repos.settings,
        appInfoRepository: repos.appInfo,
      ),
      writer: const ExportFileWriterImpl(),
    ),
    zipArchiver: const ZipArchiverImpl(),
    backupRepository: repos.backups,
    appInfoRepository: repos.appInfo,
  );

  RestoreService restoreService() => RestoreServiceImpl(
    database: repos.database,
    importValidator: ImportValidatorImpl(zipArchiver: const ZipArchiverImpl()),
    peopleRepository: repos.people,
    categoryRepository: repos.categories,
    transactionRepository: repos.transactions,
    settingsRepository: repos.settings,
    appInfoRepository: repos.appInfo,
  );

  Widget buildApp({required BackupFilePicker picker}) {
    return ProviderScope(
      overrides: [
        peopleRepositoryProvider.overrideWithValue(repos.people),
        transactionRepositoryProvider.overrideWithValue(repos.transactions),
        categoryRepositoryProvider.overrideWithValue(repos.categories),
        backupRepositoryProvider.overrideWithValue(repos.backups),
        appInfoRepositoryProvider.overrideWithValue(repos.appInfo),
        backupServiceProvider.overrideWithValue(backupService()),
        restoreServiceProvider.overrideWithValue(restoreService()),
        backupFilePickerProvider.overrideWithValue(picker),
      ],
      child: const MaterialApp(home: BackupScreen()),
    );
  }

  testWidgets('shows Never/em-dash placeholders before any backup exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(picker: const FakeBackupFilePicker()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Last backup'), findsOneWidget);
    expect(find.text('Never'), findsNWidgets(2)); // backup + restore
    expect(find.text('Export Backup'), findsOneWidget);
    expect(find.text('Import Backup'), findsOneWidget);

    await disposeReactiveWidgetTree(tester);
  });

  testWidgets('a cancelled picker leaves everything untouched', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(picker: const FakeBackupFilePicker()), // returns null
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Export Backup'));
    await tester.pumpAndSettle();

    expect(find.text('Never'), findsNWidgets(2));
    expect(await repos.backups.getAll(), isEmpty);

    await disposeReactiveWidgetTree(tester);
  });

  testWidgets('export creates a zip and updates the info card', (
    tester,
  ) async {
    final destination = Directory(p.join(tempRoot.path, 'chosen_folder'))
      ..createSync();

    await tester.pumpWidget(
      buildApp(picker: FakeBackupFilePicker(directory: destination.path)),
    );
    await tester.pumpAndSettle();

    // The export does real file I/O, which never completes inside the
    // widget test's fake-async zone — tester.runAsync escapes to the real
    // event loop for the duration of the work.
    await tester.runAsync(() async {
      await tester.tap(find.text('Export Backup'));
      var waitedMilliseconds = 0;
      while ((await repos.backups.getAll()).isEmpty &&
          waitedMilliseconds < 5000) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        waitedMilliseconds += 20;
      }
    });
    await tester.pumpAndSettle();

    expect(find.textContaining('Backup saved'), findsOneWidget);

    final zips = destination
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.zip'));
    expect(zips, hasLength(1));

    // Info card now reflects the recorded backup.
    expect(find.text('Today'), findsOneWidget);
    expect(find.text(destination.path), findsOneWidget);
    final records = await repos.backups.getAll();
    expect(records, hasLength(1));

    await disposeReactiveWidgetTree(tester);
  });

  testWidgets('export to an unwritable folder shows a clear error', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        picker: FakeBackupFilePicker(
          directory: p.join(tempRoot.path, 'does_not_exist'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      await tester.tap(find.text('Export Backup'));
      // The writability probe fails fast; give its I/O a moment.
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();

    expect(
      find.textContaining('cannot be written to from this app'),
      findsOneWidget,
    );
    expect(await repos.backups.getAll(), isEmpty);

    await disposeReactiveWidgetTree(tester);
  });

  testWidgets(
    'import asks for confirmation, and cancelling changes nothing',
    (tester) async {
      // A real backup zip made from the current (seeded) data. Real file
      // I/O, so it must run on the real event loop (see the export test).
      final destination = Directory(p.join(tempRoot.path, 'backups'))
        ..createSync();
      late final String zipFilePath;
      await tester.runAsync(() async {
        final backup = await backupService().createBackup(
          destinationDirectoryPath: destination.path,
        );
        zipFilePath = backup.zipFilePath;
      });

      final people = await repos.people.getAll();
      await repos.transactions.insert(
        TransactionModel(
          personId: people.first.id!,
          amount: 777,
          transactionType: TransactionType.advanceReceived,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        buildApp(picker: FakeBackupFilePicker(zipFile: zipFilePath)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Import Backup'));
      await tester.pumpAndSettle();

      expect(find.text('Replace all data?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // The post-backup transaction survives an aborted import.
      expect(await repos.transactions.getAll(), hasLength(1));

      await disposeReactiveWidgetTree(tester);
    },
  );

  testWidgets('confirmed import replaces data and reports the counts', (
    tester,
  ) async {
    final destination = Directory(p.join(tempRoot.path, 'backups'))
      ..createSync();
    late final String zipFilePath;
    await tester.runAsync(() async {
      final backup = await backupService().createBackup(
        destinationDirectoryPath: destination.path,
      );
      zipFilePath = backup.zipFilePath;
    });

    // Recorded after the backup — restoring must wipe it.
    final people = await repos.people.getAll();
    await repos.transactions.insert(
      TransactionModel(
        personId: people.first.id!,
        amount: 777,
        transactionType: TransactionType.advanceReceived,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    await tester.pumpWidget(
      buildApp(picker: FakeBackupFilePicker(zipFile: zipFilePath)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    // The restore behind this confirmation does real file I/O (zip
    // extraction) — run it on the real event loop, pumping frames while
    // polling for the completion message so the whole flow (including
    // the busy spinner turning off) finishes inside the runAsync window.
    await tester.runAsync(() async {
      await tester.tap(find.text('Replace data'));
      var waitedMilliseconds = 0;
      while (find.textContaining('Restore complete').evaluate().isEmpty &&
          waitedMilliseconds < 8000) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
        waitedMilliseconds += 50;
      }
      // One extra beat for the finally-block setState (spinner off).
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();
    });
    await tester.pumpAndSettle();

    expect(find.textContaining('Restore complete'), findsOneWidget);
    expect(find.textContaining('0 transactions'), findsOneWidget);
    expect(await repos.transactions.getAll(), isEmpty);

    // Info card now shows the restore.
    expect(find.text('Last restore'), findsOneWidget);
    expect(find.text('Today'), findsWidgets);

    await disposeReactiveWidgetTree(tester);
  });

  testWidgets('importing an invalid file shows the specific error', (
    tester,
  ) async {
    final bogus = File(p.join(tempRoot.path, 'not_a_backup.zip'))
      ..writeAsBytesSync([1, 2, 3]);

    await tester.pumpWidget(
      buildApp(picker: FakeBackupFilePicker(zipFile: bogus.path)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Import Backup'));
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      await tester.tap(find.text('Replace data'));
      // Validation does real file I/O before it can reject the file;
      // pump while polling for the error message (see the confirmed-
      // import test for why).
      var waitedMilliseconds = 0;
      while (find
              .text('This file is not a valid backup archive.')
              .evaluate()
              .isEmpty &&
          waitedMilliseconds < 8000) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
        waitedMilliseconds += 50;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();
    });
    await tester.pumpAndSettle();

    expect(
      find.text('This file is not a valid backup archive.'),
      findsOneWidget,
    );

    await disposeReactiveWidgetTree(tester);
  });
}

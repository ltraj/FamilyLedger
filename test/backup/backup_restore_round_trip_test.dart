import 'dart:io';

import 'package:family_ledger/backup/services/impl/import_validator_impl.dart';
import 'package:family_ledger/backup/services/impl/restore_service_impl.dart';
import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/core/utils/balance_calculator.dart';
import 'package:family_ledger/export/services/impl/export_data_collector_impl.dart';
import 'package:family_ledger/export/services/impl/export_file_writer_impl.dart';
import 'package:family_ledger/export/services/impl/export_service_impl.dart';
import 'package:family_ledger/export/services/impl/local_directory_export_destination.dart';
import 'package:family_ledger/export/services/impl/zip_archiver_impl.dart';
import 'package:family_ledger/models/category_model.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../helpers/fake_path_provider.dart';
import '../helpers/test_database.dart';
import '../helpers/test_repositories.dart';

void main() {
  late Directory tempRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('backup_round_trip_test');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempRoot.path);
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  /// Exports everything in [source] to a fresh `.zip` under [tempRoot],
  /// returning its path.
  Future<String> exportTo(TestRepositories source) async {
    final stagingDir = await Directory(
      p.join(tempRoot.path, 'staging_${DateTime.now().microsecondsSinceEpoch}'),
    ).create(recursive: true);

    final exportService = ExportServiceImpl(
      collector: ExportDataCollectorImpl(
        peopleRepository: source.people,
        categoryRepository: source.categories,
        transactionRepository: source.transactions,
        settingsRepository: source.settings,
        appInfoRepository: source.appInfo,
      ),
      writer: const ExportFileWriterImpl(),
    );

    final exportResult = await exportService.exportAll(
      LocalDirectoryExportDestination(stagingDir.path),
    );

    final zipPath = p.join(
      tempRoot.path,
      'backup_${DateTime.now().microsecondsSinceEpoch}.zip',
    );
    await const ZipArchiverImpl().zipDirectory(
      sourceDirectoryPath: exportResult.exportDirectoryPath,
      outputZipPath: zipPath,
    );
    return zipPath;
  }

  RestoreServiceImpl restoreServiceFor(TestRepositories target) {
    return RestoreServiceImpl(
      database: target.database,
      importValidator: ImportValidatorImpl(zipArchiver: const ZipArchiverImpl()),
      peopleRepository: target.people,
      categoryRepository: target.categories,
      transactionRepository: target.transactions,
      settingsRepository: target.settings,
      appInfoRepository: target.appInfo,
    );
  }

  test('restoring a backup reproduces the source data exactly', () async {
    final source = TestRepositories(await createTestDatabase());
    addTearDown(source.close);

    // Replace the seeded defaults with deliberately varied data: a
    // person with no transactions, a category-less transaction, an
    // expense, and a negative adjustment.
    final now = DateTime(2026, 3, 1);
    final personId = await source.people.insert(
      PersonModel(
        name: 'Extra Helper',
        type: PersonType.temporary,
        status: PersonStatus.active,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final categoryId = await source.categories.insert(
      CategoryModel(
        name: 'Custom Category',
        icon: 'star',
        color: '#123456',
        isDefault: false,
        createdAt: now,
      ),
    );
    await source.transactions.insert(
      TransactionModel(
        personId: personId,
        amount: 500,
        transactionType: TransactionType.advanceReceived,
        categoryId: categoryId,
        remark: 'Initial advance',
        date: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await source.transactions.insert(
      TransactionModel(
        personId: personId,
        amount: 120,
        transactionType: TransactionType.expensePaid,
        date: now.add(const Duration(days: 1)),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await source.transactions.insert(
      TransactionModel(
        personId: personId,
        amount: -30,
        transactionType: TransactionType.adjustment,
        remark: 'Correction',
        date: now.add(const Duration(days: 2)),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final sourcePeople = await source.people.getAll();
    final sourceCategories = await source.categories.getAll();
    final sourceTransactions = await source.transactions.getAll();
    final sourceSettings = await source.settings.getSettings();
    final sourceBalance = await source.transactions.calculateBalance(
      personId,
    );

    final zipPath = await exportTo(source);

    // The target starts with its own, different seeded data — restore
    // must replace it entirely, not merge with it.
    final target = TestRepositories(await createTestDatabase());
    addTearDown(target.close);
    await target.people.insert(
      PersonModel(
        name: 'Should Be Wiped',
        type: PersonType.permanent,
        status: PersonStatus.active,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final result = await restoreServiceFor(target).restore(zipPath);

    expect(result.peopleCount, sourcePeople.length);
    expect(result.categoryCount, sourceCategories.length);
    expect(result.transactionCount, sourceTransactions.length);

    final restoredPeople = await target.people.getAll();
    final restoredCategories = await target.categories.getAll();
    final restoredTransactions = await target.transactions.getAll();
    final restoredSettings = await target.settings.getSettings();

    expect(restoredPeople.map((p) => p.id).toSet(), sourcePeople.map((p) => p.id).toSet());
    expect(
      restoredPeople.map((p) => p.name).toSet(),
      sourcePeople.map((p) => p.name).toSet(),
    );
    expect(
      restoredCategories.map((c) => c.name).toSet(),
      sourceCategories.map((c) => c.name).toSet(),
    );
    expect(restoredTransactions.length, sourceTransactions.length);
    expect(restoredSettings.currency, sourceSettings.currency);

    // Balances are re-derived, never stored — restoring must reproduce
    // the same derived balance too.
    final restoredBalance = await target.transactions.calculateBalance(
      personId,
    );
    expect(restoredBalance, sourceBalance);
    expect(
      BalanceCalculator.calculateBalance(restoredTransactions.where((t) => t.personId == personId).toList()),
      350, // 500 (advance) - 120 (expense) - 30 (adjustment)
    );
  });

  test('handles a larger dataset without dropping or duplicating rows', () async {
    final source = TestRepositories(await createTestDatabase());
    addTearDown(source.close);

    final people = await source.people.getAll();
    final categories = await source.categories.getAll();
    final now = DateTime(2026, 1, 1);

    const transactionCount = 500;
    for (var i = 0; i < transactionCount; i++) {
      final person = people[i % people.length];
      final category = categories[i % categories.length];
      await source.transactions.insert(
        TransactionModel(
          personId: person.id!,
          amount: (i % 50) + 1,
          transactionType: TransactionType.values[i % TransactionType.values.length],
          categoryId: category.id,
          date: now.add(Duration(hours: i)),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    final zipPath = await exportTo(source);

    final target = TestRepositories(await createTestDatabase());
    addTearDown(target.close);

    final result = await restoreServiceFor(target).restore(zipPath);

    expect(result.transactionCount, transactionCount);
    final restoredTransactions = await target.transactions.getAll();
    expect(restoredTransactions, hasLength(transactionCount));
    expect(
      restoredTransactions.map((t) => t.id).toSet(),
      hasLength(transactionCount),
    );
  });
}

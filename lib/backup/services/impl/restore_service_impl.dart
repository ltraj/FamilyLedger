import 'dart:io';

import 'package:family_ledger/backup/models/backup_import_exception.dart';
import 'package:family_ledger/backup/models/import_bundle_model.dart';
import 'package:family_ledger/backup/models/import_validation_result.dart';
import 'package:family_ledger/backup/models/restore_result_model.dart';
import 'package:family_ledger/backup/services/import_validator.dart';
import 'package:family_ledger/backup/services/restore_service.dart';
import 'package:family_ledger/core/database/app_database.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/models/transaction_model.dart';
import 'package:family_ledger/repositories/app_info_repository.dart';
import 'package:family_ledger/repositories/category_repository.dart';
import 'package:family_ledger/repositories/people_repository.dart';
import 'package:family_ledger/repositories/settings_repository.dart';
import 'package:family_ledger/repositories/transaction_repository.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Drift-backed implementation of [RestoreService].
///
/// Copying attachment files from the extracted bundle into the app's
/// permanent storage happens before the database transaction; writing the
/// restored records happens inside a single [AppDatabase.transaction], so
/// a failure partway through the database step rolls every table back to
/// its pre-restore state. [database] is the same [AppDatabase] instance
/// injected into every repository this class receives — Drift joins
/// queries made through repositories from inside the transaction callback
/// into that same ambient transaction, so `transactionRepository.insert`
/// (etc.) participate correctly without needing their own transaction
/// awareness.
class RestoreServiceImpl implements RestoreService {
  RestoreServiceImpl({
    required AppDatabase database,
    required ImportValidator importValidator,
    required PeopleRepository peopleRepository,
    required CategoryRepository categoryRepository,
    required TransactionRepository transactionRepository,
    required SettingsRepository settingsRepository,
    required AppInfoRepository appInfoRepository,
  }) : _database = database,
       _importValidator = importValidator,
       _peopleRepository = peopleRepository,
       _categoryRepository = categoryRepository,
       _transactionRepository = transactionRepository,
       _settingsRepository = settingsRepository,
       _appInfoRepository = appInfoRepository;

  final AppDatabase _database;
  final ImportValidator _importValidator;
  final PeopleRepository _peopleRepository;
  final CategoryRepository _categoryRepository;
  final TransactionRepository _transactionRepository;
  final SettingsRepository _settingsRepository;
  final AppInfoRepository _appInfoRepository;

  @override
  Future<RestoreResultModel> restore(String zipFilePath) async {
    final validationResult = await _importValidator.validate(zipFilePath);

    switch (validationResult) {
      case ImportValidationFailure(:final reason, :final message):
        throw BackupImportException(reason: reason, message: message);

      case ImportValidationSuccess(:final bundle):
        try {
          return await _applyBundle(bundle);
        } finally {
          await _deleteQuietly(
            Directory(bundle.attachmentsDirectoryPath).parent.path,
          );
        }
    }
  }

  Future<RestoreResultModel> _applyBundle(ImportBundleModel bundle) async {
    final permanentAttachmentsDirectory =
        await _permanentAttachmentsDirectory();

    // Built via the full constructor rather than copyWith: copyWith's `??`
    // fallback can't distinguish "resolve to null" from "leave unchanged",
    // so it would silently keep the bundle's bare file name (not a real
    // device path) whenever an attachment turns out to be missing.
    final people = [
      for (final person in bundle.people)
        PersonModel(
          id: person.id,
          name: person.name,
          photoPath: await _resolveAttachment(
            fileName: person.photoPath,
            sourceDirectoryPath: bundle.attachmentsDirectoryPath,
            destinationDirectoryPath: permanentAttachmentsDirectory,
          ),
          type: person.type,
          status: person.status,
          avatarSeed: person.avatarSeed,
          displayOrder: person.displayOrder,
          createdAt: person.createdAt,
          updatedAt: person.updatedAt,
        ),
    ];

    final transactions = [
      for (final transaction in bundle.transactions)
        TransactionModel(
          id: transaction.id,
          personId: transaction.personId,
          amount: transaction.amount,
          transactionType: transaction.transactionType,
          categoryId: transaction.categoryId,
          remark: transaction.remark,
          attachmentPath: await _resolveAttachment(
            fileName: transaction.attachmentPath,
            sourceDirectoryPath: bundle.attachmentsDirectoryPath,
            destinationDirectoryPath: permanentAttachmentsDirectory,
          ),
          date: transaction.date,
          createdAt: transaction.createdAt,
          updatedAt: transaction.updatedAt,
        ),
    ];

    await _database.transaction(() async {
      // Children first: both people and categories are referenced by
      // transactions' foreign keys.
      await _transactionRepository.deleteAll();
      await _peopleRepository.deleteAll();
      await _categoryRepository.deleteAll();

      for (final category in bundle.categories) {
        await _categoryRepository.insert(category);
      }
      for (final person in people) {
        await _peopleRepository.insert(person);
      }
      for (final transaction in transactions) {
        await _transactionRepository.insert(transaction);
      }

      await _settingsRepository.update(bundle.settings);
      await _appInfoRepository.recordRestore(DateTime.now());
    });

    return RestoreResultModel(
      restoredAt: DateTime.now(),
      peopleCount: bundle.people.length,
      transactionCount: bundle.transactions.length,
      categoryCount: bundle.categories.length,
    );
  }

  Future<String> _permanentAttachmentsDirectory() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final directory = Directory(
      p.join(documentsDirectory.path, 'attachments'),
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory.path;
  }

  /// Copies the attachment named [fileName] (a bare file name, as parsed
  /// from the bundle by `ImportConverters`) from [sourceDirectoryPath]
  /// into [destinationDirectoryPath], and returns the new absolute path
  /// to write into the restored record.
  ///
  /// Returns null if [fileName] is null, or if the referenced file isn't
  /// actually present in the bundle — the record still restores
  /// correctly, just without that one attachment, rather than failing the
  /// whole restore over a single missing photo.
  Future<String?> _resolveAttachment({
    required String? fileName,
    required String sourceDirectoryPath,
    required String destinationDirectoryPath,
  }) async {
    if (fileName == null) return null;

    final sourceFile = File(p.join(sourceDirectoryPath, fileName));
    if (!await sourceFile.exists()) return null;

    final destinationPath = p.join(destinationDirectoryPath, fileName);
    await sourceFile.copy(destinationPath);
    return destinationPath;
  }

  Future<void> _deleteQuietly(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}

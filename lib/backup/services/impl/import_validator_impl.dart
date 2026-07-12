import 'dart:convert';
import 'dart:io';

import 'package:family_ledger/backup/constants/backup_constants.dart';
import 'package:family_ledger/backup/converters/import_converters.dart';
import 'package:family_ledger/backup/models/import_bundle_model.dart';
import 'package:family_ledger/backup/models/import_validation_result.dart';
import 'package:family_ledger/backup/services/import_validator.dart';
import 'package:family_ledger/export/constants/export_constants.dart';
import 'package:family_ledger/export/models/export_metadata_model.dart';
import 'package:family_ledger/export/services/export_checksum.dart';
import 'package:family_ledger/export/services/zip_archiver.dart';
import 'package:family_ledger/models/category_model.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/models/settings_model.dart';
import 'package:family_ledger/models/transaction_model.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImportValidatorImpl implements ImportValidator {
  ImportValidatorImpl({required ZipArchiver zipArchiver})
    : _zipArchiver = zipArchiver;

  final ZipArchiver _zipArchiver;

  static const List<String> _requiredFiles = [
    ExportConstants.metadataFileName,
    ExportConstants.peopleFileName,
    ExportConstants.categoriesFileName,
    ExportConstants.transactionsFileName,
    ExportConstants.settingsFileName,
    ExportConstants.appInfoFileName,
  ];

  @override
  Future<ImportValidationResult> validate(String zipFilePath) async {
    final extractionDirectoryPath = await _newExtractionDirectory();

    try {
      await _zipArchiver.extractZip(
        zipFilePath: zipFilePath,
        outputDirectoryPath: extractionDirectoryPath,
      );
    } on FileSystemException catch (error) {
      return _fail(
        extractionDirectoryPath,
        _isPermissionError(error)
            ? ImportValidationFailureReason.permissionDenied
            : ImportValidationFailureReason.corruptedArchive,
        _isPermissionError(error)
            ? 'Permission was denied while reading the backup file.'
            : 'The backup file could not be read. It may be corrupted or '
                  'not a valid backup archive.',
      );
    } catch (_) {
      return _fail(
        extractionDirectoryPath,
        ImportValidationFailureReason.corruptedArchive,
        'The backup file is not a valid ZIP archive.',
      );
    }

    final missingFiles = [
      for (final fileName in _requiredFiles)
        if (!File(p.join(extractionDirectoryPath, fileName)).existsSync())
          fileName,
    ];
    if (missingFiles.isNotEmpty) {
      return _fail(
        extractionDirectoryPath,
        ImportValidationFailureReason.missingFiles,
        'This backup is missing required file(s): '
        '${missingFiles.join(', ')}.',
      );
    }

    final String metadataText;
    final String peopleText;
    final String categoriesText;
    final String transactionsText;
    final String settingsText;
    final String appInfoText;
    try {
      metadataText = await _readFile(
        extractionDirectoryPath,
        ExportConstants.metadataFileName,
      );
      peopleText = await _readFile(
        extractionDirectoryPath,
        ExportConstants.peopleFileName,
      );
      categoriesText = await _readFile(
        extractionDirectoryPath,
        ExportConstants.categoriesFileName,
      );
      transactionsText = await _readFile(
        extractionDirectoryPath,
        ExportConstants.transactionsFileName,
      );
      settingsText = await _readFile(
        extractionDirectoryPath,
        ExportConstants.settingsFileName,
      );
      appInfoText = await _readFile(
        extractionDirectoryPath,
        ExportConstants.appInfoFileName,
      );
    } on FileSystemException {
      return _fail(
        extractionDirectoryPath,
        ImportValidationFailureReason.permissionDenied,
        'Permission was denied while reading the backup contents.',
      );
    }

    final Object? metadataJson;
    final Object? peopleJson;
    final Object? categoriesJson;
    final Object? transactionsJson;
    final Object? settingsJson;
    final Object? appInfoJson;
    try {
      metadataJson = jsonDecode(metadataText);
      peopleJson = jsonDecode(peopleText);
      categoriesJson = jsonDecode(categoriesText);
      transactionsJson = jsonDecode(transactionsText);
      settingsJson = jsonDecode(settingsText);
      appInfoJson = jsonDecode(appInfoText);
    } on FormatException {
      return _fail(
        extractionDirectoryPath,
        ImportValidationFailureReason.corruptedJson,
        'One or more files in this backup contain invalid JSON.',
      );
    }

    final ExportMetadataModel metadata;
    try {
      metadata = ExportMetadataModel.fromJson(
        metadataJson as Map<String, dynamic>,
      );
    } catch (_) {
      return _fail(
        extractionDirectoryPath,
        ImportValidationFailureReason.corruptedJson,
        'metadata.json is missing required fields.',
      );
    }

    if (!BackupConstants.supportedExportFormatVersions.contains(
      metadata.exportFormatVersion,
    )) {
      return _fail(
        extractionDirectoryPath,
        ImportValidationFailureReason.unsupportedFormatVersion,
        'This backup uses export format version '
        '${metadata.exportFormatVersion}, which this version of the app '
        "doesn't support importing.",
      );
    }

    final recomputedChecksum = ExportChecksum.combinedSha256([
      jsonEncode(peopleJson),
      jsonEncode(categoriesJson),
      jsonEncode(transactionsJson),
      jsonEncode(settingsJson),
      jsonEncode(appInfoJson),
    ]);
    if (recomputedChecksum != metadata.checksum) {
      return _fail(
        extractionDirectoryPath,
        ImportValidationFailureReason.checksumMismatch,
        'This backup failed its integrity check — its contents may have '
        'been altered or corrupted after it was created.',
      );
    }

    final List<Map<String, dynamic>> peopleList;
    final List<Map<String, dynamic>> categoriesList;
    final List<Map<String, dynamic>> transactionsList;
    try {
      peopleList = (peopleJson as List<dynamic>).cast<Map<String, dynamic>>();
      categoriesList = (categoriesJson as List<dynamic>)
          .cast<Map<String, dynamic>>();
      transactionsList = (transactionsJson as List<dynamic>)
          .cast<Map<String, dynamic>>();
    } catch (_) {
      return _fail(
        extractionDirectoryPath,
        ImportValidationFailureReason.corruptedJson,
        'people.json, categories.json, or transactions.json is not a '
        'list of records as expected.',
      );
    }

    // Conversion can throw beyond FormatException: JSON that is
    // well-formed but wrongly typed (a string where a number belongs, a
    // missing key, an unknown enum name) surfaces as TypeError /
    // ArgumentError. All of it means the same thing to the user —
    // unreadable backup — and none of it may escape as a crash.
    final List<PersonModel> people;
    final List<CategoryModel> categories;
    final List<TransactionModel> transactions;
    final SettingsModel settings;
    try {
      people = peopleList.map(ImportConverters.toPerson).toList();
      categories = categoriesList.map(ImportConverters.toCategory).toList();
      transactions = transactionsList
          .map(ImportConverters.toTransaction)
          .toList();
      settings = ImportConverters.toSettings(
        settingsJson as Map<String, dynamic>,
      );
    } catch (_) {
      return _fail(
        extractionDirectoryPath,
        ImportValidationFailureReason.corruptedJson,
        'This backup contains records with missing or wrongly-typed '
        'fields and could not be read.',
      );
    }

    final personIds = people.map((person) => person.id).toSet();
    final categoryIds = categories.map((category) => category.id).toSet();
    final transactionIds = transactions
        .map((transaction) => transaction.id)
        .toSet();
    if (personIds.length != people.length ||
        categoryIds.length != categories.length ||
        transactionIds.length != transactions.length) {
      return _fail(
        extractionDirectoryPath,
        ImportValidationFailureReason.duplicateIdentifiers,
        'This backup contains duplicate record identifiers.',
      );
    }

    final hasDanglingReference = transactions.any(
      (transaction) =>
          !personIds.contains(transaction.personId) ||
          (transaction.categoryId != null &&
              !categoryIds.contains(transaction.categoryId)),
    );
    if (hasDanglingReference) {
      return _fail(
        extractionDirectoryPath,
        ImportValidationFailureReason.danglingReference,
        'This backup contains transactions that reference a person or '
        "category that doesn't exist in the same backup.",
      );
    }

    return ImportValidationSuccess(
      ImportBundleModel(
        metadata: metadata,
        people: people,
        categories: categories,
        transactions: transactions,
        settings: settings,
        attachmentsDirectoryPath: p.join(
          extractionDirectoryPath,
          ExportConstants.attachmentsFolderName,
        ),
      ),
    );
  }

  Future<String> _newExtractionDirectory() async {
    final tempDirectory = await getTemporaryDirectory();
    final path = p.join(
      tempDirectory.path,
      'family_ledger_import_${DateTime.now().microsecondsSinceEpoch}',
    );
    await Directory(path).create(recursive: true);
    return path;
  }

  Future<String> _readFile(String directoryPath, String fileName) {
    return File(p.join(directoryPath, fileName)).readAsString();
  }

  bool _isPermissionError(FileSystemException error) {
    final message = error.message.toLowerCase();
    final osMessage = error.osError?.message.toLowerCase() ?? '';
    return message.contains('permission') || osMessage.contains('permission');
  }

  Future<ImportValidationResult> _fail(
    String extractionDirectoryPath,
    ImportValidationFailureReason reason,
    String message,
  ) async {
    await _deleteQuietly(extractionDirectoryPath);
    return ImportValidationFailure(reason: reason, message: message);
  }

  Future<void> _deleteQuietly(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}

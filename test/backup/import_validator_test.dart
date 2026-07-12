import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:family_ledger/backup/models/import_validation_result.dart';
import 'package:family_ledger/backup/services/impl/import_validator_impl.dart';
import 'package:family_ledger/core/constants/app_constants.dart';
import 'package:family_ledger/export/constants/export_constants.dart';
import 'package:family_ledger/export/services/export_checksum.dart';
import 'package:family_ledger/export/services/impl/zip_archiver_impl.dart';
import 'package:family_ledger/export/services/zip_archiver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../helpers/fake_path_provider.dart';

void main() {
  late Directory tempRoot;
  late ZipArchiver zipArchiver;
  late ImportValidatorImpl validator;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('import_validator_test');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempRoot.path);
    zipArchiver = const ZipArchiverImpl();
    validator = ImportValidatorImpl(zipArchiver: zipArchiver);
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  group('ImportValidator', () {
    test('accepts a well-formed, checksum-correct bundle', () async {
      final zipPath = await _writeBundleZip(tempRoot);

      final result = await validator.validate(zipPath);

      expect(result, isA<ImportValidationSuccess>());
      final bundle = (result as ImportValidationSuccess).bundle;
      expect(bundle.people, hasLength(1));
      expect(bundle.categories, hasLength(1));
      expect(bundle.transactions, hasLength(1));
    });

    test('rejects a file that is not a valid ZIP', () async {
      final badZip = File(p.join(tempRoot.path, 'garbage.zip'));
      await badZip.writeAsBytes([1, 2, 3, 4, 5]);

      final result = await validator.validate(badZip.path);

      expect(result, isA<ImportValidationFailure>());
      expect(
        (result as ImportValidationFailure).reason,
        ImportValidationFailureReason.corruptedArchive,
      );
    });

    test('rejects a bundle missing a required file', () async {
      final zipPath = await _writeBundleZip(
        tempRoot,
        omitFile: ExportConstants.settingsFileName,
      );

      final result = await validator.validate(zipPath);

      expect(
        (result as ImportValidationFailure).reason,
        ImportValidationFailureReason.missingFiles,
      );
    });

    test('rejects a bundle with invalid JSON', () async {
      final zipPath = await _writeBundleZip(
        tempRoot,
        fileOverrides: {ExportConstants.peopleFileName: '{not valid json'},
      );

      final result = await validator.validate(zipPath);

      expect(
        (result as ImportValidationFailure).reason,
        ImportValidationFailureReason.corruptedJson,
      );
    });

    test(
      'rejects well-formed JSON whose fields are wrongly typed, without '
      'crashing',
      () async {
        final zipPath = await _writeBundleZip(
          tempRoot,
          peopleOverride: [
            {..._person, 'personIdentifier': 'seven'}, // string, not int
          ],
        );

        final result = await validator.validate(zipPath);

        expect(
          (result as ImportValidationFailure).reason,
          ImportValidationFailureReason.corruptedJson,
        );

        // The temp extraction folder must have been cleaned up on this
        // path too — the original bug leaked it by throwing past _fail.
        final leftovers = tempRoot
            .listSync()
            .whereType<Directory>()
            .where(
              (dir) =>
                  p.basename(dir.path).startsWith('family_ledger_import_'),
            );
        expect(leftovers, isEmpty);
      },
    );

    test('rejects an unknown enum value in a record field', () async {
      final zipPath = await _writeBundleZip(
        tempRoot,
        transactionsOverride: [
          {..._transaction, 'transactionType': 'notARealType'},
        ],
      );

      final result = await validator.validate(zipPath);

      expect(
        (result as ImportValidationFailure).reason,
        ImportValidationFailureReason.corruptedJson,
      );
    });

    test('rejects an unsupported export format version', () async {
      final zipPath = await _writeBundleZip(
        tempRoot,
        metadataOverrides: {'exportFormatVersion': 999},
      );

      final result = await validator.validate(zipPath);

      expect(
        (result as ImportValidationFailure).reason,
        ImportValidationFailureReason.unsupportedFormatVersion,
      );
    });

    test('rejects a bundle whose checksum does not match', () async {
      final zipPath = await _writeBundleZip(
        tempRoot,
        // Changed after the checksum was computed, so it no longer
        // matches metadata.json's recorded checksum.
        fileOverrides: {
          ExportConstants.peopleFileName: jsonEncode([
            {..._person, 'fullName': 'Tampered Name'},
          ]),
        },
        recomputeChecksum: false,
      );

      final result = await validator.validate(zipPath);

      expect(
        (result as ImportValidationFailure).reason,
        ImportValidationFailureReason.checksumMismatch,
      );
    });

    test('rejects duplicate identifiers within a file', () async {
      final zipPath = await _writeBundleZip(
        tempRoot,
        peopleOverride: [_person, _person],
      );

      final result = await validator.validate(zipPath);

      expect(
        (result as ImportValidationFailure).reason,
        ImportValidationFailureReason.duplicateIdentifiers,
      );
    });

    test('rejects a transaction referencing a non-existent person', () async {
      final zipPath = await _writeBundleZip(
        tempRoot,
        transactionsOverride: [
          {..._transaction, 'personIdentifier': 999},
        ],
      );

      final result = await validator.validate(zipPath);

      expect(
        (result as ImportValidationFailure).reason,
        ImportValidationFailureReason.danglingReference,
      );
    });

    test('rejects an archive whose entries escape the extraction folder',
        () async {
      // A hand-built malicious archive: one entry tries to climb out of
      // the extraction directory with a relative path.
      final archive = Archive()
        ..addFile(
          ArchiveFile('../escaped.txt', 11, utf8.encode('escaped!!!!')),
        );
      final zipPath = p.join(tempRoot.path, 'malicious.zip');
      await File(zipPath).writeAsBytes(ZipEncoder().encode(archive)!);

      final result = await validator.validate(zipPath);

      expect(
        (result as ImportValidationFailure).reason,
        ImportValidationFailureReason.corruptedArchive,
      );
      // The traversal target must not exist anywhere: extraction dirs
      // live directly under tempRoot, so a successful escape would have
      // landed the file in tempRoot itself.
      expect(File(p.join(tempRoot.path, 'escaped.txt')).existsSync(), isFalse);
      expect(
        File(p.join(tempRoot.parent.path, 'escaped.txt')).existsSync(),
        isFalse,
      );
    });

    test('cleans up its temp extraction folder on failure', () async {
      final badZip = File(p.join(tempRoot.path, 'garbage.zip'));
      await badZip.writeAsBytes([1, 2, 3, 4, 5]);

      await validator.validate(badZip.path);

      final leftoverEntries = tempRoot
          .listSync()
          .whereType<Directory>()
          .where((dir) => p.basename(dir.path).startsWith('family_ledger_import_'));
      expect(leftoverEntries, isEmpty);
    });
  });
}

const _person = {
  'personIdentifier': 1,
  'fullName': 'Nani',
  'contactType': 'permanent',
  'lifecycleStatus': 'active',
  'photographFileName': null,
  'sortPosition': 0,
  'avatarColorSeed': null,
  'recordCreatedAt': '2026-01-01T00:00:00.000',
  'recordUpdatedAt': '2026-01-01T00:00:00.000',
};

const _category = {
  'categoryIdentifier': 1,
  'categoryName': 'Groceries',
  'iconIdentifier': 'shopping_cart',
  'colorHexCode': '#FF9800',
  'isSystemDefinedDefault': true,
  'recordCreatedAt': '2026-01-01T00:00:00.000',
};

const _transaction = {
  'transactionIdentifier': 1,
  'personIdentifier': 1,
  'categoryIdentifier': 1,
  'transactionType': 'advanceReceived',
  'amount': 500.0,
  'remark': null,
  'attachmentFileName': null,
  'transactionDate': '2026-01-01T00:00:00.000',
  'runningBalance': 500.0,
  'recordCreatedAt': '2026-01-01T00:00:00.000',
  'recordUpdatedAt': '2026-01-01T00:00:00.000',
};

const _settings = {
  'themePreference': 'system',
  'currencyCode': 'INR',
  'automaticBackupFrequency': 'never',
};

const _appInfo = {
  'installationIdentifier': 'install-123',
  'databaseSchemaVersion': 5,
  'applicationVersion': '1.0.0+1',
  'deviceName': null,
  'lastBackupCompletedAt': null,
  'lastRestoreCompletedAt': null,
  'recordCreatedAt': '2026-01-01T00:00:00.000',
};

/// Builds a minimal, valid backup `.zip` under [root] and returns its
/// path, for [ImportValidator] to be pointed at directly.
///
/// [fileOverrides] replaces a named file's raw text content outright
/// (used to inject invalid JSON). [peopleOverride]/[transactionsOverride]
/// replace just that file's record list, still JSON-encoded normally.
/// [metadataOverrides] merges into metadata.json after everything else is
/// computed, so it can override fields like exportFormatVersion without
/// needing to also fix up the checksum. Unless [recomputeChecksum] is
/// false, the checksum always matches whatever people/categories/
/// transactions/settings/app_info content ends up in the bundle.
Future<String> _writeBundleZip(
  Directory root, {
  String? omitFile,
  Map<String, String>? fileOverrides,
  Map<String, dynamic>? metadataOverrides,
  List<Map<String, dynamic>>? peopleOverride,
  List<Map<String, dynamic>>? transactionsOverride,
  bool recomputeChecksum = true,
}) async {
  final stagingDir = await Directory(
    p.join(root.path, 'staging_${DateTime.now().microsecondsSinceEpoch}'),
  ).create(recursive: true);

  final peopleJson = peopleOverride ?? [_person];
  final categoriesJson = [_category];
  final transactionsJson = transactionsOverride ?? [_transaction];
  const settingsJson = _settings;
  const appInfoJson = _appInfo;

  final peopleText =
      fileOverrides?[ExportConstants.peopleFileName] ??
      jsonEncode(peopleJson);
  final categoriesText =
      fileOverrides?[ExportConstants.categoriesFileName] ??
      jsonEncode(categoriesJson);
  final transactionsText =
      fileOverrides?[ExportConstants.transactionsFileName] ??
      jsonEncode(transactionsJson);
  final settingsText =
      fileOverrides?[ExportConstants.settingsFileName] ??
      jsonEncode(settingsJson);
  final appInfoText =
      fileOverrides?[ExportConstants.appInfoFileName] ??
      jsonEncode(appInfoJson);

  // Canonicalizes text that's valid JSON, so the checksum matches what
  // ImportValidator recomputes from the same files; passes deliberately
  // invalid JSON through as-is; that fixture is only ever used in a test
  // expecting corruptedJson, which is checked before the checksum, so
  // its exact value there doesn't matter.
  String canonicalize(String text) {
    try {
      return jsonEncode(jsonDecode(text));
    } on FormatException {
      return text;
    }
  }

  final checksum = recomputeChecksum
      ? ExportChecksum.combinedSha256([
          canonicalize(peopleText),
          canonicalize(categoriesText),
          canonicalize(transactionsText),
          canonicalize(settingsText),
          canonicalize(appInfoText),
        ])
      : 'stale-checksum-does-not-match';

  final metadata = {
    'exportFormatVersion': ExportConstants.exportFormatVersion,
    'exportGeneratedAt': DateTime(2026, 1, 1).toIso8601String(),
    'applicationVersion': AppConstants.appVersion,
    'databaseSchemaVersion': AppConstants.databaseSchemaVersion,
    'installationIdentifier': 'install-123',
    'deviceName': null,
    'timezone': 'IST (UTC+05:30)',
    'currencyCode': 'INR',
    'totalPeopleCount': peopleJson.length,
    'totalTransactionCount': transactionsJson.length,
    'totalCategoryCount': categoriesJson.length,
    'checksum': checksum,
    'includedFiles': <dynamic>[],
    ...?metadataOverrides,
  };

  final files = <String, String>{
    ExportConstants.metadataFileName: jsonEncode(metadata),
    ExportConstants.peopleFileName: peopleText,
    ExportConstants.categoriesFileName: categoriesText,
    ExportConstants.transactionsFileName: transactionsText,
    ExportConstants.settingsFileName: settingsText,
    ExportConstants.appInfoFileName: appInfoText,
  };

  for (final entry in files.entries) {
    if (entry.key == omitFile) continue;
    await File(
      p.join(stagingDir.path, entry.key),
    ).writeAsString(entry.value);
  }

  final zipPath = p.join(
    root.path,
    'bundle_${DateTime.now().microsecondsSinceEpoch}.zip',
  );
  await const ZipArchiverImpl().zipDirectory(
    sourceDirectoryPath: stagingDir.path,
    outputZipPath: zipPath,
  );

  return zipPath;
}

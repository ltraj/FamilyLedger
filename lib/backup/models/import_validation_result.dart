import 'package:family_ledger/backup/models/import_bundle_model.dart';

/// Why an import bundle failed validation.
///
/// Distinguishing these lets the UI show a specific, actionable message
/// instead of one generic "import failed" error.
enum ImportValidationFailureReason {
  /// The file at the chosen path isn't a valid ZIP archive, or couldn't be
  /// read at all.
  corruptedArchive,

  /// One or more required files (`metadata.json`, `people.json`,
  /// `categories.json`, `transactions.json`, `settings.json`,
  /// `app_info.json`) is missing from the archive.
  missingFiles,

  /// A required file exists but isn't valid JSON.
  corruptedJson,

  /// `metadata.json`'s `exportFormatVersion` isn't one this app build
  /// knows how to import (see
  /// [BackupConstants.supportedExportFormatVersions]).
  unsupportedFormatVersion,

  /// The checksum recomputed from the extracted files doesn't match the
  /// one recorded in `metadata.json` — the bundle was altered or
  /// corrupted after export.
  checksumMismatch,

  /// The same identifier appears more than once within `people.json`,
  /// `categories.json`, or `transactions.json`.
  duplicateIdentifiers,

  /// A transaction references a `personIdentifier` or `categoryIdentifier`
  /// that doesn't exist anywhere in `people.json`/`categories.json`.
  danglingReference,

  /// The device denied access while reading the chosen file or folder.
  permissionDenied,
}

/// Outcome of validating a candidate backup bundle, before any database
/// write happens.
///
/// A sealed type rather than a boolean + nullable fields, so callers are
/// forced by the compiler to handle both cases explicitly (see the
/// `switch` in `RestoreService`) instead of forgetting to check a flag.
sealed class ImportValidationResult {
  const ImportValidationResult();
}

class ImportValidationSuccess extends ImportValidationResult {
  const ImportValidationSuccess(this.bundle);

  final ImportBundleModel bundle;
}

class ImportValidationFailure extends ImportValidationResult {
  const ImportValidationFailure({required this.reason, required this.message});

  final ImportValidationFailureReason reason;

  /// Human-readable explanation, safe to show directly in the UI.
  final String message;
}

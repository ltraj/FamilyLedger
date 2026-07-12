import 'package:family_ledger/backup/models/import_validation_result.dart';

/// Validates a candidate backup `.zip` before any of its data touches the
/// database.
///
/// Extracts the archive to a temporary folder, checks every required file
/// is present and parses as JSON, checks the export format version is one
/// this build understands, recomputes the checksum recorded in
/// `metadata.json`, and checks for duplicate or dangling record
/// identifiers. Only if every check passes does it hand back a fully
/// parsed [ImportBundleModel] — never a partially-checked one.
///
/// On [ImportValidationSuccess], the caller (normally [RestoreService])
/// takes ownership of the temporary extraction folder referenced by
/// `bundle.attachmentsDirectoryPath` and is responsible for deleting its
/// parent once done reading attachments from it. On
/// [ImportValidationFailure], this validator deletes that folder itself —
/// callers never need to clean up after a failed validation.
///
/// Implementation: [ImportValidatorImpl] in
/// `lib/backup/services/impl/import_validator_impl.dart`.
abstract interface class ImportValidator {
  Future<ImportValidationResult> validate(String zipFilePath);
}

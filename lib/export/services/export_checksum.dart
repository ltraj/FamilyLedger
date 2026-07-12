import 'dart:convert';

import 'package:crypto/crypto.dart';

/// SHA-256 checksums for verifying a backup's core data wasn't corrupted
/// or altered in transit (copied to a USB drive, uploaded, re-downloaded,
/// ...).
///
/// Covers only the primary data files — people.json, categories.json,
/// transactions.json, settings.json, app_info.json, concatenated in that
/// fixed order — not metadata.json itself (which can't hash its own
/// contents), and not generated/derived files (schema.json, README.md,
/// ledger.csv), which are documentation rather than primary data.
abstract final class ExportChecksum {
  /// Combines [orderedFileContents] (already-serialized JSON strings, in
  /// the fixed order documented on this class) into one SHA-256 hex
  /// digest.
  static String combinedSha256(List<String> orderedFileContents) {
    final combined = orderedFileContents.join('\n');
    return sha256.convert(utf8.encode(combined)).toString();
  }
}

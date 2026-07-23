/// Selects which old backup files to delete after a new automatic backup —
/// the pure core of rotation, separated from filesystem I/O so the
/// deletion decision can be exhaustively unit-tested with plain filename
/// lists.
///
/// Deletion is permanent (no recycle bin), so this class is deliberately
/// paranoid, in this order:
///
/// 1. Only file *names* are considered — the caller lists one directory
///    (the user's granted backup folder) and joins returned names back
///    onto that same directory, so nothing outside it can ever be
///    touched.
/// 2. Only names matching this app's own backup pattern
///    (`FamilyLedger_Backup_YYYY-MM-DD_HH-mm.zip`, the exact shape
///    `BackupConstants.backupFileName` produces — a test pins the two
///    together) are candidates. The user's other files, whatever they
///    are, are invisible to rotation.
/// 3. The just-created backup is removed from the candidate set before
///    any sorting, so no ordering bug — clock skew, duplicate
///    timestamps — can ever select it.
/// 4. The newest [keepCount] backups (just-created included) are kept;
///    only matching files beyond those are returned for deletion.
abstract final class BackupRotationPolicy {
  /// How many backups to keep, newest first, counting the one just
  /// written.
  static const int keepCount = 2;

  /// Mirrors `BackupConstants.backupFileName`'s output exactly: fixed
  /// prefix, zero-padded date/time, `.zip`. Anchored on both ends so a
  /// name merely *containing* a backup-like substring never matches.
  static final RegExp _backupFileNamePattern = RegExp(
    r'^FamilyLedger_Backup_\d{4}-\d{2}-\d{2}_\d{2}-\d{2}\.zip$',
  );

  /// Whether [fileName] is one of this app's own backup archives.
  static bool isAppBackupFileName(String fileName) {
    return _backupFileNamePattern.hasMatch(fileName);
  }

  /// The file names that should be deleted, given every file name found
  /// in the backup folder and the name of the backup written moments ago.
  ///
  /// Sorting is by the timestamp embedded in the name: because every
  /// component is zero-padded, descending lexicographic order *is*
  /// descending chronological order, with no date parsing (and therefore
  /// no parse failure) possible on a name that already matched the
  /// pattern. Two backups in the same minute produce the same name and
  /// overwrite each other on disk, so ties cannot arise.
  static List<String> selectFilesToDelete({
    required Iterable<String> fileNames,
    required String justCreatedFileName,
  }) {
    final candidates = fileNames.where(isAppBackupFileName).toSet()
      ..remove(justCreatedFileName);

    final newestFirst = candidates.toList()..sort((a, b) => b.compareTo(a));

    // The just-created backup always occupies one keep slot, whether or
    // not it appeared in [fileNames].
    const keepFromOlder = keepCount - 1;
    if (newestFirst.length <= keepFromOlder) return const [];
    return newestFirst.sublist(keepFromOlder);
  }
}

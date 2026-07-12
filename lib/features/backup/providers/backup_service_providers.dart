import 'package:family_ledger/backup/services/backup_service.dart';
import 'package:family_ledger/backup/services/restore_service.dart';
import 'package:family_ledger/core/services/service_locator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [BackupService] from the service locator.
final backupServiceProvider = Provider<BackupService>(
  (ref) => sl<BackupService>(),
);

/// Provides the [RestoreService] from the service locator.
final restoreServiceProvider = Provider<RestoreService>(
  (ref) => sl<RestoreService>(),
);

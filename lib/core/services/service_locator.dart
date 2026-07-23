import 'package:family_ledger/backup/services/auto_backup_service.dart';
import 'package:family_ledger/backup/services/backup_service.dart';
import 'package:family_ledger/backup/services/impl/auto_backup_service_impl.dart';
import 'package:family_ledger/backup/services/impl/backup_service_impl.dart';
import 'package:family_ledger/backup/services/impl/import_validator_impl.dart';
import 'package:family_ledger/backup/services/impl/restore_service_impl.dart';
import 'package:family_ledger/backup/services/import_validator.dart';
import 'package:family_ledger/backup/services/restore_service.dart';
import 'package:family_ledger/core/database/app_database.dart';
import 'package:family_ledger/export/services/export_data_collector.dart';
import 'package:family_ledger/export/services/export_file_writer.dart';
import 'package:family_ledger/export/services/export_service.dart';
import 'package:family_ledger/export/services/impl/export_data_collector_impl.dart';
import 'package:family_ledger/export/services/impl/export_file_writer_impl.dart';
import 'package:family_ledger/export/services/impl/export_service_impl.dart';
import 'package:family_ledger/export/services/impl/zip_archiver_impl.dart';
import 'package:family_ledger/export/services/zip_archiver.dart';
import 'package:family_ledger/repositories/app_info_repository.dart';
import 'package:family_ledger/repositories/backup_repository.dart';
import 'package:family_ledger/repositories/category_repository.dart';
import 'package:family_ledger/repositories/impl/app_info_repository_impl.dart';
import 'package:family_ledger/repositories/impl/backup_repository_impl.dart';
import 'package:family_ledger/repositories/impl/category_repository_impl.dart';
import 'package:family_ledger/repositories/impl/people_repository_impl.dart';
import 'package:family_ledger/repositories/impl/settings_repository_impl.dart';
import 'package:family_ledger/repositories/impl/transaction_repository_impl.dart';
import 'package:family_ledger/repositories/people_repository.dart';
import 'package:family_ledger/repositories/settings_repository.dart';
import 'package:family_ledger/repositories/transaction_repository.dart';
import 'package:get_it/get_it.dart';

/// Global service locator instance.
final GetIt sl = GetIt.instance;

/// Registers all dependencies into the service locator.
///
/// Call once during application startup before [runApp].
Future<void> setupServiceLocator() async {
  if (sl.isRegistered<AppDatabase>()) return;

  sl.registerLazySingleton<AppDatabase>(AppDatabase.new);

  sl.registerLazySingleton<PeopleRepository>(
    () => PeopleRepositoryImpl(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<BackupRepository>(
    () => BackupRepositoryImpl(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<AppInfoRepository>(
    () => AppInfoRepositoryImpl(sl<AppDatabase>()),
  );

  sl.registerLazySingleton<ZipArchiver>(ZipArchiverImpl.new);

  sl.registerLazySingleton<ExportDataCollector>(
    () => ExportDataCollectorImpl(
      peopleRepository: sl<PeopleRepository>(),
      categoryRepository: sl<CategoryRepository>(),
      transactionRepository: sl<TransactionRepository>(),
      settingsRepository: sl<SettingsRepository>(),
      appInfoRepository: sl<AppInfoRepository>(),
    ),
  );
  sl.registerLazySingleton<ExportFileWriter>(ExportFileWriterImpl.new);
  sl.registerLazySingleton<ExportService>(
    () => ExportServiceImpl(
      collector: sl<ExportDataCollector>(),
      writer: sl<ExportFileWriter>(),
    ),
  );

  sl.registerLazySingleton<BackupService>(
    () => BackupServiceImpl(
      exportService: sl<ExportService>(),
      zipArchiver: sl<ZipArchiver>(),
      backupRepository: sl<BackupRepository>(),
      appInfoRepository: sl<AppInfoRepository>(),
    ),
  );

  sl.registerLazySingleton<AutoBackupService>(
    () => AutoBackupServiceImpl(
      settingsRepository: sl<SettingsRepository>(),
      appInfoRepository: sl<AppInfoRepository>(),
      backupService: sl<BackupService>(),
    ),
  );

  sl.registerLazySingleton<ImportValidator>(
    () => ImportValidatorImpl(zipArchiver: sl<ZipArchiver>()),
  );
  sl.registerLazySingleton<RestoreService>(
    () => RestoreServiceImpl(
      database: sl<AppDatabase>(),
      importValidator: sl<ImportValidator>(),
      peopleRepository: sl<PeopleRepository>(),
      categoryRepository: sl<CategoryRepository>(),
      transactionRepository: sl<TransactionRepository>(),
      settingsRepository: sl<SettingsRepository>(),
      appInfoRepository: sl<AppInfoRepository>(),
    ),
  );
}

/// Tears down all registered dependencies. Useful for testing.
Future<void> resetServiceLocator() async {
  if (sl.isRegistered<AppDatabase>()) {
    await sl<AppDatabase>().close();
  }
  await sl.reset();
}

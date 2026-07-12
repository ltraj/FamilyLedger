import 'package:family_ledger/core/database/app_database.dart';
import 'package:family_ledger/repositories/impl/app_info_repository_impl.dart';
import 'package:family_ledger/repositories/impl/backup_repository_impl.dart';
import 'package:family_ledger/repositories/impl/category_repository_impl.dart';
import 'package:family_ledger/repositories/impl/people_repository_impl.dart';
import 'package:family_ledger/repositories/impl/settings_repository_impl.dart';
import 'package:family_ledger/repositories/impl/transaction_repository_impl.dart';

/// Holds repository instances backed by a shared test database.
class TestRepositories {
  TestRepositories(this.database)
      : people = PeopleRepositoryImpl(database),
        categories = CategoryRepositoryImpl(database),
        transactions = TransactionRepositoryImpl(database),
        settings = SettingsRepositoryImpl(database),
        backups = BackupRepositoryImpl(database),
        appInfo = AppInfoRepositoryImpl(database);

  final AppDatabase database;
  final PeopleRepositoryImpl people;
  final CategoryRepositoryImpl categories;
  final TransactionRepositoryImpl transactions;
  final SettingsRepositoryImpl settings;
  final BackupRepositoryImpl backups;
  final AppInfoRepositoryImpl appInfo;

  Future<void> close() => database.close();
}

import 'package:family_ledger/core/services/service_locator.dart';
import 'package:family_ledger/models/category_model.dart';
import 'package:family_ledger/models/transaction_model.dart';
import 'package:family_ledger/repositories/app_info_repository.dart';
import 'package:family_ledger/repositories/backup_repository.dart';
import 'package:family_ledger/repositories/category_repository.dart';
import 'package:family_ledger/repositories/people_repository.dart';
import 'package:family_ledger/repositories/settings_repository.dart';
import 'package:family_ledger/repositories/transaction_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [PeopleRepository] from the service locator.
final peopleRepositoryProvider = Provider<PeopleRepository>(
  (ref) => sl<PeopleRepository>(),
);

/// Provides the [CategoryRepository] from the service locator.
final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => sl<CategoryRepository>(),
);

/// One-shot list of every category (default and custom).
///
/// Categories aren't mutated from any screen built so far, so a plain
/// [FutureProvider] is enough — no need for a reactive stream the way
/// transactions have. If a future category-management screen starts
/// mutating categories out from under other screens, this should become
/// a [StreamProvider] backed by a `CategoryRepository.watchAll()`, the
/// same way [transactionsStreamProvider] upgraded [TransactionRepository].
final categoriesListProvider = FutureProvider<List<CategoryModel>>(
  (ref) => ref.watch(categoryRepositoryProvider).getAll(),
);

/// Provides the [TransactionRepository] from the service locator.
final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => sl<TransactionRepository>(),
);

/// Reactive stream of every transaction, shared across every feature that
/// derives data from transactions (People today; Transactions and
/// Dashboard in future phases).
///
/// Backed by [TransactionRepository.watchAll], so it re-emits whenever the
/// `transactions` table changes anywhere in the app — no matter which
/// screen, view model, or future module made the change. Any provider
/// that watches this (typically via `ref.watch(transactionsStreamProvider
/// .future)` from inside another async provider) rebuilds itself
/// automatically when transactions change, instead of needing to be told
/// to `invalidate()` by whichever code happened to cause the change.
final transactionsStreamProvider = StreamProvider<List<TransactionModel>>(
  (ref) => ref.watch(transactionRepositoryProvider).watchAll(),
);

/// Reactive stream of a single person's transactions.
///
/// Prefer this over filtering [transactionsStreamProvider] client-side
/// when a screen only cares about one person (the Transaction screen):
/// it's backed by [TransactionRepository.watchByPersonId], a query scoped
/// to that person at the database level, so it doesn't re-run or re-emit
/// for every other person's transaction activity the way filtering the
/// whole-table stream would.
///
/// `autoDispose`, unlike [transactionsStreamProvider]: that one is a
/// single app-wide stream shared by always-alive tabs, but this is a
/// family — without autoDispose, every person whose screen was ever
/// opened would leave a live database watch stream running for the rest
/// of the app's lifetime.
final personTransactionsStreamProvider =
    StreamProvider.autoDispose.family<List<TransactionModel>, int>(
      (ref, personId) =>
          ref.watch(transactionRepositoryProvider).watchByPersonId(personId),
    );

/// Provides the [SettingsRepository] from the service locator.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => sl<SettingsRepository>(),
);

/// Provides the [BackupRepository] from the service locator.
final backupRepositoryProvider = Provider<BackupRepository>(
  (ref) => sl<BackupRepository>(),
);

/// Provides the [AppInfoRepository] from the service locator.
final appInfoRepositoryProvider = Provider<AppInfoRepository>(
  (ref) => sl<AppInfoRepository>(),
);

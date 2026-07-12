import 'package:drift/drift.dart';
import 'package:family_ledger/core/database/app_database.dart';
import 'package:family_ledger/core/database/mappers/entity_mappers.dart';
import 'package:family_ledger/core/utils/balance_calculator.dart';
import 'package:family_ledger/models/transaction_model.dart';
import 'package:family_ledger/repositories/transaction_repository.dart';

/// Drift-backed implementation of [TransactionRepository].
class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<List<TransactionModel>> getAll() async {
    final entities =
        await (_database.select(_database.transactions)..orderBy([
              (transaction) => OrderingTerm.desc(transaction.date),
              (transaction) => OrderingTerm.desc(transaction.id),
            ]))
            .get();

    return entities.map(EntityMappers.toTransaction).toList();
  }

  @override
  Future<List<TransactionModel>> getByPersonId(int personId) async {
    final entities =
        await (_database.select(_database.transactions)
              ..where((transaction) => transaction.personId.equals(personId))
              ..orderBy([
                (transaction) => OrderingTerm.desc(transaction.date),
                (transaction) => OrderingTerm.desc(transaction.id),
              ]))
            .get();

    return entities.map(EntityMappers.toTransaction).toList();
  }

  @override
  Future<TransactionModel?> getById(int id) async {
    final entity = await (_database.select(
      _database.transactions,
    )..where((transaction) => transaction.id.equals(id))).getSingleOrNull();

    return entity == null ? null : EntityMappers.toTransaction(entity);
  }

  @override
  Future<int> insert(TransactionModel transaction) {
    return _database
        .into(_database.transactions)
        .insert(EntityMappers.toTransactionCompanion(transaction));
  }

  @override
  Future<bool> update(TransactionModel transaction) async {
    if (transaction.id == null) return false;

    final rowsAffected =
        await (_database.update(_database.transactions)
              ..where((row) => row.id.equals(transaction.id!)))
            .write(EntityMappers.toTransactionCompanion(transaction));

    return rowsAffected > 0;
  }

  @override
  Future<bool> delete(int id) async {
    final rowsAffected = await (_database.delete(
      _database.transactions,
    )..where((transaction) => transaction.id.equals(id))).go();

    return rowsAffected > 0;
  }

  @override
  Future<void> deleteAll() async {
    await _database.delete(_database.transactions).go();
  }

  @override
  Future<double> calculateBalance(int personId) async {
    final transactions = await getByPersonId(personId);
    return BalanceCalculator.calculateBalance(transactions);
  }

  @override
  Stream<List<TransactionModel>> watchAll() {
    return (_database.select(_database.transactions)..orderBy([
          (transaction) => OrderingTerm.desc(transaction.date),
          (transaction) => OrderingTerm.desc(transaction.id),
        ]))
        .watch()
        .map((entities) => entities.map(EntityMappers.toTransaction).toList());
  }

  @override
  Stream<List<TransactionModel>> watchByPersonId(int personId) {
    return (_database.select(_database.transactions)
          ..where((transaction) => transaction.personId.equals(personId))
          ..orderBy([
            (transaction) => OrderingTerm.desc(transaction.date),
            (transaction) => OrderingTerm.desc(transaction.id),
          ]))
        .watch()
        .map((entities) => entities.map(EntityMappers.toTransaction).toList());
  }
}

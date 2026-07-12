import 'package:drift/native.dart';
import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/core/database/app_database.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/models/transaction_model.dart';
import 'package:family_ledger/repositories/impl/category_repository_impl.dart';
import 'package:family_ledger/repositories/impl/people_repository_impl.dart';
import 'package:family_ledger/repositories/impl/transaction_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late PeopleRepositoryImpl peopleRepository;
  late CategoryRepositoryImpl categoryRepository;
  late TransactionRepositoryImpl transactionRepository;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    peopleRepository = PeopleRepositoryImpl(database);
    categoryRepository = CategoryRepositoryImpl(database);
    transactionRepository = TransactionRepositoryImpl(database);
    await database.customStatement('PRAGMA foreign_keys = ON');
  });

  tearDown(() async {
    await database.close();
  });

  test('seeds default categories and settings on create', () async {
    final categories = await categoryRepository.getAll();
    expect(categories.length, 11);
    expect(categories.every((category) => category.isDefault), isTrue);

    final electricity = categories.firstWhere((c) => c.name == 'Electricity');
    expect(electricity.icon, 'bolt');
  });

  test('archives person without deleting transactions', () async {
    final now = DateTime.now();
    final personId = await peopleRepository.insert(
      PersonModel(
        name: 'Grandmother',
        type: PersonType.permanent,
        status: PersonStatus.active,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final categories = await categoryRepository.getAll();
    final electricity = categories.firstWhere((c) => c.name == 'Electricity');

    await transactionRepository.insert(
      TransactionModel(
        personId: personId,
        amount: 5000,
        transactionType: TransactionType.advanceReceived,
        categoryId: electricity.id,
        date: now,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await peopleRepository.archive(personId);

    final archived = await peopleRepository.getById(personId);
    expect(archived?.status, PersonStatus.archived);

    final transactions = await transactionRepository.getByPersonId(personId);
    expect(transactions, hasLength(1));

    final balance = await transactionRepository.calculateBalance(personId);
    expect(balance, 5000);
  });

  test(
    'deleting category reassigns transactions to the replacement category',
    () async {
      final now = DateTime.now();
      final personId = await peopleRepository.insert(
        PersonModel(
          name: 'Uncle',
          type: PersonType.temporary,
          status: PersonStatus.active,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final categories = await categoryRepository.getAll();
      final wifi = categories.firstWhere((c) => c.name == 'WiFi');
      final other = categories.firstWhere((c) => c.name == 'Other');

      final transactionId = await transactionRepository.insert(
        TransactionModel(
          personId: personId,
          amount: 800,
          transactionType: TransactionType.expensePaid,
          categoryId: wifi.id,
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await categoryRepository.delete(
        wifi.id!,
        replacementCategoryId: other.id!,
      );

      final transaction = await transactionRepository.getById(transactionId);
      expect(transaction, isNotNull);
      expect(transaction!.categoryId, other.id);
    },
  );
}

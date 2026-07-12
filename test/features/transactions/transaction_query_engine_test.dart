import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/features/transactions/models/transaction_date_range.dart';
import 'package:family_ledger/features/transactions/models/transaction_sort_option.dart';
import 'package:family_ledger/features/transactions/utils/transaction_query_engine.dart';
import 'package:family_ledger/models/category_model.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/models/transaction_model.dart';
import 'package:family_ledger/projections/transaction_details.dart';
import 'package:flutter_test/flutter_test.dart';

final _person = PersonModel(
  id: 1,
  name: 'Uncle',
  type: PersonType.temporary,
  status: PersonStatus.active,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

final _wifi = CategoryModel(
  id: 10,
  name: 'WiFi',
  icon: 'wifi',
  color: '#2196F3',
  isDefault: true,
  createdAt: DateTime(2026, 1, 1),
);

final _food = CategoryModel(
  id: 11,
  name: 'Food',
  icon: 'restaurant',
  color: '#FF5722',
  isDefault: true,
  createdAt: DateTime(2026, 1, 1),
);

TransactionDetails _entry({
  required int id,
  double amount = 100,
  TransactionType type = TransactionType.expensePaid,
  CategoryModel? category,
  String? remark,
  DateTime? date,
  double runningBalanceAfter = 0,
}) {
  final effectiveDate = date ?? DateTime(2026, 1, 1);
  return TransactionDetails(
    transaction: TransactionModel(
      id: id,
      personId: _person.id!,
      amount: amount,
      transactionType: type,
      categoryId: category?.id,
      remark: remark,
      date: effectiveDate,
      createdAt: effectiveDate,
      updatedAt: effectiveDate,
    ),
    person: _person,
    category: category,
    runningBalanceAfter: runningBalanceAfter,
  );
}

void main() {
  group('TransactionQueryEngine', () {
    final advance = _entry(
      id: 1,
      amount: 5000,
      type: TransactionType.advanceReceived,
      category: null,
      remark: 'Monthly advance',
      date: DateTime(2026, 1, 1),
      runningBalanceAfter: 5000,
    );
    final electricity = _entry(
      id: 2,
      amount: 850,
      type: TransactionType.expensePaid,
      category: _wifi,
      remark: 'Router bill',
      date: DateTime(2026, 1, 5),
      runningBalanceAfter: 4150,
    );
    final food = _entry(
      id: 3,
      amount: 300,
      type: TransactionType.expensePaid,
      category: _food,
      remark: null,
      date: DateTime(2026, 1, 10),
      runningBalanceAfter: 3850,
    );
    final returned = _entry(
      id: 4,
      amount: 500,
      type: TransactionType.moneyReturned,
      category: null,
      remark: 'Gave some back',
      date: DateTime(2026, 1, 15),
      runningBalanceAfter: 4350,
    );
    final all = [advance, electricity, food, returned];

    test('type filter restricts to the selected TransactionType', () {
      final result = TransactionQueryEngine.apply(
        all,
        searchText: '',
        sort: TransactionSortOption.newest,
        typeFilter: TransactionType.expensePaid,
      );
      expect(result, unorderedEquals([electricity, food]));
    });

    test('null type filter means all types', () {
      final result = TransactionQueryEngine.apply(
        all,
        searchText: '',
        sort: TransactionSortOption.newest,
      );
      expect(result, unorderedEquals(all));
    });

    test('category filter restricts to the selected category', () {
      final result = TransactionQueryEngine.apply(
        all,
        searchText: '',
        sort: TransactionSortOption.newest,
        categoryFilter: _wifi.id,
      );
      expect(result, [electricity]);
    });

    test('date range filter is inclusive of both endpoints', () {
      final result = TransactionQueryEngine.apply(
        all,
        searchText: '',
        sort: TransactionSortOption.newest,
        dateRange: TransactionDateRange(
          start: DateTime(2026, 1, 5),
          end: DateTime(2026, 1, 10),
        ),
      );
      expect(result, unorderedEquals([electricity, food]));
    });

    test('search matches remark, category name, or amount', () {
      expect(
        TransactionQueryEngine.apply(
          all,
          searchText: 'router',
          sort: TransactionSortOption.newest,
        ),
        [electricity],
      );
      expect(
        TransactionQueryEngine.apply(
          all,
          searchText: 'wifi',
          sort: TransactionSortOption.newest,
        ),
        [electricity],
      );
      expect(
        TransactionQueryEngine.apply(
          all,
          searchText: '5000',
          sort: TransactionSortOption.newest,
        ),
        [advance],
      );
    });

    test('sort: newest and oldest order by date', () {
      final newest = TransactionQueryEngine.apply(
        all,
        searchText: '',
        sort: TransactionSortOption.newest,
      );
      expect(newest, [returned, food, electricity, advance]);

      final oldest = TransactionQueryEngine.apply(
        all,
        searchText: '',
        sort: TransactionSortOption.oldest,
      );
      expect(oldest, [advance, electricity, food, returned]);
    });

    test('sort: highestAmount and lowestAmount order by signed amount', () {
      // Signed: advance +5000, electricity -850, food -300, returned +500.
      final highest = TransactionQueryEngine.apply(
        all,
        searchText: '',
        sort: TransactionSortOption.highestAmount,
      );
      expect(highest, [advance, returned, food, electricity]);

      final lowest = TransactionQueryEngine.apply(
        all,
        searchText: '',
        sort: TransactionSortOption.lowestAmount,
      );
      expect(lowest, [electricity, food, returned, advance]);
    });

    test('filtering and sorting never changes runningBalanceAfter', () {
      final result = TransactionQueryEngine.apply(
        all,
        searchText: '',
        sort: TransactionSortOption.lowestAmount,
        typeFilter: TransactionType.expensePaid,
      );

      final electricityResult = result.firstWhere((d) => d.transaction.id == 2);
      expect(electricityResult.runningBalanceAfter, 4150);
    });
  });
}

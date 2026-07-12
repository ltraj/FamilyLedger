import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/features/reports/models/report_date_preset.dart';
import 'package:family_ledger/features/reports/models/report_filter.dart';
import 'package:family_ledger/features/reports/utils/report_filter_engine.dart';
import 'package:family_ledger/features/transactions/models/transaction_date_range.dart';
import 'package:family_ledger/models/category_model.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 7, 15);

  final nani = PersonModel(
    id: 1,
    name: 'Nani',
    type: PersonType.permanent,
    status: PersonStatus.active,
    createdAt: now,
    updatedAt: now,
  );
  final sudha = PersonModel(
    id: 2,
    name: 'Sudha',
    type: PersonType.permanent,
    status: PersonStatus.active,
    createdAt: now,
    updatedAt: now,
  );
  final electricity = CategoryModel(
    id: 10,
    name: 'Electricity',
    icon: 'bolt',
    color: '#FF9800',
    isDefault: true,
    createdAt: now,
  );

  final peopleById = {1: nani, 2: sudha};
  final categoriesById = {10: electricity};

  TransactionModel transaction({
    required int id,
    int personId = 1,
    int? categoryId,
    TransactionType type = TransactionType.expensePaid,
    String? remark,
    required DateTime date,
  }) {
    return TransactionModel(
      id: id,
      personId: personId,
      amount: 100,
      transactionType: type,
      categoryId: categoryId,
      remark: remark,
      date: date,
      createdAt: date,
      updatedAt: date,
    );
  }

  final transactions = [
    transaction(
      id: 1,
      personId: 1,
      categoryId: 10,
      remark: 'July power bill',
      date: DateTime(2026, 7, 10),
    ),
    transaction(
      id: 2,
      personId: 2,
      type: TransactionType.advanceReceived,
      date: DateTime(2026, 7, 12),
    ),
    transaction(id: 3, personId: 2, date: DateTime(2026, 6, 1)),
  ];

  List<int?> idsFor(ReportFilter filter) {
    return ReportFilterEngine.apply(
      transactions,
      filter: filter,
      peopleById: peopleById,
      categoriesById: categoriesById,
      now: now,
    ).map((transaction) => transaction.id).toList();
  }

  group('ReportFilterEngine', () {
    test('no filters admits everything', () {
      expect(idsFor(const ReportFilter()), [1, 2, 3]);
    });

    test('person filter', () {
      expect(idsFor(const ReportFilter(personId: 2)), [2, 3]);
    });

    test('category filter', () {
      expect(idsFor(const ReportFilter(categoryId: 10)), [1]);
    });

    test('transaction type filter', () {
      expect(
        idsFor(
          const ReportFilter(transactionType: TransactionType.advanceReceived),
        ),
        [2],
      );
    });

    test('date preset filter', () {
      expect(
        idsFor(const ReportFilter(datePreset: ReportDatePreset.thisMonth)),
        [1, 2],
      );
    });

    test('custom date range filter', () {
      final filter = ReportFilter(
        datePreset: ReportDatePreset.custom,
        customRange: TransactionDateRange(
          start: DateTime(2026, 6, 1),
          end: DateTime(2026, 6, 30),
        ),
      );
      expect(idsFor(filter), [3]);
    });

    test('search matches remark, person name, and category name', () {
      expect(idsFor(const ReportFilter(searchText: 'power')), [1]);
      expect(idsFor(const ReportFilter(searchText: 'sudha')), [2, 3]);
      expect(idsFor(const ReportFilter(searchText: 'electr')), [1]);
      expect(idsFor(const ReportFilter(searchText: 'nomatch')), isEmpty);
    });

    test('search is case-insensitive and ignores surrounding whitespace', () {
      expect(idsFor(const ReportFilter(searchText: '  POWER  ')), [1]);
    });

    test('filters combine with AND semantics', () {
      expect(
        idsFor(
          const ReportFilter(
            personId: 2,
            datePreset: ReportDatePreset.thisMonth,
          ),
        ),
        [2],
      );
    });
  });
}

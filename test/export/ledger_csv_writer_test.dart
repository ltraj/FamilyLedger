import 'package:family_ledger/export/models/transaction_export_model.dart';
import 'package:family_ledger/export/services/ledger_csv_writer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LedgerCsvWriter', () {
    test('starts with a UTF-8 BOM and the header row', () {
      final csv = LedgerCsvWriter.write(
        transactions: const [],
        personNamesById: const {},
        categoryNamesById: const {},
      );

      expect(csv, startsWith('﻿Transaction ID,Person,Category,'));
      expect(csv, contains('\r\n'));
    });

    test('writes one row per transaction with resolved names', () {
      final transaction = TransactionExportModel(
        transactionIdentifier: 1,
        personIdentifier: 10,
        categoryIdentifier: 20,
        transactionType: 'advanceReceived',
        amount: 500.5,
        remark: 'Monthly advance',
        transactionDate: DateTime(2026, 3, 4, 9, 30, 15),
        runningBalance: 500.5,
        recordCreatedAt: DateTime(2026, 3, 4, 9, 30, 15),
        recordUpdatedAt: DateTime(2026, 3, 4, 9, 30, 15),
      );

      final csv = LedgerCsvWriter.write(
        transactions: [transaction],
        personNamesById: const {10: 'Nani'},
        categoryNamesById: const {20: 'Groceries'},
      );

      final rows = csv.split('\r\n');
      expect(rows[1], contains('Nani'));
      expect(rows[1], contains('Groceries'));
      expect(rows[1], contains('500.50'));
      expect(rows[1], contains('2026-03-04'));
      expect(rows[1], contains('09:30:15'));
    });

    test('falls back to Unknown for an unresolved person or category', () {
      final transaction = TransactionExportModel(
        transactionIdentifier: 1,
        personIdentifier: 999,
        categoryIdentifier: 999,
        transactionType: 'adjustment',
        amount: -10,
        transactionDate: DateTime(2026, 1, 1),
        recordCreatedAt: DateTime(2026, 1, 1),
        recordUpdatedAt: DateTime(2026, 1, 1),
      );

      final csv = LedgerCsvWriter.write(
        transactions: [transaction],
        personNamesById: const {},
        categoryNamesById: const {},
      );

      expect(csv, contains('Unknown'));
    });

    test('leaves category blank when the transaction has none', () {
      final transaction = TransactionExportModel(
        transactionIdentifier: 1,
        personIdentifier: 10,
        transactionType: 'moneyReturned',
        amount: 100,
        transactionDate: DateTime(2026, 1, 1),
        recordCreatedAt: DateTime(2026, 1, 1),
        recordUpdatedAt: DateTime(2026, 1, 1),
      );

      final csv = LedgerCsvWriter.write(
        transactions: [transaction],
        personNamesById: const {10: 'Nani'},
        categoryNamesById: const {},
      );

      final dataRow = csv.split('\r\n')[1];
      // Person, then an empty category field: "1,Nani,,moneyReturned,...".
      expect(dataRow, contains('Nani,,moneyReturned'));
    });

    test('quotes fields containing commas, quotes, or newlines', () {
      final transaction = TransactionExportModel(
        transactionIdentifier: 1,
        personIdentifier: 10,
        transactionType: 'adjustment',
        amount: 1,
        remark: 'Bought "milk", bread, and eggs',
        transactionDate: DateTime(2026, 1, 1),
        recordCreatedAt: DateTime(2026, 1, 1),
        recordUpdatedAt: DateTime(2026, 1, 1),
      );

      final csv = LedgerCsvWriter.write(
        transactions: [transaction],
        personNamesById: const {10: 'Nani'},
        categoryNamesById: const {},
      );

      expect(csv, contains('"Bought ""milk"", bread, and eggs"'));
    });
  });
}

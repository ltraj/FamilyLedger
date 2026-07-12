import 'package:family_ledger/export/models/transaction_export_model.dart';

/// Renders transactions as `ledger.csv` — one row per transaction, for
/// spreadsheet apps (Excel, LibreOffice, Google Sheets).
///
/// Deliberately denormalized, unlike transactions.json: a spreadsheet has
/// no way to cross-reference a separate people.json/categories.json file,
/// so this resolves person and category names directly into each row.
/// transactions.json stays normalized (identifiers only) for JSON/AI
/// consumers, which *can* follow that cross-reference via schema.json.
abstract final class LedgerCsvWriter {
  static const List<String> columns = [
    'Transaction ID',
    'Person',
    'Category',
    'Transaction Type',
    'Amount',
    'Remark',
    'Date',
    'Time',
    'Running Balance',
    'Created At',
    'Updated At',
  ];

  static String write({
    required List<TransactionExportModel> transactions,
    required Map<int, String> personNamesById,
    required Map<int, String> categoryNamesById,
  }) {
    final buffer = StringBuffer()
      // UTF-8 byte-order mark: without it, Excel on Windows guesses the
      // wrong encoding for any non-ASCII character (accented names,
      // currency symbols in remarks) and shows mojibake instead.
      ..write('﻿')
      ..write(_row(columns));

    for (final transaction in transactions) {
      buffer.write(_row(_rowValues(transaction, personNamesById, categoryNamesById)));
    }

    return buffer.toString();
  }

  static List<String> _rowValues(
    TransactionExportModel transaction,
    Map<int, String> personNamesById,
    Map<int, String> categoryNamesById,
  ) {
    final date = transaction.transactionDate;
    final categoryId = transaction.categoryIdentifier;

    return [
      '${transaction.transactionIdentifier}',
      personNamesById[transaction.personIdentifier] ?? 'Unknown',
      categoryId == null ? '' : (categoryNamesById[categoryId] ?? 'Unknown'),
      transaction.transactionType,
      transaction.amount.toStringAsFixed(2),
      transaction.remark ?? '',
      _formatDate(date),
      _formatTime(date),
      transaction.runningBalance?.toStringAsFixed(2) ?? '',
      transaction.recordCreatedAt.toIso8601String(),
      transaction.recordUpdatedAt.toIso8601String(),
    ];
  }

  /// One CSV row, RFC 4180-quoted, ending in `\r\n` — the format's
  /// specified line ending, for maximum compatibility with spreadsheet
  /// apps that are stricter about it than plain `\n`.
  static String _row(List<String> fields) =>
      '${fields.map(_escape).join(',')}\r\n';

  static String _escape(String field) {
    final needsQuoting =
        field.contains(',') ||
        field.contains('"') ||
        field.contains('\n') ||
        field.contains('\r');
    if (!needsQuoting) return field;
    return '"${field.replaceAll('"', '""')}"';
  }

  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}

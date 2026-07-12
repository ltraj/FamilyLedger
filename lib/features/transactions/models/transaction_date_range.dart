/// An inclusive date range (calendar days only; time of day is ignored)
/// used to filter transactions.
///
/// Deliberately independent of `package:flutter/material.dart`'s
/// `DateTimeRange` so this model — and the query engine that uses it —
/// stays framework-agnostic and unit-testable without a widget harness.
/// The date-range picker widget converts to/from `DateTimeRange` at the
/// UI boundary.
class TransactionDateRange {
  const TransactionDateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  /// Whether [date]'s calendar day falls within `[start, end]`,
  /// inclusive, ignoring time of day on all three dates.
  bool contains(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    return !day.isBefore(startDay) && !day.isAfter(endDay);
  }
}

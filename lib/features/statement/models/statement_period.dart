/// A single calendar month a person's plain-language statement can be
/// generated for.
///
/// Deliberately month-only (not an arbitrary [TransactionDateRange]) since
/// the Statement screen's selector only ever pages by whole month —
/// simpler for a non-technical reader than a free-form date range picker.
class StatementPeriod {
  StatementPeriod({required int year, required int month})
    : start = DateTime(year, month, 1),
      // Day 0 of the next month is the last day of this month.
      end = DateTime(year, month + 1, 0);

  /// First day of the month, inclusive.
  final DateTime start;

  /// Last day of the month, inclusive.
  final DateTime end;

  factory StatementPeriod.currentMonth([DateTime? now]) {
    final today = now ?? DateTime.now();
    return StatementPeriod(year: today.year, month: today.month);
  }

  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// e.g. `"July 2026"`.
  String get label => '${_months[start.month - 1]} ${start.year}';

  StatementPeriod previousMonth() =>
      StatementPeriod(year: start.year, month: start.month - 1);

  StatementPeriod nextMonth() =>
      StatementPeriod(year: start.year, month: start.month + 1);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatementPeriod && start == other.start;

  @override
  int get hashCode => start.hashCode;
}

import 'package:family_ledger/features/transactions/models/transaction_date_range.dart';

/// The Reports filter bar's quick date presets.
///
/// Each preset resolves to a concrete [TransactionDateRange] (calendar
/// days, inclusive) via [resolve], relative to a caller-supplied "now" so
/// the resolution is deterministic and unit-testable. [allTime] and
/// [custom] are special: all-time resolves to no range at all, and custom
/// carries no dates of its own — the chosen range lives on
/// `ReportFilter.customRange`.
enum ReportDatePreset {
  allTime,
  today,
  yesterday,
  last7Days,
  last30Days,
  thisMonth,
  lastMonth,
  thisYear,
  custom;

  String get label => switch (this) {
    ReportDatePreset.allTime => 'All Time',
    ReportDatePreset.today => 'Today',
    ReportDatePreset.yesterday => 'Yesterday',
    ReportDatePreset.last7Days => 'Last 7 Days',
    ReportDatePreset.last30Days => 'Last 30 Days',
    ReportDatePreset.thisMonth => 'This Month',
    ReportDatePreset.lastMonth => 'Last Month',
    ReportDatePreset.thisYear => 'This Year',
    ReportDatePreset.custom => 'Custom',
  };

  /// The date range this preset means at the moment [now], or null for
  /// [allTime] (no date restriction) and [custom] (the range is chosen by
  /// the user, not derived from the clock).
  ///
  /// Rolling presets ([last7Days], [last30Days]) include today as one of
  /// their N days — "Last 7 Days" means today plus the six days before
  /// it, matching what the label reads as in everyday use.
  TransactionDateRange? resolve(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);

    return switch (this) {
      ReportDatePreset.allTime => null,
      ReportDatePreset.custom => null,
      ReportDatePreset.today => TransactionDateRange(
        start: today,
        end: today,
      ),
      ReportDatePreset.yesterday => TransactionDateRange(
        start: today.subtract(const Duration(days: 1)),
        end: today.subtract(const Duration(days: 1)),
      ),
      ReportDatePreset.last7Days => TransactionDateRange(
        start: today.subtract(const Duration(days: 6)),
        end: today,
      ),
      ReportDatePreset.last30Days => TransactionDateRange(
        start: today.subtract(const Duration(days: 29)),
        end: today,
      ),
      ReportDatePreset.thisMonth => TransactionDateRange(
        start: DateTime(now.year, now.month, 1),
        // Day 0 of the next month is the last day of this month.
        end: DateTime(now.year, now.month + 1, 0),
      ),
      ReportDatePreset.lastMonth => TransactionDateRange(
        start: DateTime(now.year, now.month - 1, 1),
        end: DateTime(now.year, now.month, 0),
      ),
      ReportDatePreset.thisYear => TransactionDateRange(
        start: DateTime(now.year, 1, 1),
        end: DateTime(now.year, 12, 31),
      ),
    };
  }
}

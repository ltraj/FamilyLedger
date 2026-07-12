import 'package:family_ledger/projections/projection.dart';

/// Section 4 of the Reports screen: one calendar month's money movements
/// within the filtered period.
class MonthlyReport implements Projection {
  const MonthlyReport({
    required this.month,
    required this.advances,
    required this.expenses,
    required this.moneyReturned,
    required this.adjustments,
    required this.netChange,
    required this.runningBalance,
  });

  /// First day of the month this row covers.
  final DateTime month;

  final double advances;

  /// Positive magnitude.
  final double expenses;

  final double moneyReturned;

  /// Signed net effect of adjustments.
  final double adjustments;

  /// advances − expenses + returns ± adjustments for this month alone.
  final double netChange;

  /// Cumulative [netChange] from the first displayed month through this
  /// one — the balance trajectory *of the filtered data*, starting from
  /// zero at the start of the period (not the person's lifetime balance,
  /// which belongs to `currentBalance` figures).
  final double runningBalance;
}

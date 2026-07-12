import 'package:family_ledger/projections/projection.dart';
import 'package:family_ledger/projections/reports/report_breakdowns.dart';

/// Section 6 of the Reports screen: where the user's own money went.
///
/// "Own pocket" is the part of each expense not covered by advance money
/// at the moment it happened (see `BalanceCalculator.ownPocketPortions`).
/// Portions are computed per person over full chronology — an expense's
/// coverage depends on the real balance before it, not on what the
/// current filter happens to show — then only the portions belonging to
/// filtered transactions are summed into these breakdowns.
class OwnPocketReport implements Projection {
  const OwnPocketReport({
    required this.total,
    required this.monthly,
    required this.perPerson,
    required this.perCategory,
  });

  final double total;

  /// Month-by-month own-pocket spending, oldest first. Only months with a
  /// non-zero amount appear.
  final List<TrendPoint> monthly;

  /// Largest first. Only people with a non-zero amount appear.
  final List<PersonAmount> perPerson;

  /// Largest first. Only categories with a non-zero amount appear; a null
  /// category is the "no category" bucket.
  final List<CategoryAmount> perCategory;

  bool get isEmpty => total == 0;
}

import 'package:family_ledger/projections/projection.dart';

/// Section 1 of the Reports screen: the ledger-wide money picture.
///
/// Two different time scopes deliberately coexist here:
///
/// - [currentBalance] is a **point-in-time fact**: the full-history
///   balance of the people the person filter admits. Date, category, and
///   type filters don't change it — "where do I stand with these people
///   right now" has one true answer regardless of which period is being
///   inspected.
/// - Every other figure is a **period figure**, computed only from the
///   transactions the full filter admits — "what happened in the
///   selected period".
///
/// Assembled by `ReportEngine`; never stored.
class LedgerReport implements Projection {
  const LedgerReport({
    required this.currentBalance,
    required this.totalAdvanceReceived,
    required this.totalExpenses,
    required this.totalMoneyReturned,
    required this.totalAdjustments,
    required this.ownPocketExpenses,
    required this.netPosition,
  });

  /// Full-history balance of the filtered people. Positive: advance money
  /// is still held. Negative: the user is out of pocket overall.
  final double currentBalance;

  /// Sum of `advanceReceived` amounts in the filtered period.
  final double totalAdvanceReceived;

  /// Sum of `expensePaid` amounts in the filtered period, as a positive
  /// magnitude.
  final double totalExpenses;

  /// Sum of `moneyReturned` amounts in the filtered period.
  final double totalMoneyReturned;

  /// Net effect of `adjustment` transactions in the filtered period
  /// (signed — adjustments can go either way).
  final double totalAdjustments;

  /// The part of [totalExpenses] not covered by advance money at the time
  /// each expense happened — the user's own money. See
  /// `BalanceCalculator.ownPocketPortions`.
  final double ownPocketExpenses;

  /// Net balance change across the filtered period:
  /// advances − expenses + returns ± adjustments. Unlike
  /// [currentBalance], this moves with the date filter — it answers "did
  /// this period leave me holding more or less than it started with".
  final double netPosition;
}

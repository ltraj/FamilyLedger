import 'package:family_ledger/projections/projection.dart';
import 'package:family_ledger/projections/reports/report_breakdowns.dart';
import 'package:family_ledger/projections/transaction_details.dart';

/// The per-person report screen, opened by tapping a Section 2 row.
///
/// Always covers the person's **full history**, regardless of the Reports
/// screen's global filter: the row the user tapped already showed the
/// filtered-period figures, so the detail screen's job is the complete
/// picture — trend, habits, and where the relationship stands overall.
class PersonReportDetail implements Projection {
  const PersonReportDetail({
    required this.currentBalance,
    required this.totalExpenses,
    required this.averageMonthlyExpense,
    required this.monthlySpendingTrend,
    required this.categoryUsage,
    required this.largestExpenses,
    required this.largestAdvances,
    required this.timeline,
  });

  final double currentBalance;

  final double totalExpenses;

  /// [totalExpenses] divided by the number of months with at least one
  /// expense — months with no spending don't dilute the average.
  final double averageMonthlyExpense;

  /// Expense totals per month, oldest first, including zero months
  /// between the first and last expense so the trend chart shows real
  /// gaps rather than compressing them away.
  final List<TrendPoint> monthlySpendingTrend;

  /// Spending per category, largest first; null category is the
  /// "no category" bucket.
  final List<CategoryAmount> categoryUsage;

  /// Top expenses, largest first, fully resolved for display.
  final List<TransactionDetails> largestExpenses;

  /// Top advances, largest first.
  final List<TransactionDetails> largestAdvances;

  /// The person's most recent transactions, newest first, capped by
  /// `ReportEngine.timelineLimit`.
  final List<TransactionDetails> timeline;

  bool get isEmpty => timeline.isEmpty;
}

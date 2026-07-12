import 'package:family_ledger/projections/projection.dart';
import 'package:family_ledger/projections/reports/category_report.dart';
import 'package:family_ledger/projections/reports/ledger_report.dart';
import 'package:family_ledger/projections/reports/monthly_report.dart';
import 'package:family_ledger/projections/reports/own_pocket_report.dart';
import 'package:family_ledger/projections/reports/person_report.dart';
import 'package:family_ledger/projections/reports/report_breakdowns.dart';
import 'package:family_ledger/projections/reports/report_insight.dart';
import 'package:family_ledger/projections/reports/top_lists_report.dart';

/// Everything the Reports screen shows, computed in one pass by
/// `ReportEngine.buildOverview` from the currently filtered transactions.
///
/// Like `DashboardSummary`, this is a pure read model: recomputed
/// whenever the underlying data or the filter changes, never stored. Its
/// section objects are plain data classes, so a future report-export
/// feature can serialize this object directly without touching the
/// engine — the same models-then-writers split the export bundle uses.
///
/// The trend-chart series (Section 7) are getters over the sections
/// already computed, not stored copies — the charts can't drift from the
/// tables they visualize.
class ReportsOverview implements Projection {
  const ReportsOverview({
    required this.ledger,
    required this.personReports,
    required this.categoryReports,
    required this.monthlyReports,
    required this.topLists,
    required this.ownPocket,
    required this.insights,
    required this.filteredTransactionCount,
  });

  final LedgerReport ledger;

  /// Most active first. Only people with at least one filtered
  /// transaction appear.
  final List<PersonReport> personReports;

  /// Highest total first (the default sort; the section's sort selector
  /// re-sorts via `ReportEngine.sortCategoryReports`).
  final List<CategoryReport> categoryReports;

  /// Oldest month first, so running balance reads top-to-bottom.
  final List<MonthlyReport> monthlyReports;

  final TopListsReport topLists;
  final OwnPocketReport ownPocket;
  final List<ReportInsight> insights;

  /// How many transactions the current filter admits — drives the filter
  /// bar's result count and the screen-wide empty state.
  final int filteredTransactionCount;

  bool get isEmpty => filteredTransactionCount == 0;

  /// Section 7: monthly expense totals, derived from [monthlyReports].
  List<TrendPoint> get monthlyExpensesTrend => [
    for (final month in monthlyReports)
      TrendPoint(month: month.month, value: month.expenses),
  ];

  /// Section 7: monthly advance totals, derived from [monthlyReports].
  List<TrendPoint> get monthlyAdvancesTrend => [
    for (final month in monthlyReports)
      TrendPoint(month: month.month, value: month.advances),
  ];

  /// Section 7: actual spending (`expensePaid` only) per category,
  /// derived from [categoryReports], largest first.
  List<CategoryAmount> get categorySpending {
    final spending = [
      for (final report in categoryReports)
        if (report.expenseTotal > 0)
          CategoryAmount(category: report.category, amount: report.expenseTotal),
    ];
    spending.sort((a, b) => b.amount.compareTo(a.amount));
    return spending;
  }
}

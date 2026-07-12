import 'package:family_ledger/models/category_model.dart';
import 'package:family_ledger/projections/projection.dart';

/// Section 3 of the Reports screen: one category's figures over the
/// filtered period.
///
/// [category] is null for the "no category" bucket, which exists for the
/// same reason as `CategoryAmount.category` being nullable: uncategorized
/// transactions are real money, and dropping them would make the section
/// totals disagree with Section 1.
class CategoryReport implements Projection {
  const CategoryReport({
    required this.category,
    required this.total,
    required this.expenseTotal,
    required this.average,
    required this.largest,
    required this.smallest,
    required this.transactionCount,
    required this.mostRecentDate,
  });

  final CategoryModel? category;

  /// Sum of transaction magnitudes in this category, all types.
  final double total;

  /// Sum of `expensePaid` amounts only. This — not [total] — is what the
  /// "Category Spending" chart and spending insights use: a categorized
  /// advance is money received, not money spent, and counting it as
  /// spending would state something false.
  final double expenseTotal;

  final double average;
  final double largest;
  final double smallest;
  final int transactionCount;
  final DateTime mostRecentDate;
}

/// How the Category Analysis section is ordered. The user's pick re-sorts
/// via `ReportEngine.sortCategoryReports` — a pure helper, so the widget
/// still does no calculating of its own.
enum CategoryReportSort {
  amount,
  frequency,
  alphabetical;

  String get label => switch (this) {
    CategoryReportSort.amount => 'Amount',
    CategoryReportSort.frequency => 'Frequency',
    CategoryReportSort.alphabetical => 'A–Z',
  };
}

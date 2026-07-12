import 'package:family_ledger/models/category_model.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/projections/projection.dart';
import 'package:family_ledger/projections/reports/monthly_report.dart';
import 'package:family_ledger/projections/transaction_details.dart';

/// Section 5 of the Reports screen: the extremes of the filtered period.
/// Every field is null when the filtered data simply doesn't contain that
/// kind of record — the widget hides the row rather than inventing one.
class TopListsReport implements Projection {
  const TopListsReport({
    required this.highestExpense,
    required this.highestAdvance,
    required this.largestTransaction,
    required this.mostActivePerson,
    required this.mostUsedCategory,
    required this.largestExpenseMonth,
  });

  /// Largest single `expensePaid`, fully resolved for display.
  final TransactionDetails? highestExpense;

  /// Largest single `advanceReceived`.
  final TransactionDetails? highestAdvance;

  /// Largest transaction of any type, by magnitude.
  final TransactionDetails? largestTransaction;

  final TopPersonActivity? mostActivePerson;
  final TopCategoryUsage? mostUsedCategory;

  /// The month with the highest expense total.
  final MonthlyReport? largestExpenseMonth;
}

/// The most active person and how active they were — the count is what
/// makes the row informative rather than just a name.
class TopPersonActivity implements Projection {
  const TopPersonActivity({
    required this.person,
    required this.transactionCount,
  });

  final PersonModel person;
  final int transactionCount;
}

/// The most used category and its usage count.
class TopCategoryUsage implements Projection {
  const TopCategoryUsage({
    required this.category,
    required this.transactionCount,
  });

  final CategoryModel category;
  final int transactionCount;
}

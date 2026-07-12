import 'package:family_ledger/models/category_model.dart';
import 'package:family_ledger/projections/attention_item.dart';
import 'package:family_ledger/projections/person_summary.dart';
import 'package:family_ledger/projections/projection.dart';
import 'package:family_ledger/projections/transaction_details.dart';

/// Ledger-wide figures for the Dashboard (Home tab).
///
/// Assembled by `DashboardAggregator` from data that already exists
/// elsewhere — `PersonSummary` (from `PeopleViewModel`, so a person's
/// balance is computed exactly once, not re-derived here) and the raw
/// transaction/category streams — never recomputed from scratch. See
/// `lib/features/dashboard/utils/dashboard_aggregator.dart`.
class DashboardSummary implements Projection {
  const DashboardSummary({
    required this.totalAdvanceHeld,
    required this.totalOwedToMe,
    required this.thisMonthExpenses,
    required this.people,
    required this.attentionItems,
    required this.recentActivity,
    required this.highestAdvancePerson,
    required this.mostOwingPerson,
    required this.mostActivePersonThisMonth,
    required this.mostUsedCategory,
    required this.largestExpenseThisMonth,
  });

  /// Sum of every active person's balance, counting only those in credit
  /// (balance > 0). Always >= 0.
  final double totalAdvanceHeld;

  /// Sum of every active person's shortfall, counting only those in debt
  /// (balance < 0), expressed as a positive magnitude (how much is owed
  /// to the user, not a negative number). Always >= 0.
  final double totalOwedToMe;

  /// Net Position — how much advance is held minus how much is owed —
  /// is deliberately not stored: it's `totalAdvanceHeld - totalOwedToMe`,
  /// computed on demand so it can never drift out of sync with the two
  /// figures it's derived from.
  double get netPosition => totalAdvanceHeld - totalOwedToMe;

  /// Total of every `expensePaid` transaction dated in the current
  /// calendar month, as a positive magnitude.
  final double thisMonthExpenses;

  /// Every active person (permanent and temporary), for the People
  /// Overview section. Also doubles as the source for this dashboard's
  /// empty states: no entries means no active people exist; entries with
  /// no one having any transactions means people exist but nothing's
  /// been recorded yet.
  final List<PersonSummary> people;

  /// Active person count, for the "Active People" summary card. Derived
  /// from [people] rather than stored as its own concept.
  int get activePersonCount => people.length;

  /// People who need action, ordered by priority (see
  /// [AttentionReason]). Empty when nothing needs attention — the
  /// Dashboard hides the whole section in that case.
  final List<AttentionItem> attentionItems;

  /// The 10 most recent transactions across every person, newest first,
  /// each with its own true running balance already resolved.
  final List<TransactionDetails> recentActivity;

  /// The active person currently holding the most advance, or null if no
  /// active person has a positive balance.
  final PersonSummary? highestAdvancePerson;

  /// The active person the user is most out of pocket for, or null if no
  /// active person has a negative balance.
  final PersonSummary? mostOwingPerson;

  /// The person with the most transactions dated in the current calendar
  /// month, or null if nobody has any this month.
  final PersonSummary? mostActivePersonThisMonth;

  /// The category used by the most transactions (all-time), or null if
  /// no transaction has ever had a category.
  final CategoryModel? mostUsedCategory;

  /// The single largest `expensePaid` transaction dated in the current
  /// calendar month, or null if there isn't one.
  final TransactionDetails? largestExpenseThisMonth;
}

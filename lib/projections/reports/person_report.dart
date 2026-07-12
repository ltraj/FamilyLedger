import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/projections/projection.dart';

/// Section 2 of the Reports screen: one person's figures for the filtered
/// period, plus their point-in-time [currentBalance] (full history — same
/// two-scope rule as `LedgerReport`).
class PersonReport implements Projection {
  const PersonReport({
    required this.person,
    required this.currentBalance,
    required this.advanceReceived,
    required this.expenses,
    required this.moneyReturned,
    required this.transactionCount,
    required this.averageTransaction,
    required this.largestExpense,
    required this.largestAdvance,
    required this.firstTransactionDate,
    required this.latestTransactionDate,
  });

  final PersonModel person;

  /// Full-history balance for this person, independent of the date/
  /// category/type filters.
  final double currentBalance;

  final double advanceReceived;
  final double expenses;
  final double moneyReturned;
  final int transactionCount;

  /// Mean transaction magnitude in the filtered period.
  final double averageTransaction;

  /// Largest single `expensePaid` amount in the filtered period, or null
  /// if there were none.
  final double? largestExpense;

  /// Largest single `advanceReceived` amount in the filtered period, or
  /// null if there were none.
  final double? largestAdvance;

  final DateTime firstTransactionDate;
  final DateTime latestTransactionDate;
}

import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/projections/projection.dart';

/// A person paired with the ledger figures the People screen needs to
/// display, computed from that person's transaction history.
class PersonSummary implements Projection {
  const PersonSummary({
    required this.person,
    required this.balance,
    required this.transactionCount,
    required this.lastTransactionDate,
  });

  final PersonModel person;

  /// Current balance, derived from transaction history. Never stored.
  final double balance;

  final int transactionCount;

  /// Date of this person's most recent transaction, or null if they have
  /// none.
  final DateTime? lastTransactionDate;

  bool get hasTransactions => transactionCount > 0;
}

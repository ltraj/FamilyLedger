import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/models/transaction_model.dart';

/// Utility for calculating ledger balances from transaction history.
///
/// Balances are **never** stored in the database. They are always
/// derived at read time from the full transaction list for a person.
abstract final class BalanceCalculator {
  /// Calculates the current balance for a person from their transactions.
  ///
  /// Formula:
  /// `Advance Received − Expense Paid + Money Returned ± Adjustments`
  ///
  /// - Positive balance: advance money is still available.
  /// - Negative balance: own money was used; the person owes you.
  static double calculateBalance(List<TransactionModel> transactions) {
    var balance = 0.0;

    for (final transaction in transactions) {
      balance += _signedAmount(transaction);
    }

    return balance;
  }

  /// Returns the signed contribution of a single transaction to the balance.
  static double signedAmount(TransactionModel transaction) {
    return _signedAmount(transaction);
  }

  static double _signedAmount(TransactionModel transaction) {
    final amount = transaction.amount;

    return switch (transaction.transactionType) {
      TransactionType.advanceReceived => amount,
      TransactionType.expensePaid => -amount,
      TransactionType.moneyReturned => amount,
      TransactionType.adjustment => amount,
    };
  }

  /// Computes the running balance after each transaction in
  /// [chronologicalTransactions], which must already be in chronological
  /// order (oldest first) — typically a single person's transactions,
  /// since running balance is a per-person concept.
  ///
  /// Returns a list the same length and order as
  /// [chronologicalTransactions], where `result[i]` is the balance
  /// immediately after `chronologicalTransactions[i]`. Like every other
  /// balance in this class, this is computed fresh every time and never
  /// stored.
  static List<double> runningBalances(
    List<TransactionModel> chronologicalTransactions,
  ) {
    var balance = 0.0;
    final result = <double>[];

    for (final transaction in chronologicalTransactions) {
      balance += _signedAmount(transaction);
      result.add(balance);
    }

    return result;
  }

  /// Computes how much of each transaction came out of the user's own
  /// pocket rather than out of advance money.
  ///
  /// [chronologicalTransactions] must be oldest-first and belong to a
  /// single person, exactly like [runningBalances]. Returns a list the
  /// same length and order, where `result[i]` is the own-pocket portion
  /// of transaction `i`:
  ///
  /// - Only `expensePaid` transactions can have one; every other type
  ///   contributes 0.
  /// - An expense fully covered by the balance available immediately
  ///   before it (advance still held) contributes 0.
  /// - An expense larger than the available balance contributes the
  ///   uncovered part; with no advance left (balance already <= 0), the
  ///   whole amount is own pocket.
  ///
  /// Summing these answers "how much of my own money did I actually
  /// spend?" — which a plain expense total can't, since it doesn't know
  /// what was advance-funded. Like every figure in this class, computed
  /// fresh from history, never stored.
  static List<double> ownPocketPortions(
    List<TransactionModel> chronologicalTransactions,
  ) {
    var balance = 0.0;
    final result = <double>[];

    for (final transaction in chronologicalTransactions) {
      if (transaction.transactionType == TransactionType.expensePaid) {
        final available = balance > 0 ? balance : 0.0;
        final uncovered = transaction.amount - available;
        result.add(uncovered > 0 ? uncovered : 0.0);
      } else {
        result.add(0);
      }
      balance += _signedAmount(transaction);
    }

    return result;
  }

  /// Aggregates balances per person from a flat transaction list.
  ///
  /// Returns a map of `personId → balance`.
  static Map<int, double> calculateBalancesByPerson(
    List<TransactionModel> transactions,
  ) {
    final balances = <int, double>{};

    for (final transaction in transactions) {
      balances.update(
        transaction.personId,
        (current) => current + _signedAmount(transaction),
        ifAbsent: () => _signedAmount(transaction),
      );
    }

    return balances;
  }
}

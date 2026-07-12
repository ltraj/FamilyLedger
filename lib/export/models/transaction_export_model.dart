/// AI- and human-readable representation of a transaction, written to
/// `transactions.json` as part of an export bundle.
///
/// Unlike the internal `TransactionModel`, which stores an always-positive
/// `amount` alongside a separate `transactionType`, this model exposes a
/// single signed [amount] so a reader can determine a transaction's effect
/// on the balance from that one field, without cross-referencing
/// [transactionType]. [transactionType] is still included so the original
/// category of movement (advance vs. return vs. adjustment) is not lost.
/// See `transactions.json`'s entry in `schema.json` for the full meaning of
/// every field.
class TransactionExportModel {
  const TransactionExportModel({
    required this.transactionIdentifier,
    required this.personIdentifier,
    this.categoryIdentifier,
    required this.transactionType,
    required this.amount,
    this.remark,
    this.attachmentFileName,
    required this.transactionDate,
    this.runningBalance,
    required this.recordCreatedAt,
    required this.recordUpdatedAt,
  });

  /// Local identifier for this transaction at the time of export.
  final int transactionIdentifier;

  /// Identifies which person this transaction belongs to. Matches a
  /// `personIdentifier` value in people.json.
  final int personIdentifier;

  /// Identifies the expense category of this transaction, if any. Matches
  /// a `categoryIdentifier` value in categories.json.
  final int? categoryIdentifier;

  /// `advanceReceived`, `expensePaid`, `moneyReturned`, or `adjustment`.
  final String transactionType;

  /// Signed amount of this transaction's effect on the person's balance.
  /// Positive means money received; negative means money spent.
  final double amount;

  final String? remark;

  /// File name of this transaction's attachment inside the export bundle's
  /// `attachments` folder, or null if no attachment was set.
  final String? attachmentFileName;

  /// Date the transaction occurred, as shown to the user in the app.
  final DateTime transactionDate;

  /// This person's balance immediately after this transaction, in true
  /// chronological order. Optional: never a source of truth (balances are
  /// always derived fresh from transaction history, per the app's core
  /// design), included purely as a convenience so a reader doesn't have
  /// to replay the whole history themselves. Null when not computed for
  /// this export.
  final double? runningBalance;

  final DateTime recordCreatedAt;
  final DateTime recordUpdatedAt;

  Map<String, dynamic> toJson() => {
        'transactionIdentifier': transactionIdentifier,
        'personIdentifier': personIdentifier,
        'categoryIdentifier': categoryIdentifier,
        'transactionType': transactionType,
        'amount': amount,
        'remark': remark,
        'attachmentFileName': attachmentFileName,
        'transactionDate': transactionDate.toIso8601String(),
        'runningBalance': runningBalance,
        'recordCreatedAt': recordCreatedAt.toIso8601String(),
        'recordUpdatedAt': recordUpdatedAt.toIso8601String(),
      };
}

import 'package:family_ledger/projections/projection.dart';

/// Which way money moved for a [StatementLineItem] — a plain-language
/// stand-in for `TransactionType` so the Statement screen never has to
/// expose (or branch on) app jargon like `advanceReceived`/`expensePaid`.
enum StatementDirection {
  /// Money moved from the person to the ledger owner.
  given,

  /// Money moved from the ledger owner to (or for) the person.
  spent,
}

/// One row of a [PersonStatement]'s itemized "Show details" list.
class StatementLineItem implements Projection {
  const StatementLineItem({
    required this.date,
    required this.description,
    required this.amount,
    required this.direction,
    this.remark,
  });

  final DateTime date;

  /// Plain-language label — a category name, `"You gave"`, or a short
  /// adjustment phrase (e.g. `"Sent to Ajit"`). Never a raw transaction
  /// type or the word "adjustment".
  final String description;

  /// Always a non-negative magnitude — [direction] conveys the sign, so
  /// no caller ever needs to render a literal minus sign.
  final double amount;

  final StatementDirection direction;

  /// The transaction's free-text remark, already trimmed and normalized
  /// to null when blank — never a placeholder like "No remark". Callers
  /// only need a null check before rendering it.
  final String? remark;
}

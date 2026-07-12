import 'package:family_ledger/core/constants/enums.dart';

/// Display label for a [TransactionType], for the Transaction screen's
/// UI (cards, the add/edit sheet, the type filter).
///
/// Kept as an extension in this feature rather than on [TransactionType]
/// itself: the enum is a core, structural type with no UI concerns of its
/// own — display strings belong with the feature that displays them.
extension TransactionTypeLabel on TransactionType {
  String get label => switch (this) {
        TransactionType.advanceReceived => 'Advance Received',
        TransactionType.expensePaid => 'Expense Paid',
        TransactionType.moneyReturned => 'Money Returned',
        TransactionType.adjustment => 'Adjustment',
      };
}

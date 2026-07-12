/// Ways the Transaction screen can order the transaction list.
///
/// This only affects which order transactions are *displayed* in — it
/// never affects `TransactionDetails.runningBalanceAfter`, which is
/// always computed in true chronological order regardless of the
/// currently selected sort. See `TransactionsViewModel`.
enum TransactionSortOption {
  newest,
  oldest,
  highestAmount,
  lowestAmount;

  /// Label shown in the sort picker.
  String get label => switch (this) {
        TransactionSortOption.newest => 'Newest',
        TransactionSortOption.oldest => 'Oldest',
        TransactionSortOption.highestAmount => 'Highest Amount',
        TransactionSortOption.lowestAmount => 'Lowest Amount',
      };
}

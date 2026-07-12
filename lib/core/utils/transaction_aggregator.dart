import 'package:family_ledger/core/utils/balance_calculator.dart';
import 'package:family_ledger/models/transaction_model.dart';

/// Generic grouping, filtering, and frequency-analysis primitives over a
/// transaction list.
///
/// Complements [BalanceCalculator]: that class turns a chronological
/// transaction list into money figures; this class turns a flat
/// transaction list into the sub-lists and lookups other calculations
/// need first — which person each transaction belongs to, which
/// transactions fall in a date range, which key appears most often.
/// Introduced to stop that partitioning logic from being re-derived
/// slightly differently in `PeopleViewModel`, `DashboardAggregator`, and
/// `ExportDataCollectorImpl` — see each call site for what it replaced.
/// Every method here is a pure function of its inputs: no I/O, no
/// database, no Riverpod.
abstract final class TransactionAggregator {
  /// Partitions [transactions] by `personId`, preserving each person's
  /// relative order.
  static Map<int, List<TransactionModel>> groupByPerson(
    List<TransactionModel> transactions,
  ) {
    final result = <int, List<TransactionModel>>{};
    for (final transaction in transactions) {
      (result[transaction.personId] ??= []).add(transaction);
    }
    return result;
  }

  /// Every transaction in [transactions] dated on or after [from] and on
  /// or before [to] (inclusive on both ends).
  static List<TransactionModel> filterByDateRange(
    List<TransactionModel> transactions, {
    required DateTime from,
    required DateTime to,
  }) {
    return [
      for (final transaction in transactions)
        if (!transaction.date.isBefore(from) && !transaction.date.isAfter(to))
          transaction,
    ];
  }

  /// Each transaction's running balance immediately after it, keyed by
  /// transaction id, computed against that transaction's own person only
  /// — a multi-person [transactions] list is grouped internally first, so
  /// one person's history never affects another's running balance.
  ///
  /// [transactions] must be newest-first, matching
  /// `TransactionRepository.getAll`/`watchAll`'s order (`date DESC, id
  /// DESC`) — [groupByPerson] preserves relative order, so each person's
  /// group inherits that same ordering, and is simply reversed to get
  /// [BalanceCalculator.runningBalances]' required oldest-first order,
  /// same-date ties included. If [personIds] is given, only those
  /// people's running balances are computed — the grouping pass is still
  /// O(n) over all of [transactions], but the balance computation itself
  /// is bounded to just the requested people, not everyone in the
  /// ledger.
  static Map<int, double> runningBalancesById(
    List<TransactionModel> transactions, {
    Set<int>? personIds,
  }) {
    final byPerson = groupByPerson(transactions);
    final targetPersonIds = personIds ?? byPerson.keys.toSet();

    final result = <int, double>{};
    for (final personId in targetPersonIds) {
      final personTransactions = byPerson[personId];
      if (personTransactions == null) continue;

      final chronological = personTransactions.reversed.toList();
      final balances = BalanceCalculator.runningBalances(chronological);

      for (var i = 0; i < chronological.length; i++) {
        final id = chronological[i].id;
        if (id != null) result[id] = balances[i];
      }
    }
    return result;
  }

  /// Each transaction's own-pocket portion (see
  /// [BalanceCalculator.ownPocketPortions]), keyed by transaction id,
  /// computed per person over that person's full chronology — same
  /// contract as [runningBalancesById]: [transactions] must be
  /// newest-first, and [personIds] optionally bounds the work to just the
  /// people a caller actually needs.
  ///
  /// Zero-valued entries (non-expenses, fully advance-covered expenses)
  /// are omitted, so a missing id simply means "nothing from your own
  /// pocket" — callers sum with `map[id] ?? 0`.
  static Map<int, double> ownPocketByTransactionId(
    List<TransactionModel> transactions, {
    Set<int>? personIds,
  }) {
    final byPerson = groupByPerson(transactions);
    final targetPersonIds = personIds ?? byPerson.keys.toSet();

    final result = <int, double>{};
    for (final personId in targetPersonIds) {
      final personTransactions = byPerson[personId];
      if (personTransactions == null) continue;

      final chronological = personTransactions.reversed.toList();
      final portions = BalanceCalculator.ownPocketPortions(chronological);

      for (var i = 0; i < chronological.length; i++) {
        final id = chronological[i].id;
        if (id != null && portions[i] > 0) result[id] = portions[i];
      }
    }
    return result;
  }

  /// The most common non-null [keyOf] value among [items], or null if
  /// [items] is empty or every key is null. Ties resolve to whichever
  /// key is encountered first.
  static K? mostFrequentKey<T, K>(
    Iterable<T> items,
    K? Function(T item) keyOf,
  ) {
    final counts = <K, int>{};
    for (final item in items) {
      final key = keyOf(item);
      if (key == null) continue;
      counts.update(key, (count) => count + 1, ifAbsent: () => 1);
    }
    if (counts.isEmpty) return null;

    K? mostFrequent;
    var highestCount = 0;
    counts.forEach((key, count) {
      if (count > highestCount) {
        highestCount = count;
        mostFrequent = key;
      }
    });
    return mostFrequent;
  }
}

import 'package:family_ledger/features/statement/models/statement_period.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the currently selected month for one person's Statement screen.
///
/// Family-scoped by `personId`, like `TransactionQueryController`, so
/// switching between two people's statements never mixes up which month
/// each was viewing.
class StatementPeriodController extends FamilyNotifier<StatementPeriod, int> {
  @override
  StatementPeriod build(int personId) => StatementPeriod.currentMonth();

  void previousMonth() => state = state.previousMonth();

  void nextMonth() => state = state.nextMonth();
}

final statementPeriodProvider =
    NotifierProvider.family<StatementPeriodController, StatementPeriod, int>(
      StatementPeriodController.new,
    );

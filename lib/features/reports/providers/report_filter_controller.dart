import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/features/reports/models/report_date_preset.dart';
import 'package:family_ledger/features/reports/models/report_filter.dart';
import 'package:family_ledger/features/transactions/models/transaction_date_range.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Reports screen's current filter selection.
///
/// Lives at the root `ProviderScope` (app lifetime), which is what makes
/// the last-used filters "remembered": leaving the Reports tab and coming
/// back — or navigating anywhere else in the app — never resets them.
/// Deliberately separate from `ReportsViewModel` for the same reason
/// `PeopleQueryController` is separate from `PeopleViewModel`: this is
/// selection state, not loaded data.
class ReportFilterController extends Notifier<ReportFilter> {
  @override
  ReportFilter build() => const ReportFilter();

  void setPerson(int? personId) {
    state = state.copyWith(personId: personId);
  }

  void setCategory(int? categoryId) {
    state = state.copyWith(categoryId: categoryId);
  }

  void setTransactionType(TransactionType? type) {
    state = state.copyWith(transactionType: type);
  }

  void setPreset(ReportDatePreset preset) {
    state = state.copyWith(
      datePreset: preset,
      // A stale custom range would silently re-apply the next time the
      // user picks Custom; drop it when they move to a named preset.
      customRange: preset == ReportDatePreset.custom ? state.customRange : null,
    );
  }

  void setCustomRange(TransactionDateRange range) {
    state = state.copyWith(
      datePreset: ReportDatePreset.custom,
      customRange: range,
    );
  }

  void setSearchText(String text) {
    state = state.copyWith(searchText: text);
  }

  void clearAll() {
    state = const ReportFilter();
  }
}

final reportFilterProvider =
    NotifierProvider<ReportFilterController, ReportFilter>(
      ReportFilterController.new,
    );

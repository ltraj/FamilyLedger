import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/features/reports/models/report_date_preset.dart';
import 'package:family_ledger/features/transactions/models/transaction_date_range.dart';

/// The Reports screen's global filter selection: every section derives
/// from the transactions this filter admits.
///
/// A plain immutable value — no Riverpod, no widgets — so
/// `ReportFilterEngine` and `ReportEngine` stay pure functions of
/// (data, filter). Held app-lifetime by `reportFilterProvider`, which is
/// what makes the last selection "remembered" when the user leaves the
/// Reports tab and comes back.
class ReportFilter {
  const ReportFilter({
    this.personId,
    this.categoryId,
    this.transactionType,
    this.datePreset = ReportDatePreset.allTime,
    this.customRange,
    this.searchText = '',
  });

  /// Only this person's transactions, or null for everyone.
  final int? personId;

  /// Only transactions in this category, or null for all categories.
  final int? categoryId;

  /// Only this transaction type, or null for all types.
  final TransactionType? transactionType;

  final ReportDatePreset datePreset;

  /// The user-picked range when [datePreset] is [ReportDatePreset.custom];
  /// ignored for every other preset.
  final TransactionDateRange? customRange;

  /// Free-text query matched against person name, category name, and
  /// remark (see `ReportFilterEngine`). Empty means no text filtering.
  final String searchText;

  /// The concrete date range currently in effect, or null when no date
  /// restriction applies ([ReportDatePreset.allTime], or [custom] before
  /// a range has been picked).
  TransactionDateRange? resolveDateRange(DateTime now) {
    if (datePreset == ReportDatePreset.custom) return customRange;
    return datePreset.resolve(now);
  }

  bool get hasActiveFilters =>
      personId != null ||
      categoryId != null ||
      transactionType != null ||
      datePreset != ReportDatePreset.allTime ||
      searchText.trim().isNotEmpty;

  static const Object _unset = Object();

  /// [personId], [categoryId], [transactionType], and [customRange] use a
  /// sentinel default so a caller can explicitly set them back to null
  /// (clear the filter) — a plain `??`-style copyWith can't distinguish
  /// "not passed" from "passed null".
  ReportFilter copyWith({
    Object? personId = _unset,
    Object? categoryId = _unset,
    Object? transactionType = _unset,
    ReportDatePreset? datePreset,
    Object? customRange = _unset,
    String? searchText,
  }) {
    return ReportFilter(
      personId: identical(personId, _unset)
          ? this.personId
          : personId as int?,
      categoryId: identical(categoryId, _unset)
          ? this.categoryId
          : categoryId as int?,
      transactionType: identical(transactionType, _unset)
          ? this.transactionType
          : transactionType as TransactionType?,
      datePreset: datePreset ?? this.datePreset,
      customRange: identical(customRange, _unset)
          ? this.customRange
          : customRange as TransactionDateRange?,
      searchText: searchText ?? this.searchText,
    );
  }
}

import 'package:family_ledger/core/utils/friendly_date.dart';

/// Human-friendly relative date formatting shared across features (e.g.
/// the Dashboard's Recent Activity feed): `Today`, `Yesterday`, `3 days
/// ago`, falling back to [FriendlyDate]'s full format beyond a week (or
/// for a date that isn't in the past at all).
abstract final class RelativeDate {
  static String format(DateTime date, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final target = DateTime(date.year, date.month, date.day);
    final differenceInDays = today.difference(target).inDays;

    if (differenceInDays == 0) return 'Today';
    if (differenceInDays == 1) return 'Yesterday';
    if (differenceInDays > 1 && differenceInDays < 7) {
      return '$differenceInDays days ago';
    }
    return FriendlyDate.format(date);
  }
}

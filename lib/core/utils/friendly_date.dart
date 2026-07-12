/// Minimal, locale-independent date formatting shared across features
/// (e.g. `11 Jul 2026`).
abstract final class FriendlyDate {
  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String format(DateTime date) {
    return '${date.day} ${_months[date.month - 1]} ${date.year}';
  }
}

import 'package:family_ledger/core/constants/app_constants.dart';

/// Minimal currency formatting shared across features.
///
/// Uses the app's default currency symbol rather than a formatting
/// package, since the app has no `intl`-style dependency today. Wiring
/// this to the user's configured currency (`SettingsModel.currency`) is a
/// natural follow-up once the Settings screen exists.
abstract final class CurrencyFormatter {
  static String format(double amount) {
    final isNegative = amount < 0;
    final fixed = amount.abs().toStringAsFixed(2);
    final parts = fixed.split('.');
    final grouped = _withThousandsSeparators(parts[0]);
    final sign = isNegative ? '-' : '';
    return '$sign${AppConstants.defaultCurrencySymbol}$grouped.${parts[1]}';
  }

  static String _withThousandsSeparators(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final positionFromEnd = digits.length - i;
      if (i > 0 && positionFromEnd % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

import 'package:family_ledger/core/constants/app_constants.dart';

/// One currency offered in the Settings currency picker.
class CurrencyDefinition {
  const CurrencyDefinition({
    required this.code,
    required this.symbol,
    required this.label,
  });

  /// ISO 4217 code (e.g. `INR`), matches `SettingsModel.currency`.
  final String code;

  /// Display symbol (e.g. `₹`).
  final String symbol;

  /// Human-readable name shown in the picker.
  final String label;
}

/// The fixed set of currencies the Settings screen offers.
///
/// Intentionally a small hand-picked list rather than pulling in `intl` —
/// see `CurrencyFormatter`'s doc comment for why this app has no `intl`
/// dependency. Add a new [CurrencyDefinition] here to offer another
/// currency; no other change is needed since [symbolFor] and the picker
/// both derive from this list.
abstract final class SupportedCurrencies {
  static const List<CurrencyDefinition> all = [
    CurrencyDefinition(code: 'INR', symbol: '₹', label: 'Indian Rupee'),
    CurrencyDefinition(code: 'USD', symbol: '\$', label: 'US Dollar'),
    CurrencyDefinition(code: 'EUR', symbol: '€', label: 'Euro'),
    CurrencyDefinition(code: 'GBP', symbol: '£', label: 'British Pound'),
  ];

  /// The display symbol for [code], falling back to
  /// [AppConstants.defaultCurrencySymbol] if [code] is null or not one of
  /// [all] (e.g. a value from a future app version this build doesn't
  /// recognize yet).
  static String symbolFor(String? code) {
    for (final currency in all) {
      if (currency.code == code) return currency.symbol;
    }
    return AppConstants.defaultCurrencySymbol;
  }

  /// The full [CurrencyDefinition] for [code], falling back to the first
  /// entry (INR) if [code] is null or unrecognized.
  static CurrencyDefinition definitionFor(String? code) {
    for (final currency in all) {
      if (currency.code == code) return currency;
    }
    return all.first;
  }
}

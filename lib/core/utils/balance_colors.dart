import 'package:flutter/material.dart';

/// Semantic colors for a balance figure: green when in credit, red when
/// not, gray when there's no history yet. Shared across any feature that
/// displays a person's or a transaction's balance impact.
///
/// Green/red carry a fixed, universal meaning (money received vs. money
/// owed) that must not shift with the app's theme — like `AvatarPalette`,
/// this intentionally does not derive those two from `Theme.of(context)`.
/// The "no transactions" case has no inherent meaning of its own, so it
/// does use the theme's neutral color.
abstract final class BalanceColors {
  static const Color positive = Color(0xFF2E7D32);
  static const Color negative = Color(0xFFC62828);

  static Color forBalance(
    BuildContext context, {
    required bool hasTransactions,
    required double balance,
  }) {
    if (!hasTransactions) return Theme.of(context).colorScheme.onSurfaceVariant;
    return balance >= 0 ? positive : negative;
  }
}

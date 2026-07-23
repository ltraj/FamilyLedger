import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/projections/projection.dart';
import 'package:family_ledger/projections/statement/statement_line_item.dart';

/// Which way [PersonStatement.balanceLine] reads — lets the Statement
/// screen pick a balance color without parsing the finished sentence or
/// re-exposing the raw signed balance figure.
enum BalanceStatus { positive, negative, settled }

/// A non-technical, jargon-free summary of one person's ledger activity
/// over one month, built by `StatementEngine.build`.
///
/// Deliberately structured rather than a single formatted string blob:
/// [gaveLine], [spentLine], and [balanceLine] are kept separate so the
/// Statement screen can lay each out on its own line (matching the
/// "You gave / I spent / balance" format) and so tests can assert on each
/// sentence independently.
class PersonStatement implements Projection {
  const PersonStatement({
    required this.person,
    required this.periodLabel,
    required this.periodStart,
    required this.periodEnd,
    required this.gaveLine,
    required this.spentLine,
    required this.balanceLine,
    required this.balanceStatus,
    required this.items,
  });

  final PersonModel person;

  /// e.g. `"July 2026"`.
  final String periodLabel;

  final DateTime periodStart;
  final DateTime periodEnd;

  /// `"You gave me ₹9,000 on 9 July."`, or null if nothing was given this
  /// period.
  final String? gaveLine;

  /// `"I spent ₹700 for you: ₹500 on electricity, ₹200 on recharge."`, or
  /// null if nothing was spent this period.
  final String? spentLine;

  /// Always present: `"₹8,300 is still with me."` /
  /// `"You owe me ₹5,750."` / `"We're all settled up."`.
  final String balanceLine;

  final BalanceStatus balanceStatus;

  /// Itemized detail rows for the "Show details" section, oldest first.
  final List<StatementLineItem> items;
}

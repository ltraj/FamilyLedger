import 'package:family_ledger/projections/projection.dart';

/// What kind of fact an insight states — the widget maps this to an icon;
/// the projection itself stays framework-free.
enum ReportInsightKind { spending, person, category, ownPocket, balance }

/// Section 8 of the Reports screen: one plain-language, purely calculated
/// statement, e.g. "Most spending is on Electricity (₹4,200)".
///
/// Produced only by `ReportEngine._buildInsights`, and only when the
/// filtered data actually supports the statement — an insight is a
/// rendering of a number that exists, never a conclusion drawn beyond it.
class ReportInsight implements Projection {
  const ReportInsight({required this.kind, required this.message});

  final ReportInsightKind kind;
  final String message;
}

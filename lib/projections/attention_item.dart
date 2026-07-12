import 'package:family_ledger/projections/person_summary.dart';
import 'package:family_ledger/projections/projection.dart';

/// Why a person appears in the Dashboard's Attention Center.
///
/// Ordered by priority: `DashboardAggregator` (in the dashboard feature)
/// assigns at most one reason per person, picking the first of these that
/// applies, so a person never gets two overlapping attention cards.
///
/// [longInactive] and [recentlyEditedTransaction] are prepared as future
/// extension points — named ahead of time so the Dashboard's rendering
/// code (a `switch` over this enum) already has a place for them — but
/// nothing produces them yet; there's no defined threshold for
/// "inactive," and edit-tracking beyond `updatedAt` doesn't exist yet.
enum AttentionReason {
  negativeBalance,
  lowRemainingAdvance,
  temporaryPersonPending,
  longInactive,
  recentlyEditedTransaction,
}

/// One person who needs the user's attention, and why.
class AttentionItem implements Projection {
  const AttentionItem({required this.personSummary, required this.reason});

  final PersonSummary personSummary;
  final AttentionReason reason;
}

/// Utilities for working with `People.displayOrder`.
///
/// `displayOrder` values are stored with gaps (see [step]) instead of as
/// dense `0, 1, 2, ...` integers, specifically so a future drag-and-drop
/// feature can insert a person between two existing neighbors by writing a
/// single midpoint value — see [between] — without renumbering every other
/// row or changing the column's type or constraints. Drag-and-drop itself
/// is not implemented; this only prepares the scheme it will need.
abstract final class PersonDisplayOrder {
  /// Gap left between consecutive people when assigning order values
  /// during migration backfill or when appending a newly created person.
  static const int step = 1000;

  /// The `displayOrder` value for the first person in an empty list.
  static const int initial = 0;

  /// Returns the `displayOrder` value that appends a new person to the end
  /// of the list, given the current highest existing value (or null if
  /// the list is empty).
  static int appendAfter(int? highestExistingOrder) {
    return highestExistingOrder == null ? initial : highestExistingOrder + step;
  }

  /// Returns a `displayOrder` value placing a person strictly between
  /// [before] and [after] (either may be null to mean the start/end of the
  /// list). Not called anywhere yet — this is the insertion point a future
  /// drag-and-drop feature will use once built.
  ///
  /// If [before] and [after] are already adjacent (no integer value lies
  /// between them), callers of this future feature will need to renumber
  /// the affected rows with [step]-sized gaps before calling this again.
  /// That renumbering pass is intentionally not implemented yet either.
  static int between(int? before, int? after) {
    if (before == null && after == null) return initial;
    if (before == null) return after! - (step ~/ 2);
    if (after == null) return before + step;
    return before + ((after - before) ~/ 2);
  }
}

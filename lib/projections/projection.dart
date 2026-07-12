/// Marker interface for read-only projections: data shapes assembled from
/// one or more repository-sourced models purely for display.
///
/// A projection is never persisted and never mutated directly. It is
/// always computed fresh from source-of-truth repositories — either
/// one-shot (a `Future`) or reactively (a `Stream`; see
/// `transactionsStreamProvider` in `lib/providers/repository_providers.dart`).
/// If what a projection shows needs to change, the underlying repository
/// data changes and the projection is recomputed from it; it is never
/// edited in place.
///
/// Implemented today by `PersonSummary`. `TransactionDetails` and
/// `DashboardSummary` are prepared as the same kind of object ahead of the
/// Transaction and Dashboard phases, but nothing constructs them yet —
/// see their own doc comments for what will need to change to produce
/// them.
abstract interface class Projection {}

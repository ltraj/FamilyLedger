# FamilyLedger

Flutter personal-ledger app (Riverpod + Drift/SQLite + GetIt). For full architecture,
schema, repository/DI details, balance-calculation logic, testing coverage, and
per-feature conventions, **read `PROJECT_CONTEXT.md` at the project root first** —
it is the authoritative reference for this codebase, kept accurate against the real
source (the README is stale and understates what's actually built).

## Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # regenerate app_database.g.dart after any table/schema change
flutter analyze
flutter test                                                # full suite
flutter test test/path/to/some_test.dart                    # single file
flutter run
```

Always regenerate (`build_runner build`) after editing anything under
`lib/core/database/tables/` or bumping `AppConstants.databaseSchemaVersion` — never
hand-edit `app_database.g.dart`.

## Coding conventions

- **No code-generated models.** `lib/models/*.dart` classes are hand-written:
  `copyWith`, `toJson`/`fromJson`, value `==`/`hashCode`, all manual. Follow the same
  explicit style for new models — do not introduce `freezed`/`json_serializable`.
- **`abstract final class`** for static-only utility/constant holders (never
  instantiated). **`abstract interface class`** for every repository/service contract
  and the `Projection` marker.
- **No DAO layer.** Repository `impl/` classes query the generated `AppDatabase`
  table accessors directly — don't add an intermediate DAO class.
- **Balances are never stored.** Any derived figure (balance, running balance,
  own-pocket portion, aggregate) is computed at read time from transaction history,
  the same way `BalanceCalculator`/`TransactionAggregator` do it — never add a stored
  or cached column for something derivable from `transactions`.
- **GetIt is the composition root** (`lib/core/services/service_locator.dart`,
  `registerLazySingleton` only); **Riverpod providers never construct services
  themselves** — they re-expose GetIt singletons (`sl<T>()`) and add reactivity on
  top. See `lib/providers/repository_providers.dart`.
- **Feature packages** (`lib/features/<name>/{models,providers,screens,utils,widgets}`)
  split transient UI state (`*QueryController`, a `Notifier`) from persisted data
  (`*ViewModel`, an `AsyncNotifier`), combined via a pure `*QueryEngine`/`*Engine.apply(...)`
  static method with no Riverpod/I/O dependency — keep new filterable screens
  unit-testable the same way.
- **Domain-specific exceptions** (implementing `Exception`, with a `message` getter)
  for validated mutations — never a bare string or generic error for user-facing
  validation failures.
- **Trailing commas and const-first are enforced** by `analysis_options.yaml`
  (`prefer_const_constructors`, `prefer_const_declarations`, `avoid_print`,
  `require_trailing_commas`) — run `flutter analyze` before considering a change done.
- **Doc comments explain *why*, not *what*** — especially for schema/migration/
  ordering decisions. Don't add comments that just restate the code.
- Full conventions (provider naming, sentinel `copyWith` pattern, debounced search,
  static `show()` dialog factories, exception-per-mutation pattern, etc.) are in
  `PROJECT_CONTEXT.md` §11.

## Testing

In-memory Drift DB (`AppDatabase.forTesting(NativeDatabase.memory())`) via
`test/helpers/test_database.dart`/`test_repositories.dart` for anything
database-touching; pure engines/utils get plain unit tests with no I/O. See
`PROJECT_CONTEXT.md` §8 for full coverage map and known gaps (Settings screen and a
handful of formatters/service impls currently have no dedicated test).

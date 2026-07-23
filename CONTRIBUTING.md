# Contributing

Thanks for considering a contribution to FamilyLedger.

## Getting started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # regenerate app_database.g.dart
flutter analyze
flutter test
```

All three must pass before opening a pull request.

## Workflow

1. Fork the repo and create a branch off `main`.
2. Make your change, keeping pull requests focused on a single concern.
3. Regenerate Drift code (`build_runner`) after touching anything under
   `lib/core/database/tables/` or bumping `AppConstants.databaseSchemaVersion`
   — never hand-edit `app_database.g.dart`.
4. Add or update tests. This project relies on the test suite (~275 cases)
   as its safety net — see `PROJECT_CONTEXT.md` §8 for the current coverage map.
5. Run `flutter analyze` and `flutter test` locally.
6. Open a pull request describing what changed and why.

## Code style

See `CLAUDE.md` and `PROJECT_CONTEXT.md` §11 for the full set of conventions
this codebase follows (no code-generated models, no DAO layer, balances
never stored, GetIt as composition root with Riverpod as the consumption
layer, feature-package structure, etc.). Highlights:

- Hand-written models (no `freezed`/`json_serializable`).
- `abstract interface class` for every repository/service contract.
- Trailing commas and const-first are enforced by `analysis_options.yaml`.
- Doc comments explain *why*, not *what*.

## Reporting issues

Open a GitHub issue with a clear description, steps to reproduce, and (if
relevant) the failing test or stack trace.

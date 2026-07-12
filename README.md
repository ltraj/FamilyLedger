# Family Ledger

Personal ledger for tracking balances between you and different people.

## Phase 1 — Architecture & Database Foundation

This phase includes project structure, Drift database, domain models, repository layer, dependency injection, and balance calculation utilities. **No UI screens are implemented yet.**

## Tech Stack

- Flutter (latest stable)
- Riverpod (state management)
- Drift (SQLite)
- GetIt (dependency injection)
- Clean Architecture + Repository Pattern + MVVM-ready structure
- Material 3

## Getting Started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```

## Database

Balances are **never stored**. They are calculated at read time:

```
Balance = Advance Received − Expense Paid + Money Returned ± Adjustments
```

- **Positive balance** — you still hold their advance money
- **Negative balance** — you paid from your own pocket; they owe you

## Project Structure

See inline documentation in `lib/` or the architecture section in the project README after UI phase.

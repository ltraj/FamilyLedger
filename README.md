# FamilyLedger

A personal ledger for tracking running balances between you and the people
you exchange money with — advances given, expenses paid on their behalf,
money returned, and manual adjustments — with nothing ever stored as a
raw "balance"; every figure is derived from the transaction history at
read time.

Built with Flutter, Riverpod, Drift (SQLite), and GetIt.

## Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Folder structure](#folder-structure)
- [Architecture](#architecture)
- [Technologies used](#technologies-used)
- [Future roadmap](#future-roadmap)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Dashboard** — at-a-glance summary cards, an "Attention Center" that
  surfaces people who need follow-up, per-person overview, recent activity
  feed, and calculated quick insights.
- **People** — full CRUD for permanent/temporary contacts, archive instead
  of delete when they have history, search/sort/filter, deterministic
  per-person avatar colors.
- **Transactions** — add/edit/delete advances, expenses, returns, and
  adjustments per person, with running balance shown after every entry.
- **Reports** — an 8-section report engine: ledger-wide stats, per-person
  breakdown, category analysis, monthly trends, top lists, "own pocket"
  spend, spending trends, and plain-language generated insights.
- **Statement** — a short, jargon-free monthly summary for one person,
  meant to be read in a few seconds or screenshotted and sent to them
  directly.
- **Backup & Restore** — exports a self-contained, checksummed `.zip`
  bundle (JSON + a human-readable `ledger.csv` + `README.md`) with a
  12-step validation pipeline on import (corrupted/missing files, version
  mismatch, checksum mismatch, dangling references, and a zip-slip guard).
- **Automatic backup** — an opt-in "check on open" backup that runs on the
  configured interval to a remembered folder, then rotates old backups so
  only the newest few are kept.
- **Settings** — theme (light/dark/system) and currency selection, plus
  automatic-backup configuration.
- All balances are computed live from transaction history — there is no
  stored `balance` column anywhere in the schema.

## Screenshots

_Add screenshots here (Dashboard, People, Transactions, Reports, Statement,
Backup & Restore, Settings) — none are checked in yet._

```
docs/screenshots/dashboard.png
docs/screenshots/reports.png
docs/screenshots/statement.png
```

## Installation

Requires the Flutter SDK (`sdk: ^3.8.0`, see `pubspec.yaml`) and a configured
Android/iOS toolchain.

```bash
git clone https://github.com/ltraj/FamilyLedger.git
cd FamilyLedger
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generates app_database.g.dart
```

## Usage

```bash
flutter analyze                                # static analysis
flutter test                                   # full test suite (~275 cases)
flutter test test/path/to/some_test.dart       # a single test file
flutter run                                    # launch on a connected device/emulator
```

Regenerate Drift's generated database code any time a table under
`lib/core/database/tables/` changes, or the schema version
(`AppConstants.databaseSchemaVersion`) is bumped:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Configuration

- **Currency and theme** are user-configurable from Settings, backed by the
  single-row `Settings` table (`lib/core/database/tables/settings_table.dart`).
- **Automatic backup** (off by default) is configured from Settings →
  Automatic backup: an interval in days and a destination folder
  (`SettingsModel.autoBackupIntervalDays` / `autoBackupDirectory`).
- **Local Android SDK path** — `android/local.properties` is
  machine-specific and is not committed; Android Studio (re)generates it
  from your local SDK install.
- There are no server endpoints, API keys, or `.env` files — all data is
  local-first, stored in a single SQLite file in the app's documents
  directory.

## Folder structure

```
FamilyLedger/
├── lib/
│   ├── app/                    root shell + bottom-nav tab controller
│   ├── core/
│   │   ├── constants/            app constants, default seed data, enums
│   │   ├── database/              Drift schema (tables/migrations/mappers)
│   │   ├── services/               GetIt composition root
│   │   ├── theme/                  Material 3 theme
│   │   └── utils/                   balance calculator, formatters, aggregator
│   ├── models/                 hand-written domain models (Person, Category, Transaction, ...)
│   ├── projections/             read-models composed from repository data (never persisted)
│   ├── repositories/            repository interfaces + Drift-backed impls
│   ├── providers/               bridges GetIt singletons into Riverpod
│   ├── backup/                  backup/restore orchestration + auto-backup service
│   ├── export/                  self-contained export-bundle construction
│   └── features/                 one package per tab: dashboard, people, reports,
│                                  transactions, backup, settings, statement
├── test/                      ~275 test cases mirroring the lib/ structure
├── android/                   the real Flutter Android module (Gradle project)
└── pubspec.yaml
```

## Architecture

```
UI (Widgets, ConsumerWidget/ConsumerStatefulWidget)
   ↓ ref.watch / ref.read
Riverpod Providers & ViewModels (StateNotifier / Notifier, per feature)
   ↓ calls interface methods
Repository Interfaces (lib/repositories/*.dart — abstract interface class)
   ↓ implemented by
Repository Implementations (lib/repositories/impl/*.dart)
   ↓ query directly against
Drift AppDatabase (generated table accessors)
   ↓ backed by
SQLite (via sqlite3_flutter_libs, NativeDatabase.createInBackground)
```

Key decisions:

- **No DAO layer** — repository implementations query Drift's generated
  table accessors directly; the repository interface *is* the data-access
  boundary.
- **GetIt is the composition root, Riverpod is the consumption layer** —
  every concrete singleton (database, repositories, backup/export services)
  is registered once via `registerLazySingleton`; Riverpod providers only
  re-expose those singletons and add reactivity (`StreamProvider`,
  `FutureProvider`) on top.
- **Balances are never stored** — `BalanceCalculator` derives every balance
  figure at read time from the full transaction history.
- **Projections are the read-model layer** — feature-level aggregators
  (`DashboardAggregator`, `ReportEngine`, `StatementEngine`, ...) join
  repository data into projection objects; screens never build display
  logic directly off raw models.

Reactive screens (Dashboard, People, Transactions) subscribe via Drift
`.watch()` streams, so a write from anywhere in the app — including
restore — propagates to every open screen automatically, with no manual
refresh.

## Technologies used

- **Flutter** / **Dart** (`sdk: ^3.8.0`)
- **flutter_riverpod** — state management / ViewModels
- **get_it** — dependency injection / composition root
- **drift** + **sqlite3_flutter_libs** — type-safe SQLite ORM
- **path_provider** / **path** — filesystem paths for the DB and exports
- **archive** — ZIP creation/extraction for backup bundles
- **file_picker** — native folder/file picker for backup export/restore
- **crypto** — SHA-256 checksums for export integrity
- **flutter_lints** + custom `analysis_options.yaml` rules
- **build_runner** / **drift_dev** — code generation for the database layer

## Future roadmap

- Expand Settings beyond theme/currency/auto-backup (e.g. notification
  preferences, data-retention options).
- Direct unit tests for the remaining coverage gaps: several core
  formatters/utilities, backup/export service implementations in isolation,
  and lower-level feature widgets currently exercised only indirectly
  through their parent screen's widget test (see `PROJECT_CONTEXT.md` §8).
- iOS build/signing configuration (currently exercised on Android only).
- Optional cloud backup destination alongside the existing local-folder
  automatic backup.

## Contributing

Contributions are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md) for the
workflow and quality gate (`flutter analyze` + `flutter test`).

## License

Released under the [MIT License](LICENSE).

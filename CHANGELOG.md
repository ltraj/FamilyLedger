# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased] - 2026-07-23

### Added

- **Settings screen is now fully functional** (previously a stub): theme
  selection, currency selection (`supported_currencies.dart`), and an
  automatic-backup configuration sheet.
- **Automatic backup**: `AutoBackupService` runs a "check on open" backup
  when due, through the same export pipeline as the manual Backup & Restore
  screen, then rotates old backups via `BackupRotationPolicy` so only the
  newest few are kept.
- **Statement feature**: a per-person, jargon-free monthly statement
  (`StatementScreen`) meant to be read at a glance or screenshotted and sent
  directly to the person it concerns — distinct from the full Transaction
  list.
- Test coverage for all of the above (`auto_backup_policy_test.dart`,
  `auto_backup_service_test.dart`, `backup_rotation_policy_test.dart`,
  `settings_screen_test.dart`, `statement_engine_test.dart`).

### Changed

- Rewrote README to reflect actual current functionality (Dashboard, People,
  Reports, Transactions, Backup & Restore, Settings, and Statement are all
  implemented) instead of the stale "Phase 1, no UI" description.

### Fixed

- Removed a stray, unused native Android Studio module (`app/`, root-level
  `gradle/`/`gradlew`/`settings.gradle.kts`) that was accidentally committed
  alongside the real Flutter project and never referenced by its build.
- Stopped tracking Gradle build-cache/daemon state (`.gradle/`,
  `android/.gradle/`) that had been committed by mistake.

## [1.0.0] - 2026-07-11

### Added

- Initial commit: Drift/SQLite database (schema v1), domain models,
  repository layer, dependency injection (GetIt), and balance-calculation
  utilities.

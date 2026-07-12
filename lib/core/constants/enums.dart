/// Whether a person is a long-term or short-term contact in the ledger.
enum PersonType {
  /// A long-term contact (e.g. family member).
  permanent,

  /// A short-term contact (e.g. one-time helper).
  temporary,
}

/// Lifecycle state of a person record.
enum PersonStatus {
  /// Person is visible and can receive new transactions.
  active,

  /// Person is hidden from active lists; transactions are preserved.
  archived,
}

/// Type of financial movement in the ledger.
enum TransactionType {
  /// Money received in advance from a person.
  advanceReceived,

  /// Expense paid using advance money (or own money if balance is negative).
  expensePaid,

  /// Money returned to the person.
  moneyReturned,

  /// Manual correction to the balance (positive or negative).
  adjustment,
}

/// Application theme preference.
enum AppThemeMode {
  /// Follow system setting.
  system,

  /// Light theme.
  light,

  /// Dark theme.
  dark,
}

/// How often automatic backups should be created.
enum BackupFrequency {
  /// No automatic backups.
  never,

  /// Backup once per day.
  daily,

  /// Backup once per week.
  weekly,

  /// Backup once per month.
  monthly,
}

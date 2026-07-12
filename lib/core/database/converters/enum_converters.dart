import 'package:drift/drift.dart';
import 'package:family_ledger/core/constants/enums.dart';

/// Drift type converter for [PersonType].
class PersonTypeConverter extends TypeConverter<PersonType, String> {
  const PersonTypeConverter();

  @override
  PersonType fromSql(String fromDb) {
    return PersonType.values.firstWhere(
      (value) => value.name == fromDb,
      orElse: () => PersonType.permanent,
    );
  }

  @override
  String toSql(PersonType value) => value.name;
}

/// Drift type converter for [PersonStatus].
class PersonStatusConverter extends TypeConverter<PersonStatus, String> {
  const PersonStatusConverter();

  @override
  PersonStatus fromSql(String fromDb) {
    return PersonStatus.values.firstWhere(
      (value) => value.name == fromDb,
      orElse: () => PersonStatus.active,
    );
  }

  @override
  String toSql(PersonStatus value) => value.name;
}

/// Drift type converter for [TransactionType].
class TransactionTypeConverter extends TypeConverter<TransactionType, String> {
  const TransactionTypeConverter();

  @override
  TransactionType fromSql(String fromDb) {
    return TransactionType.values.firstWhere(
      (value) => value.name == fromDb,
      orElse: () => TransactionType.expensePaid,
    );
  }

  @override
  String toSql(TransactionType value) => value.name;
}

/// Drift type converter for [AppThemeMode].
class AppThemeModeConverter extends TypeConverter<AppThemeMode, String> {
  const AppThemeModeConverter();

  @override
  AppThemeMode fromSql(String fromDb) {
    return AppThemeMode.values.firstWhere(
      (value) => value.name == fromDb,
      orElse: () => AppThemeMode.system,
    );
  }

  @override
  String toSql(AppThemeMode value) => value.name;
}

/// Drift type converter for [BackupFrequency].
class BackupFrequencyConverter extends TypeConverter<BackupFrequency, String> {
  const BackupFrequencyConverter();

  @override
  BackupFrequency fromSql(String fromDb) {
    return BackupFrequency.values.firstWhere(
      (value) => value.name == fromDb,
      orElse: () => BackupFrequency.never,
    );
  }

  @override
  String toSql(BackupFrequency value) => value.name;
}

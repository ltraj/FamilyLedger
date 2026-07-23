import 'package:drift/drift.dart';
import 'package:family_ledger/core/database/app_database.dart';
import 'package:family_ledger/models/app_info_model.dart';
import 'package:family_ledger/models/backup_model.dart';
import 'package:family_ledger/models/category_model.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/models/settings_model.dart';
import 'package:family_ledger/models/transaction_model.dart';

/// Maps Drift entity rows to immutable domain models.
abstract final class EntityMappers {
  static PersonModel toPerson(PersonEntity entity) {
    return PersonModel(
      id: entity.id,
      name: entity.name,
      photoPath: entity.photoPath,
      type: entity.type,
      status: entity.status,
      avatarSeed: entity.avatarSeed,
      displayOrder: entity.displayOrder,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  static CategoryModel toCategory(CategoryEntity entity) {
    return CategoryModel(
      id: entity.id,
      name: entity.name,
      icon: entity.icon,
      color: entity.color,
      isDefault: entity.isDefault,
      createdAt: entity.createdAt,
    );
  }

  static TransactionModel toTransaction(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      personId: entity.personId,
      amount: entity.amount,
      transactionType: entity.transactionType,
      categoryId: entity.categoryId,
      remark: entity.remark,
      attachmentPath: entity.attachmentPath,
      date: entity.date,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  static SettingsModel toSettings(SettingsEntity entity) {
    return SettingsModel(
      theme: entity.theme,
      currency: entity.currency,
      backupFrequency: entity.backupFrequency,
      autoBackupIntervalDays: entity.autoBackupIntervalDays,
      autoBackupDirectory: entity.autoBackupDirectory,
    );
  }

  static BackupModel toBackup(BackupEntity entity) {
    return BackupModel(
      id: entity.id,
      backupDate: entity.backupDate,
      backupPath: entity.backupPath,
      backupSize: entity.backupSize,
    );
  }

  static AppInfoModel toAppInfo(AppInfoEntity entity) {
    return AppInfoModel(
      id: entity.id,
      databaseVersion: entity.databaseVersion,
      appVersion: entity.appVersion,
      createdAt: entity.createdAt,
      lastBackup: entity.lastBackup,
      lastRestore: entity.lastRestore,
      installationId: entity.installationId,
      deviceName: entity.deviceName,
    );
  }

  static PeopleCompanion toPersonCompanion(PersonModel model) {
    return PeopleCompanion(
      id: model.id == null ? const Value.absent() : Value(model.id!),
      name: Value(model.name),
      photoPath: Value(model.photoPath),
      type: Value(model.type),
      status: Value(model.status),
      avatarSeed: Value(model.avatarSeed),
      displayOrder: Value(model.displayOrder),
      createdAt: Value(model.createdAt),
      updatedAt: Value(model.updatedAt),
    );
  }

  static CategoriesCompanion toCategoryCompanion(CategoryModel model) {
    return CategoriesCompanion(
      id: model.id == null ? const Value.absent() : Value(model.id!),
      name: Value(model.name),
      icon: Value(model.icon),
      color: Value(model.color),
      isDefault: Value(model.isDefault),
      createdAt: Value(model.createdAt),
    );
  }

  static TransactionsCompanion toTransactionCompanion(TransactionModel model) {
    return TransactionsCompanion(
      id: model.id == null ? const Value.absent() : Value(model.id!),
      personId: Value(model.personId),
      amount: Value(model.amount),
      transactionType: Value(model.transactionType),
      categoryId: Value(model.categoryId),
      remark: Value(model.remark),
      attachmentPath: Value(model.attachmentPath),
      date: Value(model.date),
      createdAt: Value(model.createdAt),
      updatedAt: Value(model.updatedAt),
    );
  }

  static SettingsCompanion toSettingsCompanion(SettingsModel model) {
    return SettingsCompanion(
      theme: Value(model.theme),
      currency: Value(model.currency),
      backupFrequency: Value(model.backupFrequency),
      // Wrapped in Value even when null: writing null is how "turn
      // automatic backup off" persists, so Value.absent would silently
      // make the setting impossible to clear.
      autoBackupIntervalDays: Value(model.autoBackupIntervalDays),
      autoBackupDirectory: Value(model.autoBackupDirectory),
    );
  }

  static BackupsCompanion toBackupCompanion(BackupModel model) {
    return BackupsCompanion(
      id: model.id == null ? const Value.absent() : Value(model.id!),
      backupDate: Value(model.backupDate),
      backupPath: Value(model.backupPath),
      backupSize: Value(model.backupSize),
    );
  }

  static AppInfoCompanion toAppInfoCompanion(AppInfoModel model) {
    return AppInfoCompanion(
      id: model.id == null ? const Value.absent() : Value(model.id!),
      databaseVersion: Value(model.databaseVersion),
      appVersion: Value(model.appVersion),
      createdAt: Value(model.createdAt),
      lastBackup: Value(model.lastBackup),
      lastRestore: Value(model.lastRestore),
      installationId: Value(model.installationId),
      deviceName: Value(model.deviceName),
    );
  }
}

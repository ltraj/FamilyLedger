import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/models/category_model.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/models/settings_model.dart';
import 'package:family_ledger/models/transaction_model.dart';

/// Converts parsed export-bundle JSON (export field names, e.g.
/// `personIdentifier`) back into the app's domain models (internal field
/// names, e.g. `id`).
///
/// The reverse of `lib/export/converters/impl/*_export_mapper_impl.dart`.
/// Pure and stateless — no I/O, no database access. `photoPath` and
/// `attachmentPath` on the returned models are left as the bare file name
/// from the bundle (e.g. `person_12.jpg`), not yet a real device path:
/// resolving those against the app's actual attachment storage directory
/// is [RestoreService]'s job, done once the files have actually been
/// copied there.
abstract final class ImportConverters {
  static PersonModel toPerson(Map<String, dynamic> json) {
    return PersonModel(
      id: json['personIdentifier'] as int,
      name: json['fullName'] as String,
      photoPath: json['photographFileName'] as String?,
      type: PersonType.values.byName(json['contactType'] as String),
      status: PersonStatus.values.byName(json['lifecycleStatus'] as String),
      avatarSeed: json['avatarColorSeed'] as int?,
      displayOrder: json['sortPosition'] as int,
      createdAt: DateTime.parse(json['recordCreatedAt'] as String),
      updatedAt: DateTime.parse(json['recordUpdatedAt'] as String),
    );
  }

  static CategoryModel toCategory(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['categoryIdentifier'] as int,
      name: json['categoryName'] as String,
      icon: json['iconIdentifier'] as String,
      color: json['colorHexCode'] as String,
      isDefault: json['isSystemDefinedDefault'] as bool,
      createdAt: DateTime.parse(json['recordCreatedAt'] as String),
    );
  }

  static TransactionModel toTransaction(Map<String, dynamic> json) {
    final transactionType = TransactionType.values.byName(
      json['transactionType'] as String,
    );
    final signedAmount = (json['amount'] as num).toDouble();

    return TransactionModel(
      id: json['transactionIdentifier'] as int,
      personId: json['personIdentifier'] as int,
      amount: transactionType == TransactionType.expensePaid
          ? -signedAmount
          : signedAmount,
      transactionType: transactionType,
      categoryId: json['categoryIdentifier'] as int?,
      remark: json['remark'] as String?,
      attachmentPath: json['attachmentFileName'] as String?,
      date: DateTime.parse(json['transactionDate'] as String),
      createdAt: DateTime.parse(json['recordCreatedAt'] as String),
      updatedAt: DateTime.parse(json['recordUpdatedAt'] as String),
    );
  }

  static SettingsModel toSettings(Map<String, dynamic> json) {
    return SettingsModel(
      theme: AppThemeMode.values.byName(json['themePreference'] as String),
      currency: json['currencyCode'] as String,
      backupFrequency: BackupFrequency.values.byName(
        json['automaticBackupFrequency'] as String,
      ),
      // The export bundle deliberately does not carry the automatic-backup
      // interval or folder (the bundle format is unchanged since v1, and
      // a backup may be restored on a different device where the old
      // folder path would be meaningless or, worse, silently wrong).
      // `as int?`/`as String?` tolerate the fields being absent, so every
      // existing backup imports unchanged, and a restore always lands
      // with automatic backup OFF until the user re-enables it.
      autoBackupIntervalDays: json['autoBackupIntervalDays'] as int?,
      autoBackupDirectory: json['autoBackupDirectory'] as String?,
    );
  }
}

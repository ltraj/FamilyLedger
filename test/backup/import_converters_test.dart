import 'package:family_ledger/backup/converters/import_converters.dart';
import 'package:family_ledger/core/constants/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImportConverters.toPerson', () {
    test('maps every export field back to the domain field', () {
      final person = ImportConverters.toPerson({
        'personIdentifier': 7,
        'fullName': 'Nani',
        'contactType': 'permanent',
        'lifecycleStatus': 'active',
        'photographFileName': 'person_7.png',
        'sortPosition': 3000,
        'avatarColorSeed': 42,
        'recordCreatedAt': '2026-01-01T00:00:00.000',
        'recordUpdatedAt': '2026-02-01T00:00:00.000',
      });

      expect(person.id, 7);
      expect(person.name, 'Nani');
      expect(person.type, PersonType.permanent);
      expect(person.status, PersonStatus.active);
      expect(person.photoPath, 'person_7.png');
      expect(person.displayOrder, 3000);
      expect(person.avatarSeed, 42);
    });

    test('handles a null photograph and avatar seed', () {
      final person = ImportConverters.toPerson({
        'personIdentifier': 1,
        'fullName': 'No Photo',
        'contactType': 'temporary',
        'lifecycleStatus': 'archived',
        'photographFileName': null,
        'sortPosition': 0,
        'avatarColorSeed': null,
        'recordCreatedAt': '2026-01-01T00:00:00.000',
        'recordUpdatedAt': '2026-01-01T00:00:00.000',
      });

      expect(person.photoPath, isNull);
      expect(person.avatarSeed, isNull);
    });
  });

  group('ImportConverters.toCategory', () {
    test('maps every export field back to the domain field', () {
      final category = ImportConverters.toCategory({
        'categoryIdentifier': 3,
        'categoryName': 'Groceries',
        'iconIdentifier': 'shopping_cart',
        'colorHexCode': '#FF9800',
        'isSystemDefinedDefault': true,
        'recordCreatedAt': '2026-01-01T00:00:00.000',
      });

      expect(category.id, 3);
      expect(category.name, 'Groceries');
      expect(category.icon, 'shopping_cart');
      expect(category.color, '#FF9800');
      expect(category.isDefault, isTrue);
    });
  });

  group('ImportConverters.toTransaction', () {
    test('undoes the sign flip export applies to expensePaid', () {
      final transaction = ImportConverters.toTransaction({
        'transactionIdentifier': 1,
        'personIdentifier': 10,
        'categoryIdentifier': null,
        'transactionType': 'expensePaid',
        'amount': -200.0,
        'remark': null,
        'attachmentFileName': null,
        'transactionDate': '2026-01-01T00:00:00.000',
        'runningBalance': null,
        'recordCreatedAt': '2026-01-01T00:00:00.000',
        'recordUpdatedAt': '2026-01-01T00:00:00.000',
      });

      // Domain model amount is stored as a positive magnitude for
      // expensePaid; only the export's signed amount is negative.
      expect(transaction.amount, 200.0);
      expect(transaction.transactionType, TransactionType.expensePaid);
    });

    test('leaves advanceReceived/moneyReturned/adjustment amounts as-is', () {
      for (final type in [
        'advanceReceived',
        'moneyReturned',
        'adjustment',
      ]) {
        final transaction = ImportConverters.toTransaction({
          'transactionIdentifier': 1,
          'personIdentifier': 10,
          'categoryIdentifier': null,
          'transactionType': type,
          'amount': 75.0,
          'remark': null,
          'attachmentFileName': null,
          'transactionDate': '2026-01-01T00:00:00.000',
          'runningBalance': null,
          'recordCreatedAt': '2026-01-01T00:00:00.000',
          'recordUpdatedAt': '2026-01-01T00:00:00.000',
        });

        expect(transaction.amount, 75.0, reason: 'type: $type');
      }
    });
  });

  group('ImportConverters.toSettings', () {
    test('maps every export field back to the domain field', () {
      final settings = ImportConverters.toSettings({
        'themePreference': 'dark',
        'currencyCode': 'INR',
        'automaticBackupFrequency': 'weekly',
      });

      expect(settings.theme, AppThemeMode.dark);
      expect(settings.currency, 'INR');
      expect(settings.backupFrequency, BackupFrequency.weekly);
    });
  });
}

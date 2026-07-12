import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/export/converters/impl/category_export_mapper_impl.dart';
import 'package:family_ledger/export/converters/impl/person_export_mapper_impl.dart';
import 'package:family_ledger/export/converters/impl/transaction_export_mapper_impl.dart';
import 'package:family_ledger/models/category_model.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PersonExportMapperImpl', () {
    const mapper = PersonExportMapperImpl();

    test('maps every field to a descriptive export name', () {
      final person = PersonModel(
        id: 7,
        name: 'Nani',
        type: PersonType.permanent,
        status: PersonStatus.active,
        avatarSeed: 42,
        displayOrder: 3000,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 2, 1),
      );

      final exported = mapper.toExportModel(person);

      expect(exported.personIdentifier, 7);
      expect(exported.fullName, 'Nani');
      expect(exported.contactType, 'permanent');
      expect(exported.lifecycleStatus, 'active');
      expect(exported.sortPosition, 3000);
      expect(exported.avatarColorSeed, 42);
      expect(exported.photographFileName, isNull);
    });

    test('derives a photograph file name from the photo path', () {
      final person = PersonModel(
        id: 9,
        name: 'Sudha',
        photoPath: '/data/photos/9.png',
        type: PersonType.temporary,
        status: PersonStatus.archived,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final exported = mapper.toExportModel(person);
      final attachment = mapper.attachmentReferenceFor(person);

      expect(exported.photographFileName, 'person_9.png');
      expect(attachment?.exportedFileName, 'person_9.png');
      expect(attachment?.sourceFilePath, '/data/photos/9.png');
    });

    test('returns no attachment reference when there is no photo', () {
      final person = PersonModel(
        id: 1,
        name: 'No Photo',
        type: PersonType.permanent,
        status: PersonStatus.active,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(mapper.attachmentReferenceFor(person), isNull);
    });
  });

  group('CategoryExportMapperImpl', () {
    const mapper = CategoryExportMapperImpl();

    test('maps every field to a descriptive export name', () {
      final category = CategoryModel(
        id: 3,
        name: 'Groceries',
        icon: 'shopping_cart',
        color: '#FF9800',
        isDefault: true,
        createdAt: DateTime(2026, 1, 1),
      );

      final exported = mapper.toExportModel(category);

      expect(exported.categoryIdentifier, 3);
      expect(exported.categoryName, 'Groceries');
      expect(exported.iconIdentifier, 'shopping_cart');
      expect(exported.colorHexCode, '#FF9800');
      expect(exported.isSystemDefinedDefault, isTrue);
    });
  });

  group('TransactionExportMapperImpl', () {
    const mapper = TransactionExportMapperImpl();

    test('exports a positive signed amount for advanceReceived', () {
      final transaction = TransactionModel(
        id: 1,
        personId: 1,
        amount: 500,
        transactionType: TransactionType.advanceReceived,
        date: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final exported = mapper.toExportModel(transaction);

      expect(exported.amount, 500);
    });

    test('exports a negative signed amount for expensePaid', () {
      final transaction = TransactionModel(
        id: 1,
        personId: 1,
        amount: 200,
        transactionType: TransactionType.expensePaid,
        date: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final exported = mapper.toExportModel(transaction);

      expect(exported.amount, -200);
    });

    test('passes an adjustment amount through unchanged, sign included', () {
      final transaction = TransactionModel(
        id: 1,
        personId: 1,
        amount: -50,
        transactionType: TransactionType.adjustment,
        date: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final exported = mapper.toExportModel(transaction);

      expect(exported.amount, -50);
    });

    test('carries through an explicit running balance', () {
      final transaction = TransactionModel(
        id: 1,
        personId: 1,
        amount: 100,
        transactionType: TransactionType.advanceReceived,
        date: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final exported = mapper.toExportModel(transaction, runningBalance: 350);

      expect(exported.runningBalance, 350);
    });

    test('derives an attachment file name from the attachment path', () {
      final transaction = TransactionModel(
        id: 4,
        personId: 1,
        amount: 100,
        transactionType: TransactionType.expensePaid,
        attachmentPath: '/data/receipts/4.jpg',
        date: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final exported = mapper.toExportModel(transaction);
      final attachment = mapper.attachmentReferenceFor(transaction);

      expect(exported.attachmentFileName, 'transaction_4.jpg');
      expect(attachment?.exportedFileName, 'transaction_4.jpg');
    });
  });
}

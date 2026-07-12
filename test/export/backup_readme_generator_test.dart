import 'package:family_ledger/export/models/export_metadata_model.dart';
import 'package:family_ledger/export/services/backup_readme_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackupReadmeGenerator', () {
    late ExportMetadataModel metadata;

    setUp(() {
      metadata = ExportMetadataModel(
        exportFormatVersion: 1,
        exportGeneratedAt: DateTime(2026, 8, 14, 18, 30),
        applicationVersion: '1.0.0+1',
        databaseSchemaVersion: 5,
        installationIdentifier: 'install-123',
        timezone: 'IST (UTC+05:30)',
        currencyCode: 'INR',
        totalPeopleCount: 2,
        totalTransactionCount: 0,
        totalCategoryCount: 3,
        checksum: 'deadbeef',
        includedFiles: const [],
      );
    });

    test('mentions record counts even when zero', () {
      final readme = BackupReadmeGenerator.generate(
        metadata: metadata,
        peopleCount: 2,
        transactionCount: 0,
        categoryCount: 3,
        attachmentCount: 0,
        currencyCode: 'INR',
      );

      expect(readme, contains('Number of transactions: 0'));
      expect(readme, contains('Number of attachments: 0'));
      expect(readme, contains('Number of people: 2'));
    });

    test('includes application version, database version, and currency', () {
      final readme = BackupReadmeGenerator.generate(
        metadata: metadata,
        peopleCount: 2,
        transactionCount: 5,
        categoryCount: 3,
        attachmentCount: 1,
        currencyCode: 'INR',
      );

      expect(readme, contains('1.0.0+1'));
      expect(readme, contains('Database version: 5'));
      expect(readme, contains('Currency: INR'));
      expect(readme, contains('UTF-8'));
    });

    test('names every exported file with a short explanation', () {
      final readme = BackupReadmeGenerator.generate(
        metadata: metadata,
        peopleCount: 2,
        transactionCount: 5,
        categoryCount: 3,
        attachmentCount: 1,
        currencyCode: 'INR',
      );

      for (final fileName in [
        'metadata.json',
        'schema.json',
        'people.json',
        'transactions.json',
        'categories.json',
        'settings.json',
        'app_info.json',
        'ledger.csv',
      ]) {
        expect(readme, contains(fileName));
      }
    });

    test('includes restore instructions', () {
      final readme = BackupReadmeGenerator.generate(
        metadata: metadata,
        peopleCount: 2,
        transactionCount: 5,
        categoryCount: 3,
        attachmentCount: 1,
        currencyCode: 'INR',
      );

      expect(readme.toLowerCase(), contains('restore'));
      expect(readme.toLowerCase(), contains('replace'));
    });
  });
}

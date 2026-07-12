import 'package:family_ledger/core/constants/app_constants.dart';
import 'package:family_ledger/export/models/export_metadata_model.dart';

/// Generates `README.md` for a backup bundle: a plain-language summary
/// and restore instructions, so the bundle is self-explanatory even to
/// someone who has never used Family Ledger, opening it years from now.
abstract final class BackupReadmeGenerator {
  static String generate({
    required ExportMetadataModel metadata,
    required int peopleCount,
    required int transactionCount,
    required int categoryCount,
    required int attachmentCount,
    required String currencyCode,
  }) {
    final generatedAt = _formatDateTime(metadata.exportGeneratedAt);

    final buffer = StringBuffer()
      ..writeln('# ${AppConstants.appName} Backup')
      ..writeln()
      ..writeln(
        'This is a complete backup of your ${AppConstants.appName} data — '
        'plain JSON and CSV files, readable without the app installed, '
        'and meant to stay readable for years.',
      )
      ..writeln()
      ..writeln('## Summary')
      ..writeln()
      ..writeln('- Application: ${AppConstants.appName}')
      ..writeln('- Application version: ${metadata.applicationVersion}')
      ..writeln('- Database version: ${metadata.databaseSchemaVersion}')
      ..writeln('- Backup date: $generatedAt')
      ..writeln('- Export date: $generatedAt')
      ..writeln('- Number of people: $peopleCount')
      ..writeln('- Number of transactions: $transactionCount')
      ..writeln('- Number of categories: $categoryCount')
      ..writeln('- Number of attachments: $attachmentCount')
      ..writeln('- Currency: $currencyCode')
      ..writeln('- Encoding: UTF-8')
      ..writeln()
      ..writeln('## How to restore')
      ..writeln()
      ..writeln('1. Install ${AppConstants.appName}.')
      ..writeln('2. Open **Settings → Backup & Restore → Import Backup**.')
      ..writeln('3. Select this ZIP file.')
      ..writeln(
        '4. Confirm when asked — this **replaces every record currently '
        'in the app** with what is in this backup.',
      )
      ..writeln()
      ..writeln('## What is in this backup')
      ..writeln()
      ..writeln(
        '- `metadata.json` — describes this backup itself (versions, '
        'device, record counts). Read this file first.',
      )
      ..writeln(
        '- `schema.json` — explains every field in every file below, so '
        'this data is understandable without reading the app\'s source '
        'code.',
      )
      ..writeln('- `people.json` — every person tracked in the ledger.')
      ..writeln(
        '- `transactions.json` — every financial movement, with a '
        'signed amount and a running balance.',
      )
      ..writeln('- `categories.json` — every expense category.')
      ..writeln(
        '- `settings.json` — this installation\'s preferences (theme, '
        'currency, backup frequency).',
      )
      ..writeln(
        '- `app_info.json` — this installation\'s identity and backup/'
        'restore history.',
      )
      ..writeln(
        '- `ledger.csv` — the same transactions as a spreadsheet, for '
        'Excel, LibreOffice, or Google Sheets.',
      )
      ..writeln(
        '- `attachments/` — photos and receipts referenced by the '
        'files above, if any.',
      );

    return buffer.toString();
  }

  static String _formatDateTime(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}

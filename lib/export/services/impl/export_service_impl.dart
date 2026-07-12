import 'dart:convert';

import 'package:family_ledger/core/constants/app_constants.dart';
import 'package:family_ledger/export/constants/export_constants.dart';
import 'package:family_ledger/export/models/export_metadata_model.dart';
import 'package:family_ledger/export/models/export_result_model.dart';
import 'package:family_ledger/export/models/exported_file_descriptor_model.dart';
import 'package:family_ledger/export/schema/export_schema_catalog.dart';
import 'package:family_ledger/export/services/backup_readme_generator.dart';
import 'package:family_ledger/export/services/export_checksum.dart';
import 'package:family_ledger/export/services/export_data_collector.dart';
import 'package:family_ledger/export/services/export_destination.dart';
import 'package:family_ledger/export/services/export_file_writer.dart';
import 'package:family_ledger/export/services/export_service.dart';
import 'package:family_ledger/export/services/ledger_csv_writer.dart';
import 'package:path/path.dart' as p;

/// Orchestrates a full export bundle: collects every entity via
/// [ExportDataCollector], writes each file via [ExportFileWriter], then
/// derives `ledger.csv`, `README.md`, and `metadata.json` (which must come
/// last — its checksum and record counts depend on everything else already
/// being known).
///
/// [destination] is expected to be a fresh staging folder (see
/// [LocalDirectoryExportDestination]); zipping that folder into the final
/// `.zip` backup file is the caller's responsibility (see
/// `lib/backup/services/backup_service.dart`), keeping this class ignorant
/// of ZIP concerns entirely.
class ExportServiceImpl implements ExportService {
  ExportServiceImpl({
    required ExportDataCollector collector,
    required ExportFileWriter writer,
  }) : _collector = collector,
       _writer = writer;

  final ExportDataCollector _collector;
  final ExportFileWriter _writer;

  @override
  Future<ExportResultModel> exportAll(ExportDestination destination) async {
    final people = await _collector.collectPeople();
    final categories = await _collector.collectCategories();
    final transactions = await _collector.collectTransactions();
    final settings = await _collector.collectSettings();
    final appInfo = await _collector.collectApplicationInfo();
    final attachments = await _collector.collectAttachmentReferences();

    final peopleJson = people.map((person) => person.toJson()).toList();
    final categoriesJson = categories
        .map((category) => category.toJson())
        .toList();
    final transactionsJson = transactions
        .map((transaction) => transaction.toJson())
        .toList();
    final settingsJson = settings.toJson();
    final appInfoJson = appInfo.toJson();

    await _writer.writeJsonFile(
      destination: destination,
      fileName: ExportConstants.peopleFileName,
      content: peopleJson,
    );
    await _writer.writeJsonFile(
      destination: destination,
      fileName: ExportConstants.categoriesFileName,
      content: categoriesJson,
    );
    await _writer.writeJsonFile(
      destination: destination,
      fileName: ExportConstants.transactionsFileName,
      content: transactionsJson,
    );
    await _writer.writeJsonFile(
      destination: destination,
      fileName: ExportConstants.settingsFileName,
      content: settingsJson,
    );
    await _writer.writeJsonFile(
      destination: destination,
      fileName: ExportConstants.appInfoFileName,
      content: appInfoJson,
    );
    await _writer.writeJsonFile(
      destination: destination,
      fileName: ExportConstants.schemaFileName,
      content: ExportSchemaCatalog.document.toJson(),
    );

    for (final attachment in attachments) {
      await _writer.writeAttachment(
        destination: destination,
        attachment: attachment,
      );
    }

    final personNamesById = {
      for (final person in people) person.personIdentifier: person.fullName,
    };
    final categoryNamesById = {
      for (final category in categories)
        category.categoryIdentifier: category.categoryName,
    };
    final ledgerCsv = LedgerCsvWriter.write(
      transactions: transactions,
      personNamesById: personNamesById,
      categoryNamesById: categoryNamesById,
    );
    await _writer.writeTextFile(
      destination: destination,
      fileName: ExportConstants.ledgerCsvFileName,
      content: ledgerCsv,
    );

    final checksum = ExportChecksum.combinedSha256([
      jsonEncode(peopleJson),
      jsonEncode(categoriesJson),
      jsonEncode(transactionsJson),
      jsonEncode(settingsJson),
      jsonEncode(appInfoJson),
    ]);

    final generatedAt = DateTime.now();
    final metadata = ExportMetadataModel(
      exportFormatVersion: ExportConstants.exportFormatVersion,
      exportGeneratedAt: generatedAt,
      applicationVersion: AppConstants.appVersion,
      databaseSchemaVersion: AppConstants.databaseSchemaVersion,
      installationIdentifier: appInfo.installationIdentifier,
      deviceName: appInfo.deviceName,
      timezone: _formatTimezone(generatedAt),
      currencyCode: settings.currencyCode,
      totalPeopleCount: people.length,
      totalTransactionCount: transactions.length,
      totalCategoryCount: categories.length,
      checksum: checksum,
      includedFiles: _manifest(
        peopleCount: people.length,
        categoriesCount: categories.length,
        transactionsCount: transactions.length,
        attachmentsCount: attachments.length,
      ),
    );

    await _writer.writeJsonFile(
      destination: destination,
      fileName: ExportConstants.metadataFileName,
      content: metadata.toJson(),
    );

    final readme = BackupReadmeGenerator.generate(
      metadata: metadata,
      peopleCount: people.length,
      transactionCount: transactions.length,
      categoryCount: categories.length,
      attachmentCount: attachments.length,
      currencyCode: settings.currencyCode,
    );
    await _writer.writeTextFile(
      destination: destination,
      fileName: ExportConstants.readmeFileName,
      content: readme,
    );

    final metadataPath = await destination.resolvePath(
      ExportConstants.metadataFileName,
    );

    return ExportResultModel(
      metadata: metadata,
      exportDirectoryPath: p.dirname(metadataPath),
    );
  }

  List<ExportedFileDescriptorModel> _manifest({
    required int peopleCount,
    required int categoriesCount,
    required int transactionsCount,
    required int attachmentsCount,
  }) => [
    const ExportedFileDescriptorModel(
      fileName: ExportConstants.schemaFileName,
      description: 'Explains every field in every file in this bundle.',
    ),
    ExportedFileDescriptorModel(
      fileName: ExportConstants.peopleFileName,
      description: 'Every person tracked in the ledger.',
      recordCount: peopleCount,
    ),
    ExportedFileDescriptorModel(
      fileName: ExportConstants.categoriesFileName,
      description: 'Every expense category.',
      recordCount: categoriesCount,
    ),
    ExportedFileDescriptorModel(
      fileName: ExportConstants.transactionsFileName,
      description:
          'Every financial movement between the user and a person.',
      recordCount: transactionsCount,
    ),
    const ExportedFileDescriptorModel(
      fileName: ExportConstants.settingsFileName,
      description: "This installation's preferences.",
    ),
    const ExportedFileDescriptorModel(
      fileName: ExportConstants.appInfoFileName,
      description: "This installation's identity and backup/restore history.",
    ),
    ExportedFileDescriptorModel(
      fileName: ExportConstants.ledgerCsvFileName,
      description: 'The same transactions as a spreadsheet.',
      recordCount: transactionsCount,
    ),
    const ExportedFileDescriptorModel(
      fileName: ExportConstants.readmeFileName,
      description: 'Plain-language summary and restore instructions.',
    ),
    ExportedFileDescriptorModel(
      fileName: ExportConstants.attachmentsFolderName,
      description:
          'Photos and receipts referenced by people.json and '
          'transactions.json.',
      recordCount: attachmentsCount,
    ),
  ];

  String _formatTimezone(DateTime dateTime) {
    final offset = dateTime.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.abs().inHours.toString().padLeft(2, '0');
    final minutes = (offset.abs().inMinutes % 60).toString().padLeft(2, '0');
    return '${dateTime.timeZoneName} (UTC$sign$hours:$minutes)';
  }
}

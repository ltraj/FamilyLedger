import 'package:family_ledger/core/utils/transaction_aggregator.dart';
import 'package:family_ledger/export/converters/app_info_export_mapper.dart';
import 'package:family_ledger/export/converters/category_export_mapper.dart';
import 'package:family_ledger/export/converters/impl/app_info_export_mapper_impl.dart';
import 'package:family_ledger/export/converters/impl/category_export_mapper_impl.dart';
import 'package:family_ledger/export/converters/impl/person_export_mapper_impl.dart';
import 'package:family_ledger/export/converters/impl/settings_export_mapper_impl.dart';
import 'package:family_ledger/export/converters/impl/transaction_export_mapper_impl.dart';
import 'package:family_ledger/export/converters/person_export_mapper.dart';
import 'package:family_ledger/export/converters/settings_export_mapper.dart';
import 'package:family_ledger/export/converters/transaction_export_mapper.dart';
import 'package:family_ledger/export/models/app_info_export_model.dart';
import 'package:family_ledger/export/models/attachment_reference_model.dart';
import 'package:family_ledger/export/models/category_export_model.dart';
import 'package:family_ledger/export/models/person_export_model.dart';
import 'package:family_ledger/export/models/settings_export_model.dart';
import 'package:family_ledger/export/models/transaction_export_model.dart';
import 'package:family_ledger/export/services/export_data_collector.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/models/transaction_model.dart';
import 'package:family_ledger/repositories/app_info_repository.dart';
import 'package:family_ledger/repositories/category_repository.dart';
import 'package:family_ledger/repositories/people_repository.dart';
import 'package:family_ledger/repositories/settings_repository.dart';
import 'package:family_ledger/repositories/transaction_repository.dart';

/// Gathers every piece of data an export bundle needs, via the app's
/// existing repositories and export mappers.
///
/// Caches its two repository reads (`getAll` for people and for
/// transactions) for the lifetime of one collector instance: several
/// `collect*` methods need one or both of those lists, and — especially
/// for transactions, which can run into the hundreds of thousands — this
/// avoids fetching the same rows from the database more than once per
/// export run.
class ExportDataCollectorImpl implements ExportDataCollector {
  ExportDataCollectorImpl({
    required PeopleRepository peopleRepository,
    required CategoryRepository categoryRepository,
    required TransactionRepository transactionRepository,
    required SettingsRepository settingsRepository,
    required AppInfoRepository appInfoRepository,
    this.personMapper = const PersonExportMapperImpl(),
    this.categoryMapper = const CategoryExportMapperImpl(),
    this.transactionMapper = const TransactionExportMapperImpl(),
    this.settingsMapper = const SettingsExportMapperImpl(),
    this.appInfoMapper = const AppInfoExportMapperImpl(),
  }) : _peopleRepository = peopleRepository,
       _categoryRepository = categoryRepository,
       _transactionRepository = transactionRepository,
       _settingsRepository = settingsRepository,
       _appInfoRepository = appInfoRepository;

  final PeopleRepository _peopleRepository;
  final CategoryRepository _categoryRepository;
  final TransactionRepository _transactionRepository;
  final SettingsRepository _settingsRepository;
  final AppInfoRepository _appInfoRepository;

  final PersonExportMapper personMapper;
  final CategoryExportMapper categoryMapper;
  final TransactionExportMapper transactionMapper;
  final SettingsExportMapper settingsMapper;
  final AppInfoExportMapper appInfoMapper;

  Future<List<PersonModel>>? _peopleCache;
  Future<List<PersonModel>> _people() =>
      _peopleCache ??= _peopleRepository.getAll();

  Future<List<TransactionModel>>? _transactionsCache;
  Future<List<TransactionModel>> _transactions() =>
      _transactionsCache ??= _transactionRepository.getAll();

  @override
  Future<List<PersonExportModel>> collectPeople() async {
    final people = await _people();
    return people.map(personMapper.toExportModel).toList();
  }

  @override
  Future<List<CategoryExportModel>> collectCategories() async {
    final categories = await _categoryRepository.getAll();
    return categories.map(categoryMapper.toExportModel).toList();
  }

  @override
  Future<List<TransactionExportModel>> collectTransactions() async {
    final transactions = await _transactions();
    final runningBalanceById = TransactionAggregator.runningBalancesById(
      transactions,
    );

    return [
      for (final transaction in transactions)
        transactionMapper.toExportModel(
          transaction,
          runningBalance: runningBalanceById[transaction.id],
        ),
    ];
  }

  @override
  Future<SettingsExportModel> collectSettings() async {
    final settings = await _settingsRepository.getSettings();
    return settingsMapper.toExportModel(settings);
  }

  @override
  Future<AppInfoExportModel> collectApplicationInfo() async {
    final appInfo = await _appInfoRepository.getAppInfo();
    return appInfoMapper.toExportModel(appInfo);
  }

  @override
  Future<List<AttachmentReferenceModel>> collectAttachmentReferences() async {
    final people = await _people();
    final transactions = await _transactions();

    return [
      for (final person in people)
        if (personMapper.attachmentReferenceFor(person) case final reference?)
          reference,
      for (final transaction in transactions)
        if (transactionMapper.attachmentReferenceFor(transaction)
            case final reference?)
          reference,
    ];
  }
}

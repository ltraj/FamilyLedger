import 'package:family_ledger/core/utils/balance_calculator.dart';
import 'package:family_ledger/export/converters/transaction_export_mapper.dart';
import 'package:family_ledger/export/models/attachment_reference_model.dart';
import 'package:family_ledger/export/models/transaction_export_model.dart';
import 'package:family_ledger/models/transaction_model.dart';
import 'package:path/path.dart' as p;

/// Converts a [TransactionModel] into its export representation. A pure
/// transformation of an already-loaded model — no I/O, no database
/// access.
///
/// Reuses [BalanceCalculator.signedAmount] for the sign, rather than
/// re-deriving it from [TransactionModel.transactionType] here — the
/// exact same rule the rest of the app uses to decide whether a
/// transaction adds to or subtracts from a balance.
class TransactionExportMapperImpl implements TransactionExportMapper {
  const TransactionExportMapperImpl();

  @override
  TransactionExportModel toExportModel(
    TransactionModel transaction, {
    double? runningBalance,
  }) {
    return TransactionExportModel(
      transactionIdentifier: transaction.id!,
      personIdentifier: transaction.personId,
      categoryIdentifier: transaction.categoryId,
      transactionType: transaction.transactionType.name,
      amount: BalanceCalculator.signedAmount(transaction),
      remark: transaction.remark,
      attachmentFileName: _exportedAttachmentFileName(transaction),
      transactionDate: transaction.date,
      runningBalance: runningBalance,
      recordCreatedAt: transaction.createdAt,
      recordUpdatedAt: transaction.updatedAt,
    );
  }

  @override
  AttachmentReferenceModel? attachmentReferenceFor(
    TransactionModel transaction,
  ) {
    final attachmentPath = transaction.attachmentPath;
    if (attachmentPath == null) return null;

    return AttachmentReferenceModel(
      sourceFilePath: attachmentPath,
      exportedFileName: _exportedAttachmentFileName(transaction)!,
      originatingRecordDescription:
          'Attachment for transaction dated '
          '${transaction.date.toIso8601String()}',
    );
  }

  String? _exportedAttachmentFileName(TransactionModel transaction) {
    final attachmentPath = transaction.attachmentPath;
    if (attachmentPath == null) return null;
    return 'transaction_${transaction.id}${p.extension(attachmentPath)}';
  }
}

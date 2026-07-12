import 'package:family_ledger/export/models/attachment_reference_model.dart';
import 'package:family_ledger/export/models/transaction_export_model.dart';
import 'package:family_ledger/models/transaction_model.dart';

/// Contract for converting a [TransactionModel] into its export
/// representation.
///
/// See `lib/export/converters/impl/transaction_export_mapper_impl.dart`,
/// which combines [TransactionModel.amount] with
/// [TransactionModel.transactionType] into the signed
/// [TransactionExportModel.amount], and decides the exported attachment
/// file name referenced by [attachmentReferenceFor].
abstract interface class TransactionExportMapper {
  /// Converts [transaction]. [runningBalance], if known, is passed
  /// through verbatim to [TransactionExportModel.runningBalance] — this
  /// mapper only converts a single transaction at a time, so it has no
  /// way to compute that figure itself (it needs the person's full
  /// chronological history); the caller (the data collector) is
  /// responsible for that.
  TransactionExportModel toExportModel(
    TransactionModel transaction, {
    double? runningBalance,
  });

  /// Returns the file that must be copied into the attachments folder for
  /// [transaction]'s attachment, or null if it has none.
  AttachmentReferenceModel? attachmentReferenceFor(
    TransactionModel transaction,
  );
}

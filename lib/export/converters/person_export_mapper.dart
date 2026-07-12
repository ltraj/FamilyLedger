import 'package:family_ledger/export/models/attachment_reference_model.dart';
import 'package:family_ledger/export/models/person_export_model.dart';
import 'package:family_ledger/models/person_model.dart';

/// Contract for converting a [PersonModel] into its export representation.
///
/// No implementation exists yet. A future implementation will live in
/// `lib/export/converters/impl/`, mirroring the interface/impl split used
/// by `lib/repositories/`, and will decide the exported photograph file
/// name (e.g. `person_12.jpg`) referenced by [attachmentReferenceFor].
abstract interface class PersonExportMapper {
  /// Converts [person] into the model written to people.json.
  PersonExportModel toExportModel(PersonModel person);

  /// Returns the file that must be copied into the attachments folder for
  /// [person]'s photograph, or null if [person] has no photograph.
  AttachmentReferenceModel? attachmentReferenceFor(PersonModel person);
}

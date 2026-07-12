import 'package:family_ledger/export/converters/person_export_mapper.dart';
import 'package:family_ledger/export/models/attachment_reference_model.dart';
import 'package:family_ledger/export/models/person_export_model.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:path/path.dart' as p;

/// Converts a [PersonModel] into its export representation. A pure
/// transformation of an already-loaded model — no I/O, no database
/// access.
class PersonExportMapperImpl implements PersonExportMapper {
  const PersonExportMapperImpl();

  @override
  PersonExportModel toExportModel(PersonModel person) {
    return PersonExportModel(
      personIdentifier: person.id!,
      fullName: person.name,
      contactType: person.type.name,
      lifecycleStatus: person.status.name,
      photographFileName: _exportedPhotoFileName(person),
      sortPosition: person.displayOrder,
      avatarColorSeed: person.avatarSeed,
      recordCreatedAt: person.createdAt,
      recordUpdatedAt: person.updatedAt,
    );
  }

  @override
  AttachmentReferenceModel? attachmentReferenceFor(PersonModel person) {
    final photoPath = person.photoPath;
    if (photoPath == null) return null;

    return AttachmentReferenceModel(
      sourceFilePath: photoPath,
      exportedFileName: _exportedPhotoFileName(person)!,
      originatingRecordDescription: 'Photograph for person: ${person.name}',
    );
  }

  String? _exportedPhotoFileName(PersonModel person) {
    final photoPath = person.photoPath;
    if (photoPath == null) return null;
    return 'person_${person.id}${p.extension(photoPath)}';
  }
}

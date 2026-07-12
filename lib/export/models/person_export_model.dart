/// AI- and human-readable representation of a person record, written to
/// `people.json` as part of an export bundle.
///
/// Field names are deliberately more explicit than the internal
/// `PersonModel`'s property names (e.g. `personIdentifier` instead of
/// `id`), because this model is read by people and language models outside
/// the app, not only by Dart code that already has type context. See
/// `people.json`'s entry in `schema.json` for the full meaning of every
/// field.
class PersonExportModel {
  const PersonExportModel({
    required this.personIdentifier,
    required this.fullName,
    required this.contactType,
    required this.lifecycleStatus,
    this.photographFileName,
    required this.sortPosition,
    this.avatarColorSeed,
    required this.recordCreatedAt,
    required this.recordUpdatedAt,
  });

  /// Local identifier for this person at the time of export.
  ///
  /// This is the database row ID, not a cross-device stable identifier.
  /// Cross-device identity — needed for future restore/merge across
  /// installations — is intentionally out of scope for this export design.
  final int personIdentifier;

  final String fullName;

  /// `permanent` (long-term family member) or `temporary` (short-term or
  /// one-time contact).
  final String contactType;

  /// `active` (visible, can receive new transactions) or `archived`
  /// (hidden from active lists, transaction history preserved).
  final String lifecycleStatus;

  /// File name of this person's photograph inside the export bundle's
  /// `attachments` folder, or null if no photograph was set.
  ///
  /// Never an absolute device file path — device paths are not portable
  /// across installations and would be meaningless outside this export.
  final String? photographFileName;

  /// This person's position in the user's custom sort order. Lower values
  /// sort first.
  final int sortPosition;

  /// Seed used to generate this person's avatar color and initial, if one
  /// has been explicitly assigned. Null means the app falls back to
  /// deriving it from personIdentifier instead.
  final int? avatarColorSeed;

  final DateTime recordCreatedAt;
  final DateTime recordUpdatedAt;

  Map<String, dynamic> toJson() => {
    'personIdentifier': personIdentifier,
    'fullName': fullName,
    'contactType': contactType,
    'lifecycleStatus': lifecycleStatus,
    'photographFileName': photographFileName,
    'sortPosition': sortPosition,
    'avatarColorSeed': avatarColorSeed,
    'recordCreatedAt': recordCreatedAt.toIso8601String(),
    'recordUpdatedAt': recordUpdatedAt.toIso8601String(),
  };
}

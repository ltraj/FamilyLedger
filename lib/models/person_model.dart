import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/core/utils/person_display_order.dart';

/// A person tracked in the ledger (family member, helper, etc.).
class PersonModel {
  const PersonModel({
    this.id,
    required this.name,
    this.photoPath,
    required this.type,
    required this.status,
    this.avatarSeed,
    this.displayOrder = PersonDisplayOrder.initial,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique identifier. Null when the person has not yet been persisted.
  final int? id;

  /// Display name of the person.
  final String name;

  /// Local file path to the person's photo, if any.
  final String? photoPath;

  /// Whether this is a permanent or temporary contact.
  final PersonType type;

  /// Active or archived lifecycle state.
  final PersonStatus status;

  /// Seed used to generate this person's avatar color and initial. Null
  /// until a color has been explicitly (re)generated; use
  /// [effectiveAvatarSeed] to read a value that always resolves to a
  /// stable seed.
  final int? avatarSeed;

  /// Position of this person in the user's custom sort order.
  ///
  /// Stored with gaps between consecutive people rather than as dense
  /// values — see `PersonDisplayOrder` for why, and for how a new value is
  /// computed when appending or (in a future phase) reordering.
  final int displayOrder;

  /// Timestamp when the record was created.
  final DateTime createdAt;

  /// Timestamp when the record was last updated.
  final DateTime updatedAt;

  /// The seed to use when rendering this person's avatar.
  ///
  /// Falls back to [id] when [avatarSeed] hasn't been set, so every
  /// persisted person has a stable, deterministic avatar without requiring
  /// a database backfill. [id] is stable across backup/restore, so the
  /// fallback preserves "same person, same avatar" even for rows written
  /// before [avatarSeed] existed.
  int get effectiveAvatarSeed => avatarSeed ?? id ?? 0;

  PersonModel copyWith({
    int? id,
    String? name,
    String? photoPath,
    PersonType? type,
    PersonStatus? status,
    int? avatarSeed,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PersonModel(
      id: id ?? this.id,
      name: name ?? this.name,
      photoPath: photoPath ?? this.photoPath,
      type: type ?? this.type,
      status: status ?? this.status,
      avatarSeed: avatarSeed ?? this.avatarSeed,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'photoPath': photoPath,
    'type': type.name,
    'status': status.name,
    'avatarSeed': avatarSeed,
    'displayOrder': displayOrder,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory PersonModel.fromJson(Map<String, dynamic> json) {
    return PersonModel(
      id: json['id'] as int?,
      name: json['name'] as String,
      photoPath: json['photoPath'] as String?,
      type: PersonType.values.byName(json['type'] as String),
      status: PersonStatus.values.byName(json['status'] as String),
      avatarSeed: json['avatarSeed'] as int?,
      displayOrder: json['displayOrder'] as int? ?? PersonDisplayOrder.initial,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonModel &&
          id == other.id &&
          name == other.name &&
          photoPath == other.photoPath &&
          type == other.type &&
          status == other.status &&
          avatarSeed == other.avatarSeed &&
          displayOrder == other.displayOrder &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    photoPath,
    type,
    status,
    avatarSeed,
    displayOrder,
    createdAt,
    updatedAt,
  );
}

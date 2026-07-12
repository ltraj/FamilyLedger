/// Ways the People screen can restrict which people are shown.
///
/// [permanent] and [temporary] implicitly restrict to active people —
/// archived people are only ever reached through [archived] or [all],
/// matching the requirement that archived people disappear from the
/// active list.
enum PersonFilterOption {
  all,
  permanent,
  temporary,
  archived,
  active;

  /// Label shown in the filter picker.
  String get label => switch (this) {
    PersonFilterOption.all => 'All',
    PersonFilterOption.permanent => 'Permanent',
    PersonFilterOption.temporary => 'Temporary',
    PersonFilterOption.archived => 'Archived',
    PersonFilterOption.active => 'Active',
  };
}

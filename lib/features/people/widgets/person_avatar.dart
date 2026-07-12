import 'package:family_ledger/features/people/utils/avatar_palette.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:flutter/material.dart';

/// A colored circle avatar showing a person's initial, deterministically
/// derived from `effectiveAvatarSeed` so it stays stable across restarts
/// and backup/restore.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({super.key, required this.person, this.radius = 24});

  final PersonModel person;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = AvatarPalette.colorForSeed(person.effectiveAvatarSeed);

    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        AvatarPalette.initialFor(person.name),
        style: TextStyle(
          color: AvatarPalette.onColor,
          fontWeight: FontWeight.w600,
          fontSize: radius * 0.85,
        ),
      ),
    );
  }
}

/// A preview-only avatar for a seed that may not belong to a saved person
/// yet (used by the add/edit dialog before the user has saved).
class SeedAvatarPreview extends StatelessWidget {
  const SeedAvatarPreview({
    super.key,
    required this.seed,
    required this.name,
    this.radius = 32,
  });

  final int seed;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = AvatarPalette.colorForSeed(seed);

    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        AvatarPalette.initialFor(name),
        style: TextStyle(
          color: AvatarPalette.onColor,
          fontWeight: FontWeight.w600,
          fontSize: radius * 0.85,
        ),
      ),
    );
  }
}

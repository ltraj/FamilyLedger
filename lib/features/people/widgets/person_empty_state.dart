import 'package:family_ledger/features/shared/widgets/empty_state_view.dart';
import 'package:flutter/material.dart';

/// A centered icon-in-a-circle, message, and call-to-action button, shown
/// when a People section (most notably "Temporary People") has no one in
/// it yet.
class PersonEmptyState extends StatelessWidget {
  const PersonEmptyState({
    super.key,
    required this.message,
    required this.onCreatePerson,
    this.icon = Icons.people_alt_outlined,
  });

  final String message;
  final VoidCallback onCreatePerson;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      message: message,
      buttonLabel: 'Create Person',
      onPressed: onCreatePerson,
      icon: icon,
    );
  }
}

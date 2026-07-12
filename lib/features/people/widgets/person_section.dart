import 'package:family_ledger/projections/person_summary.dart';
import 'package:flutter/material.dart';

/// An expandable, rounded-card section on the People screen (e.g.
/// "Permanent People"), showing a count badge and either its people's
/// cards or an empty state.
class PersonSection extends StatelessWidget {
  const PersonSection({
    super.key,
    required this.title,
    required this.summaries,
    required this.cardBuilder,
    required this.emptyState,
    this.initiallyExpanded = true,
  });

  final String title;
  final List<PersonSummary> summaries;
  final Widget Function(BuildContext context, PersonSummary summary)
  cardBuilder;
  final Widget emptyState;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              _CountBadge(count: summaries.length),
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            if (summaries.isEmpty)
              emptyState
            else
              for (final summary in summaries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: cardBuilder(context, summary),
                ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

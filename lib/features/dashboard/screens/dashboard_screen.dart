import 'package:family_ledger/app/app_tab_controller.dart';
import 'package:family_ledger/core/utils/friendly_date.dart';
import 'package:family_ledger/features/dashboard/providers/dashboard_view_model.dart';
import 'package:family_ledger/features/dashboard/widgets/attention_card.dart';
import 'package:family_ledger/features/dashboard/widgets/person_overview_card.dart';
import 'package:family_ledger/features/dashboard/widgets/quick_action_button.dart';
import 'package:family_ledger/features/dashboard/widgets/quick_insights_section.dart';
import 'package:family_ledger/features/dashboard/widgets/recent_activity_tile.dart';
import 'package:family_ledger/features/dashboard/widgets/select_person_sheet.dart';
import 'package:family_ledger/features/dashboard/widgets/summary_cards_row.dart';
import 'package:family_ledger/features/people/widgets/add_edit_person_dialog.dart';
import 'package:family_ledger/features/shared/widgets/empty_state_view.dart';
import 'package:family_ledger/features/transactions/screens/transaction_screen.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/projections/dashboard_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Dashboard: the application's command center. Answers "how much
/// advance am I holding, who owes me, who needs attention, what happened
/// recently, what have I spent this month" within a glance.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            // Search lives on the Reports tab (person/category/remark).
            onPressed: () =>
                ref.read(appTabProvider.notifier).select(AppTab.reports),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () =>
                ref.read(appTabProvider.notifier).select(AppTab.settings),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              FriendlyDate.format(DateTime.now()),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
              ),
            ),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: summaryAsync.when(
          data: (summary) => _DashboardBody(
            key: const ValueKey('data'),
            summary: summary,
          ),
          loading: () => const Center(
            key: ValueKey('loading'),
            child: CircularProgressIndicator(),
          ),
          error: (error, _) => Center(
            key: const ValueKey('error'),
            child: Text(
              'Something went wrong loading the dashboard.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({super.key, required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (summary.people.isEmpty) {
      return Center(
        child: EmptyStateView(
          message: 'No people yet.',
          buttonLabel: 'Create First Person',
          icon: Icons.people_alt_outlined,
          onPressed: () => AddEditPersonDialog.show(context),
        ),
      );
    }

    if (summary.people.every((person) => !person.hasTransactions)) {
      return Center(
        child: EmptyStateView(
          message: 'No transactions yet.',
          buttonLabel: 'Create First Transaction',
          icon: Icons.receipt_long_outlined,
          onPressed: () => showSelectPersonThenAddTransaction(context, ref),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const SummaryCardsRow(),
        const SizedBox(height: 20),
        _quickActions(context, ref),
        const SizedBox(height: 20),
        if (summary.attentionItems.isNotEmpty) ...[
          const _SectionHeader('Needs Attention'),
          const SizedBox(height: 8),
          for (final item in summary.attentionItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AttentionCard(
                item: item,
                onTap: () => _openTransactions(context, item.personSummary.person),
              ),
            ),
          const SizedBox(height: 12),
        ],
        const _SectionHeader('People Overview'),
        const SizedBox(height: 8),
        for (final person in summary.people)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PersonOverviewCard(
              summary: person,
              onTap: () => _openTransactions(context, person.person),
            ),
          ),
        const SizedBox(height: 12),
        if (summary.recentActivity.isNotEmpty) ...[
          const _SectionHeader('Recent Activity'),
          const SizedBox(height: 8),
          for (final activity in summary.recentActivity)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RecentActivityTile(
                details: activity,
                onTap: () => _openTransactions(context, activity.person),
              ),
            ),
          const SizedBox(height: 12),
        ],
        QuickInsightsSection(summary: summary),
      ],
    );
  }

  Widget _quickActions(BuildContext context, WidgetRef ref) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        QuickActionButton(
          label: 'Add Transaction',
          icon: Icons.add_card_outlined,
          onPressed: () => showSelectPersonThenAddTransaction(context, ref),
        ),
        QuickActionButton(
          label: 'Add Person',
          icon: Icons.person_add_alt_outlined,
          onPressed: () => AddEditPersonDialog.show(context),
        ),
        QuickActionButton(
          label: 'People',
          icon: Icons.people_outline,
          onPressed: () =>
              ref.read(appTabProvider.notifier).select(AppTab.people),
        ),
        QuickActionButton(
          label: 'Reports',
          icon: Icons.bar_chart_outlined,
          onPressed: () =>
              ref.read(appTabProvider.notifier).select(AppTab.reports),
        ),
      ],
    );
  }

  void _openTransactions(BuildContext context, PersonModel person) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => TransactionScreen(person: person),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

import 'package:family_ledger/features/reports/providers/report_filter_controller.dart';
import 'package:family_ledger/features/reports/providers/report_section_controller.dart';
import 'package:family_ledger/features/reports/providers/reports_view_model.dart';
import 'package:family_ledger/features/reports/widgets/category_analysis_section.dart';
import 'package:family_ledger/features/reports/widgets/ledger_section.dart';
import 'package:family_ledger/features/reports/widgets/monthly_analysis_section.dart';
import 'package:family_ledger/features/reports/widgets/own_pocket_section.dart';
import 'package:family_ledger/features/reports/widgets/person_analysis_section.dart';
import 'package:family_ledger/features/reports/widgets/report_filter_bar.dart';
import 'package:family_ledger/features/reports/widgets/report_insights_section.dart';
import 'package:family_ledger/features/reports/widgets/report_section_card.dart';
import 'package:family_ledger/features/reports/widgets/report_skeleton.dart';
import 'package:family_ledger/features/reports/widgets/spending_trends_section.dart';
import 'package:family_ledger/features/reports/widgets/top_lists_section.dart';
import 'package:family_ledger/projections/reports/reports_overview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Reports tab: a pinned filter bar over eight collapsible sections,
/// all derived live from transaction data by `ReportsViewModel`.
///
/// Display only — every number on this screen was computed in
/// `ReportEngine`. Filter changes rebuild the sections in place using the
/// previous data until the new result lands (`skipLoadingOnReload`), so
/// the screen never flashes back to its skeleton after first load.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(reportsViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: overviewAsync.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const ReportSkeleton(),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Something went wrong building the reports.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
        data: (overview) => CustomScrollView(
          slivers: [
            const SliverPersistentHeader(
              pinned: true,
              delegate: ReportFilterBarDelegate(),
            ),
            if (overview.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _ReportsEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList.list(
                  children: [
                    _resultCount(context, overview),
                    const SizedBox(height: 8),
                    ReportSectionCard(
                      section: ReportSection.ledger,
                      icon: Icons.account_balance_outlined,
                      child: LedgerSection(report: overview.ledger),
                    ),
                    const SizedBox(height: 12),
                    ReportSectionCard(
                      section: ReportSection.people,
                      icon: Icons.people_outline,
                      subtitle: '${overview.personReports.length} people',
                      child: PersonAnalysisSection(
                        reports: overview.personReports,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ReportSectionCard(
                      section: ReportSection.categories,
                      icon: Icons.category_outlined,
                      subtitle: '${overview.categoryReports.length} categories',
                      child: CategoryAnalysisSection(
                        reports: overview.categoryReports,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ReportSectionCard(
                      section: ReportSection.monthly,
                      icon: Icons.calendar_month_outlined,
                      subtitle: '${overview.monthlyReports.length} months',
                      child: MonthlyAnalysisSection(
                        reports: overview.monthlyReports,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ReportSectionCard(
                      section: ReportSection.topLists,
                      icon: Icons.emoji_events_outlined,
                      child: TopListsSection(report: overview.topLists),
                    ),
                    const SizedBox(height: 12),
                    ReportSectionCard(
                      section: ReportSection.ownPocket,
                      icon: Icons.account_balance_wallet_outlined,
                      child: OwnPocketSection(report: overview.ownPocket),
                    ),
                    const SizedBox(height: 12),
                    ReportSectionCard(
                      section: ReportSection.trends,
                      icon: Icons.show_chart,
                      child: SpendingTrendsSection(overview: overview),
                    ),
                    const SizedBox(height: 12),
                    ReportSectionCard(
                      section: ReportSection.insights,
                      icon: Icons.lightbulb_outline,
                      child: ReportInsightsSection(insights: overview.insights),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _resultCount(BuildContext context, ReportsOverview overview) {
    final theme = Theme.of(context);
    return Text(
      '${overview.filteredTransactionCount} transactions in view',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Shown when the current filter admits no transactions at all — with a
/// one-tap way out when it's the filters (not the ledger) that are empty.
class _ReportsEmptyState extends ConsumerWidget {
  const _ReportsEmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasActiveFilters = ref.watch(
      reportFilterProvider.select((filter) => filter.hasActiveFilters),
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.query_stats,
                size: 44,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasActiveFilters
                  ? 'No transactions match your filters.'
                  : 'No transactions yet. Reports appear as soon as you '
                        'record your first one.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (hasActiveFilters) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () =>
                    ref.read(reportFilterProvider.notifier).clearAll(),
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

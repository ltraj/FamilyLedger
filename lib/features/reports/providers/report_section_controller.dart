import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The eight Reports sections, in screen order.
enum ReportSection {
  ledger,
  people,
  categories,
  monthly,
  topLists,
  ownPocket,
  trends,
  insights;

  String get title => switch (this) {
    ReportSection.ledger => 'Current Ledger',
    ReportSection.people => 'Person Analysis',
    ReportSection.categories => 'Category Analysis',
    ReportSection.monthly => 'Monthly Analysis',
    ReportSection.topLists => 'Top Lists',
    ReportSection.ownPocket => 'Own Pocket',
    ReportSection.trends => 'Spending Trends',
    ReportSection.insights => 'Quick Insights',
  };
}

/// Which report sections are currently expanded.
///
/// App-lifetime like `reportFilterProvider`, so the user's last
/// expand/collapse arrangement survives leaving and returning to the
/// Reports tab. Starts with the ledger and insights open — the two
/// sections that answer "how am I doing" at a glance — rather than
/// everything at once.
class ReportSectionController extends Notifier<Set<ReportSection>> {
  @override
  Set<ReportSection> build() => {
    ReportSection.ledger,
    ReportSection.insights,
  };

  void toggle(ReportSection section) {
    final expanded = {...state};
    if (!expanded.remove(section)) expanded.add(section);
    state = expanded;
  }
}

final expandedReportSectionsProvider =
    NotifierProvider<ReportSectionController, Set<ReportSection>>(
      ReportSectionController.new,
    );

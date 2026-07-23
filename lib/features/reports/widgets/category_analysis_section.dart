import 'package:family_ledger/core/utils/currency_formatter.dart';
import 'package:family_ledger/core/utils/relative_date.dart';
import 'package:family_ledger/features/reports/utils/report_engine.dart';
import 'package:family_ledger/features/settings/providers/settings_view_model.dart';
import 'package:family_ledger/projections/reports/category_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Section 3: per-category figures with an Amount/Frequency/A–Z sort
/// selector. The selector re-sorts via `ReportEngine.sortCategoryReports`
/// (a pure helper); this widget itself computes nothing.
class CategoryAnalysisSection extends StatefulWidget {
  const CategoryAnalysisSection({super.key, required this.reports});

  final List<CategoryReport> reports;

  @override
  State<CategoryAnalysisSection> createState() =>
      _CategoryAnalysisSectionState();
}

class _CategoryAnalysisSectionState extends State<CategoryAnalysisSection> {
  CategoryReportSort _sort = CategoryReportSort.amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.reports.isEmpty) {
      return Text(
        'No transactions in this period.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final sorted = ReportEngine.sortCategoryReports(widget.reports, _sort);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<CategoryReportSort>(
          segments: [
            for (final option in CategoryReportSort.values)
              ButtonSegment(value: option, label: Text(option.label)),
          ],
          selected: {_sort},
          onSelectionChanged: (selection) =>
              setState(() => _sort = selection.first),
          showSelectedIcon: false,
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(height: 12),
        for (final report in sorted)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CategoryReportTile(report: report),
          ),
      ],
    );
  }
}

class _CategoryReportTile extends ConsumerWidget {
  const _CategoryReportTile({required this.report});

  final CategoryReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  report.category?.name ?? 'No category',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                CurrencyFormatter.format(report.total, symbol: currencySymbol),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${report.transactionCount} transactions · '
            'avg ${CurrencyFormatter.format(report.average, symbol: currencySymbol)} · '
            'largest ${CurrencyFormatter.format(report.largest, symbol: currencySymbol)} · '
            'smallest ${CurrencyFormatter.format(report.smallest, symbol: currencySymbol)} · '
            'last used ${RelativeDate.format(report.mostRecentDate)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:family_ledger/core/utils/balance_colors.dart';
import 'package:family_ledger/core/utils/currency_formatter.dart';
import 'package:family_ledger/features/reports/widgets/report_stat_row.dart';
import 'package:family_ledger/projections/reports/ledger_report.dart';
import 'package:flutter/material.dart';

/// Section 1: the ledger-wide money picture. Display only — every figure
/// arrives pre-computed on [LedgerReport].
class LedgerSection extends StatelessWidget {
  const LedgerSection({super.key, required this.report});

  final LedgerReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReportStatRow(
          label: 'Current Balance',
          value: CurrencyFormatter.format(report.currentBalance),
          emphasized: true,
          valueColor: BalanceColors.forBalance(
            context,
            hasTransactions: true,
            balance: report.currentBalance,
          ),
        ),
        Divider(height: 16, color: theme.colorScheme.outlineVariant),
        ReportStatRow(
          label: 'Total Advance Received',
          value: CurrencyFormatter.format(report.totalAdvanceReceived),
        ),
        ReportStatRow(
          label: 'Total Expenses',
          value: CurrencyFormatter.format(report.totalExpenses),
        ),
        ReportStatRow(
          label: 'Money Returned',
          value: CurrencyFormatter.format(report.totalMoneyReturned),
        ),
        ReportStatRow(
          label: 'Own Pocket Expenses',
          value: CurrencyFormatter.format(report.ownPocketExpenses),
          valueColor: report.ownPocketExpenses > 0
              ? BalanceColors.negative
              : null,
        ),
        if (report.totalAdjustments != 0)
          ReportStatRow(
            label: 'Adjustments',
            value: CurrencyFormatter.format(report.totalAdjustments),
          ),
        Divider(height: 16, color: theme.colorScheme.outlineVariant),
        ReportStatRow(
          label: 'Net Position (period)',
          value: CurrencyFormatter.format(report.netPosition),
          emphasized: true,
          valueColor: BalanceColors.forBalance(
            context,
            hasTransactions: true,
            balance: report.netPosition,
          ),
        ),
      ],
    );
  }
}

import 'package:family_ledger/features/reports/models/report_date_preset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A fixed "now" mid-month, mid-week, with a time of day, so boundary
  // mistakes (time-of-day leakage, month arithmetic) can't hide.
  final now = DateTime(2026, 7, 15, 14, 30);

  group('ReportDatePreset.resolve', () {
    test('allTime and custom resolve to no range', () {
      expect(ReportDatePreset.allTime.resolve(now), isNull);
      expect(ReportDatePreset.custom.resolve(now), isNull);
    });

    test('today covers exactly the current calendar day', () {
      final range = ReportDatePreset.today.resolve(now)!;

      expect(range.contains(DateTime(2026, 7, 15)), isTrue);
      expect(range.contains(DateTime(2026, 7, 15, 23, 59)), isTrue);
      expect(range.contains(DateTime(2026, 7, 14)), isFalse);
      expect(range.contains(DateTime(2026, 7, 16)), isFalse);
    });

    test('yesterday covers exactly the previous calendar day', () {
      final range = ReportDatePreset.yesterday.resolve(now)!;

      expect(range.contains(DateTime(2026, 7, 14)), isTrue);
      expect(range.contains(DateTime(2026, 7, 15)), isFalse);
      expect(range.contains(DateTime(2026, 7, 13)), isFalse);
    });

    test('last7Days includes today and the six days before it', () {
      final range = ReportDatePreset.last7Days.resolve(now)!;

      expect(range.contains(DateTime(2026, 7, 15)), isTrue);
      expect(range.contains(DateTime(2026, 7, 9)), isTrue);
      expect(range.contains(DateTime(2026, 7, 8)), isFalse);
    });

    test('last30Days includes today and the 29 days before it', () {
      final range = ReportDatePreset.last30Days.resolve(now)!;

      expect(range.contains(DateTime(2026, 7, 15)), isTrue);
      expect(range.contains(DateTime(2026, 6, 16)), isTrue);
      expect(range.contains(DateTime(2026, 6, 15)), isFalse);
    });

    test('thisMonth covers the full current calendar month', () {
      final range = ReportDatePreset.thisMonth.resolve(now)!;

      expect(range.contains(DateTime(2026, 7, 1)), isTrue);
      expect(range.contains(DateTime(2026, 7, 31)), isTrue);
      expect(range.contains(DateTime(2026, 6, 30)), isFalse);
      expect(range.contains(DateTime(2026, 8, 1)), isFalse);
    });

    test('lastMonth covers the full previous month, across year ends', () {
      final range = ReportDatePreset.lastMonth.resolve(now)!;
      expect(range.contains(DateTime(2026, 6, 1)), isTrue);
      expect(range.contains(DateTime(2026, 6, 30)), isTrue);
      expect(range.contains(DateTime(2026, 7, 1)), isFalse);

      // January → last month is December of the previous year.
      final january = DateTime(2026, 1, 10);
      final acrossYear = ReportDatePreset.lastMonth.resolve(january)!;
      expect(acrossYear.contains(DateTime(2025, 12, 25)), isTrue);
      expect(acrossYear.contains(DateTime(2026, 1, 1)), isFalse);
    });

    test('thisYear covers the full current calendar year', () {
      final range = ReportDatePreset.thisYear.resolve(now)!;

      expect(range.contains(DateTime(2026, 1, 1)), isTrue);
      expect(range.contains(DateTime(2026, 12, 31)), isTrue);
      expect(range.contains(DateTime(2025, 12, 31)), isFalse);
    });
  });
}

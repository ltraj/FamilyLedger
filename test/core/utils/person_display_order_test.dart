import 'package:family_ledger/core/utils/person_display_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PersonDisplayOrder', () {
    test('appendAfter returns initial for an empty list', () {
      expect(PersonDisplayOrder.appendAfter(null), PersonDisplayOrder.initial);
    });

    test('appendAfter adds one step past the current highest value', () {
      expect(
        PersonDisplayOrder.appendAfter(1000),
        1000 + PersonDisplayOrder.step,
      );
      expect(PersonDisplayOrder.appendAfter(0), PersonDisplayOrder.step);
    });

    test('between returns initial when the list is empty', () {
      expect(
        PersonDisplayOrder.between(null, null),
        PersonDisplayOrder.initial,
      );
    });

    test('between with only an upper bound stays below it', () {
      final value = PersonDisplayOrder.between(null, 1000);
      expect(value, lessThan(1000));
    });

    test('between with only a lower bound stays above it', () {
      final value = PersonDisplayOrder.between(1000, null);
      expect(value, greaterThan(1000));
    });

    test('between two values returns their midpoint', () {
      expect(PersonDisplayOrder.between(1000, 2000), 1500);
    });

    test('successive appendAfter calls preserve insertion order', () {
      int? highest;
      final orders = <int>[];
      for (var i = 0; i < 5; i++) {
        final next = PersonDisplayOrder.appendAfter(highest);
        orders.add(next);
        highest = next;
      }

      final sorted = [...orders]..sort();
      expect(orders, sorted);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  test(
    'a fresh database has the transactions indexes on personId, categoryId, '
    'and date',
    () async {
      final database = await createTestDatabase();
      addTearDown(database.close);

      final rows = await database
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND tbl_name = 'transactions'",
          )
          .get();
      final indexNames = [
        for (final row in rows) row.read<String>('name'),
      ];

      expect(indexNames, contains('idx_transactions_person_id'));
      expect(indexNames, contains('idx_transactions_category_id'));
      expect(indexNames, contains('idx_transactions_date'));
    },
  );
}

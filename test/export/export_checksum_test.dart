import 'package:family_ledger/export/services/export_checksum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExportChecksum', () {
    test('is deterministic for the same input', () {
      final first = ExportChecksum.combinedSha256(['a', 'b', 'c']);
      final second = ExportChecksum.combinedSha256(['a', 'b', 'c']);

      expect(first, second);
    });

    test('changes if any file content changes', () {
      final original = ExportChecksum.combinedSha256(['a', 'b', 'c']);
      final tampered = ExportChecksum.combinedSha256(['a', 'X', 'c']);

      expect(original, isNot(tampered));
    });

    test('changes if the order of files changes', () {
      final first = ExportChecksum.combinedSha256(['a', 'b']);
      final second = ExportChecksum.combinedSha256(['b', 'a']);

      expect(first, isNot(second));
    });

    test('produces a 64-character lowercase hex digest', () {
      final checksum = ExportChecksum.combinedSha256(['anything']);

      expect(checksum.length, 64);
      expect(checksum, matches(RegExp(r'^[0-9a-f]{64}$')));
    });
  });
}

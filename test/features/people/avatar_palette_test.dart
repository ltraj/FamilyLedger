import 'package:family_ledger/features/people/utils/avatar_palette.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AvatarPalette', () {
    test('colorForSeed is deterministic for the same seed', () {
      expect(AvatarPalette.colorForSeed(42), AvatarPalette.colorForSeed(42));
      expect(
        AvatarPalette.colorForSeed(123456),
        AvatarPalette.colorForSeed(123456),
      );
    });

    test('colorForSeed handles negative seeds without throwing', () {
      expect(() => AvatarPalette.colorForSeed(-7), returnsNormally);
      expect(AvatarPalette.colorForSeed(-7), AvatarPalette.colorForSeed(-7));
    });

    test('initialFor returns the first letter, uppercased and trimmed', () {
      expect(AvatarPalette.initialFor('nani'), 'N');
      expect(AvatarPalette.initialFor('  Sudha'), 'S');
      expect(AvatarPalette.initialFor(''), '?');
      expect(AvatarPalette.initialFor('   '), '?');
    });
  });
}

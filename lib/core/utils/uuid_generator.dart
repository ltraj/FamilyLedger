import 'dart:math';

/// Generates RFC 4122 version 4 UUIDs without an external dependency.
abstract final class UuidGenerator {
  static final Random _random = Random.secure();

  /// Generates a random v4 UUID string, e.g. `f47ac10b-58cc-4372-a567-0e02b2c3d479`.
  static String generate() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));

    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10

    String hex(int start, int end) => bytes
        .sublist(start, end)
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }
}

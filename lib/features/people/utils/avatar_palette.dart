import 'package:flutter/material.dart';

/// Deterministically maps a person's avatar seed and name to a color and
/// initial letter.
///
/// The palette is a fixed set of colors, independent of the app's
/// light/dark theme or any device's dynamic color scheme. That's
/// deliberate: the same person must render with the same avatar color on
/// every device, including after a backup/restore, which would break if
/// the color were derived from `Theme.of(context)`.
abstract final class AvatarPalette {
  static const List<Color> _colors = [
    Color(0xFF6750A4), // purple
    Color(0xFF2E7D32), // green
    Color(0xFF1565C0), // blue
    Color(0xFFB3261E), // red
    Color(0xFFEF6C00), // orange
    Color(0xFF00838F), // teal
    Color(0xFFAD1457), // pink
    Color(0xFF5D4037), // brown
    Color(0xFF3949AB), // indigo
    Color(0xFF00695C), // deep teal
    Color(0xFF8E24AA), // violet
    Color(0xFF546E7A), // blue grey
  ];

  /// The background color for [seed]. Always the same color for the same
  /// seed.
  static Color colorForSeed(int seed) => _colors[seed.abs() % _colors.length];

  /// The single uppercase initial shown on an avatar for [name].
  static String initialFor(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }

  /// The color text/icons should use on top of [colorForSeed], for
  /// contrast. All palette colors are mid-to-dark, so white reads clearly
  /// against every one of them.
  static const Color onColor = Colors.white;
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:x_scanner/app/theme.dart';

/// WCAG 2.2 contrast ratio of two opaque colors.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (light, dark) = la > lb ? (la, lb) : (lb, la);
  return (light + 0.05) / (dark + 0.05);
}

/// Normal text needs 4.5:1 (SC 1.4.3); icons, borders of controls and
/// focus/selection indicators need 3:1 (SC 1.4.11).
const double _text = 4.5;
const double _nonText = 3;

/// The foreground/background pairs of the [ColorScheme] that the app's
/// screens actually draw, with the ratio each needs. Card and footer
/// borders (`outlineVariant`) are decorative: cards are identified by their
/// text, so SC 1.4.11 does not apply to them.
List<(String, Color, Color, double)> _pairs(ColorScheme c) => [
  // Body text, app bar, list rows, dialogs and sheets.
  ('onSurface / surface', c.onSurface, c.surface, _text),
  (
    'onSurface / surfaceContainerLow',
    c.onSurface,
    c.surfaceContainerLow,
    _text,
  ),
  (
    'onSurface / surfaceContainerHigh (dialog)',
    c.onSurface,
    c.surfaceContainerHigh,
    _text,
  ),
  ('onSurfaceVariant / surface', c.onSurfaceVariant, c.surface, _text),
  (
    'onSurfaceVariant / surfaceContainerLow',
    c.onSurfaceVariant,
    c.surfaceContainerLow,
    _text,
  ),
  (
    'onSurfaceVariant / surfaceContainerHigh (dialog)',
    c.onSurfaceVariant,
    c.surfaceContainerHigh,
    _text,
  ),
  // Primary-colored text: page count, text and outlined buttons.
  ('primary / surface', c.primary, c.surface, _text),
  ('primary / surfaceContainerLow', c.primary, c.surfaceContainerLow, _text),
  ('primary / surfaceContainerHigh', c.primary, c.surfaceContainerHigh, _text),
  // Filled buttons, page number badge, new document button, snack bars.
  ('onPrimary / primary', c.onPrimary, c.primary, _text),
  (
    'onPrimaryContainer / primaryContainer',
    c.onPrimaryContainer,
    c.primaryContainer,
    _text,
  ),
  (
    'onErrorContainer / errorContainer',
    c.onErrorContainer,
    c.errorContainer,
    _text,
  ),
  (
    'onInverseSurface / inverseSurface',
    c.onInverseSurface,
    c.inverseSurface,
    _text,
  ),
  // Non-text: text field and outlined button borders, focus and selection.
  ('outline / surface', c.outline, c.surface, _nonText),
  ('outline / surfaceContainerLow', c.outline, c.surfaceContainerLow, _nonText),
  (
    'outline / surfaceContainerHigh',
    c.outline,
    c.surfaceContainerHigh,
    _nonText,
  ),
  ('primary (focus, selection) / surface', c.primary, c.surface, _nonText),
  (
    'onSurfaceVariant (icons) / surface',
    c.onSurfaceVariant,
    c.surface,
    _nonText,
  ),
  (
    'onPrimaryContainer (corner handle ring) / primaryContainer',
    c.onPrimaryContainer,
    c.primaryContainer,
    _nonText,
  ),
];

void main() {
  test('the contrast formula matches WCAG reference values', () {
    expect(contrast(Colors.black, Colors.white), closeTo(21, 0.01));
    expect(contrast(Colors.white, Colors.white), 1);
    // #767676 on white is the classic 4.54:1 grey.
    expect(
      contrast(const Color(0xFF767676), Colors.white),
      closeTo(4.54, 0.01),
    );
  });

  for (final brightness in Brightness.values) {
    test('every color pair the app draws meets WCAG AA in ${brightness.name} '
        'theme (UX-A11Y-002, UX-DS-003)', () {
      final colors = buildTheme(brightness).colorScheme;
      final failures = [
        for (final (name, fg, bg, min) in _pairs(colors))
          if (contrast(fg, bg) < min)
            '$name: ${contrast(fg, bg).toStringAsFixed(2)} < $min',
      ];
      expect(failures, isEmpty);
    });
  }
}

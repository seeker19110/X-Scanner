import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:x_scanner/app/theme.dart';

const String _next = 'Trang mới';

/// The app's theme with a button that pushes a page like the app does.
Widget _app(Brightness brightness) => MaterialApp(
  theme: buildTheme(brightness),
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Align(alignment: Alignment.topLeft, child: Text(_next)),
              ),
            ),
          ),
          child: const Text('Mở'),
        ),
      ),
    ),
  ),
);

/// Where the new page's text is one millisecond into the push, and once
/// the transition has ended.
Future<(Rect, Rect)> _pushAndMeasure(
  WidgetTester tester,
  Brightness brightness,
) async {
  await tester.pumpWidget(_app(brightness));
  await tester.tap(find.text('Mở'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
  final during = tester.getRect(find.text(_next));
  await tester.pumpAndSettle();
  final after = tester.getRect(find.text(_next));
  return (during, after);
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('with reduced motion a new page appears in place, without '
        'sliding or zooming, in ${brightness.name} theme (UX-VISUAL-001)', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final (during, after) = await _pushAndMeasure(tester, brightness);
      expect(during, after);
    });
  }

  testWidgets('without reduced motion the page transition still moves', (
    tester,
  ) async {
    final (during, after) = await _pushAndMeasure(tester, Brightness.dark);
    expect(during, isNot(after));
  });
}

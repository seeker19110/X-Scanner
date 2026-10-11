import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:x_scanner/main.dart';

void main() {
  testWidgets('shows the app shell in dark mode by default', (tester) async {
    await tester.pumpWidget(const XScannerApp());

    expect(find.text('X-Scanner'), findsOneWidget);
    expect(find.text('Bản nền P0 — chưa có chức năng chụp.'), findsOneWidget);

    final scaffoldContext = tester.element(find.byType(Scaffold));
    expect(Theme.of(scaffoldContext).brightness, Brightness.dark);
  });
}

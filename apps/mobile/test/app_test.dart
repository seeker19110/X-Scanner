import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:x_scanner/export/file_sharer.dart';
import 'package:x_scanner/export/page_exporter.dart';
import 'package:x_scanner/main.dart';
import 'package:x_scanner/storage/session_store.dart';
import 'package:x_scanner/ui/page_source.dart';
import 'package:x_scanner/ui/session_controller.dart';

/// A [PageSource] that never returns an image.
class _NoSource implements PageSource {
  @override
  Future<String?> capture() async => null;

  @override
  Future<String?> pickFromGallery() async => null;

  @override
  Future<String?> retrieveLost() async => null;

  @override
  Future<void> discard(String path) async {}
}

/// A [FileSharer] that shares nothing.
class _NoSharer implements FileSharer {
  @override
  Future<void> share(List<File> files) async {}
}

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('app_test'));

  tearDown(() => tmp.deleteSync(recursive: true));

  testWidgets('shows the app shell in dark mode by default', (tester) async {
    final controller = SessionController(
      store: SessionStore(tmp),
      source: _NoSource(),
      exporter: PageExporter(exportDir: Directory('${tmp.path}/exports')),
      sharer: _NoSharer(),
    );
    await tester.pumpWidget(XScannerApp(controller: controller));
    for (var i = 0; i < 100 && controller.busy; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump();
    }
    expect(controller.busy, isFalse);

    expect(find.text('X-Scanner'), findsOneWidget);
    expect(
      find.text('Chưa có trang nào. Chụp hoặc nhập ảnh để bắt đầu.'),
      findsOneWidget,
    );

    final scaffoldContext = tester.element(find.byType(Scaffold));
    expect(Theme.of(scaffoldContext).brightness, Brightness.dark);
  });
}

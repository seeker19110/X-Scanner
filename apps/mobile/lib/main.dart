import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app/theme.dart';
import 'export/file_sharer.dart';
import 'export/page_exporter.dart';
import 'imaging/decode_gate.dart';
import 'imaging/page_render.dart';
import 'storage/session_store.dart';
import 'ui/page_source.dart';
import 'ui/review_screen.dart';
import 'ui/session_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final support = await getApplicationSupportDirectory();
  final temp = await getTemporaryDirectory();
  final dir = await Directory('${support.path}/session')
      .create(recursive: true);
  // One gate for every decode of an original: thumbnails and export renders.
  final decodeGate = DecodeGate();
  runApp(
    XScannerApp(
      controller: SessionController(
        store: SessionStore(dir),
        // On Android the picker leaves its copies in the app cache.
        source: ImagePickerPageSource(cacheDir: temp),
        exporter: PageExporter(
          exportDir: Directory('${temp.path}/exports'),
          // share_plus copies shared files here and keeps the last ones.
          leftoverDirs: [Directory('${temp.path}/share_plus')],
          renderer: (path, quad, turns, {format = RenderFormat.jpeg}) =>
              decodeGate.run(
                () => renderPage(path, quad, turns, format: format),
              ),
        ),
        sharer: const SharePlusFileSharer(),
        decodeGate: decodeGate,
      ),
    ),
  );
}

/// The app: Dark blue theme by default with an in-memory Light switch.
class XScannerApp extends StatefulWidget {
  /// Creates the app around [controller], which it restores once.
  const XScannerApp({super.key, required this.controller});

  final SessionController controller;

  @override
  State<XScannerApp> createState() => _XScannerAppState();
}

class _XScannerAppState extends State<XScannerApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.restore());
  }

  void _toggleTheme() => setState(() {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'X-Scanner',
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: _themeMode,
      home: ReviewScreen(
        controller: widget.controller,
        themeMode: _themeMode,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

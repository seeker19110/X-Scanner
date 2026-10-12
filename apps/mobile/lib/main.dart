import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app/theme.dart';
import 'storage/session_store.dart';
import 'ui/page_source.dart';
import 'ui/review_screen.dart';
import 'ui/session_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final support = await getApplicationSupportDirectory();
  final dir = await Directory('${support.path}/session')
      .create(recursive: true);
  runApp(
    XScannerApp(
      controller: SessionController(
        store: SessionStore(dir),
        source: ImagePickerPageSource(),
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

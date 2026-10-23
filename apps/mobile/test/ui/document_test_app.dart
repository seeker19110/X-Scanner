import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:x_scanner/app/theme.dart';
import 'package:x_scanner/core/scan_document.dart';
import 'package:x_scanner/core/scan_session.dart';
import 'package:x_scanner/core/session_manifest.dart';
import 'package:x_scanner/imaging/page_render.dart';
import 'package:x_scanner/storage/pending_pick_store.dart';
import 'package:x_scanner/ui/review_screen.dart';
import 'package:x_scanner/ui/session_controller.dart';

/// Title of [testDocument]; the app's name, so P1 screen texts still match.
const String testDocumentTitle = 'X-Scanner';

/// Writes an empty library document under `tmp/documents` and returns it;
/// its folder is [documentDir].
ScanDocument testDocument(Directory tmp) {
  final created = DateTime.utc(2026, 10, 1);
  final document = ScanDocument(
    id: newPageId(),
    title: testDocumentTitle,
    createdAt: created,
    updatedAt: created,
  );
  final dir = documentDir(tmp, document)..createSync(recursive: true);
  File('${dir.path}/document.json').writeAsStringSync(encodeDocument(document));
  return document;
}

/// The folder of [document] made by [testDocument].
Directory documentDir(Directory tmp, ScanDocument document) =>
    Directory('${tmp.path}/documents/${document.id}');

/// Pending picker store whose cache is [cache] (where test images live).
PendingPickStore testPending(Directory tmp, Directory cache) =>
    PendingPickStore(
      dir: Directory('${tmp.path}/pending-pick'),
      cacheDir: cache,
      maxBytes: maxOriginalBytes,
    );

/// The document screen as the app shows it, with the Dark/Light switch;
/// restores [controller] once, like opening the document, unless the test
/// already did with real I/O ([restore] false). Restoring here runs under
/// the fake clock, where a later real-I/O call on the same pending store
/// would wait on it forever.
class DocumentTestApp extends StatefulWidget {
  const DocumentTestApp({
    super.key,
    required this.controller,
    this.restore = true,
  });

  final SessionController controller;
  final bool restore;

  @override
  State<DocumentTestApp> createState() => _DocumentTestAppState();
}

class _DocumentTestAppState extends State<DocumentTestApp> {
  ThemeMode _mode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    if (widget.restore) unawaited(widget.controller.restore());
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: buildTheme(Brightness.light),
    darkTheme: buildTheme(Brightness.dark),
    themeMode: _mode,
    home: ReviewScreen(
      controller: widget.controller,
      themeMode: _mode,
      onToggleTheme: () => setState(() {
        _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      }),
    ),
  );
}

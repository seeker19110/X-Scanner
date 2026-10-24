import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app/error_handling.dart';
import 'app/theme.dart';
import 'core/scan_document.dart';
import 'export/file_sharer.dart';
import 'export/page_exporter.dart';
import 'imaging/decode_gate.dart';
import 'imaging/page_render.dart';
import 'storage/android_storage.dart';
import 'storage/document_store.dart';
import 'storage/library_store.dart';
import 'storage/p1_migration.dart';
import 'storage/pending_pick_store.dart';
import 'ui/library_controller.dart';
import 'ui/library_screen.dart';
import 'ui/page_source.dart';
import 'ui/pick_import.dart';
import 'ui/review_screen.dart';
import 'ui/session_controller.dart';

/// Builds the controller of one opened library document; it restores only
/// after `after` completes.
typedef DocumentControllerFactory = SessionController Function(
  DocumentStore store,
  ScanDocument document, {
  Future<void>? after,
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installErrorHandlers();
  final support = await getApplicationSupportDirectory();
  final temp = await getTemporaryDirectory();
  final library = LibraryStore(Directory('${support.path}/documents'));
  // One gate for every decode of an original: thumbnails and export renders.
  final decodeGate = DecodeGate();
  // On Android the picker leaves its copies in the app cache.
  final source = ImagePickerPageSource(cacheDir: temp);
  final pending = PendingPickStore(
    dir: Directory('${support.path}/pending-pick'),
    cacheDir: temp,
    maxBytes: maxOriginalBytes,
  );
  final migration = P1Migration(
    appRoot: support,
    storage: AndroidStorage(appRoot: support),
  );
  final recovery = PickImporter(
    pending: pending,
    source: source,
    decode: (path) => decodeGate.run(() => thumbnail(path)),
  );
  final exporter = PageExporter(
    exportDir: Directory('${temp.path}/exports'),
    // share_plus copies shared files here and keeps the last ones.
    leftoverDirs: [Directory('${temp.path}/share_plus')],
    renderer: (path, quad, turns, {format = RenderFormat.jpeg}) =>
        decodeGate.run(() => renderPage(path, quad, turns, format: format)),
  );
  runApp(
    XScannerApp(
      library: LibraryController(
        library: library,
        migrate: migration.run,
        recover: (outcome) => recovery.recover(library, outcome),
      ),
      openDocument: (store, document, {after}) => SessionController(
        store: store,
        document: document,
        after: after,
        pending: pending,
        source: source,
        exporter: exporter,
        sharer: const SharePlusFileSharer(),
        decodeGate: decodeGate,
      ),
    ),
  );
}

/// The app: the library first, Dark blue theme by default with an
/// in-memory Light switch.
class XScannerApp extends StatefulWidget {
  /// Shows [library]; each opened document gets a controller from
  /// [openDocument], disposed when its screen closes.
  const XScannerApp({
    super.key,
    required this.library,
    required this.openDocument,
  });

  final LibraryController library;
  final DocumentControllerFactory openDocument;

  @override
  State<XScannerApp> createState() => _XScannerAppState();
}

class _XScannerAppState extends State<XScannerApp> {
  /// Read by the document screen too, whose route is not rebuilt with
  /// the app.
  final ValueNotifier<ThemeMode> _themeMode = ValueNotifier(ThemeMode.dark);

  /// The last controller of each opened document; a reopened document waits
  /// for it to finish (PR-4b.2 review F2).
  final Map<String, SessionController> _last = {};

  SessionController _open(DocumentStore store, ScanDocument document) =>
      _last[document.id] = widget.openDocument(
        store,
        document,
        after: _last[document.id]?.idle,
      );

  @override
  void dispose() {
    _themeMode.dispose();
    super.dispose();
  }

  void _toggleTheme() => _themeMode.value = _themeMode.value == ThemeMode.dark
      ? ThemeMode.light
      : ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeMode,
      builder: (context, mode, _) => MaterialApp(
        title: 'X-Scanner',
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: mode,
        home: LibraryScreen(
          controller: widget.library,
          themeMode: mode,
          onToggleTheme: _toggleTheme,
          documentScreen: (context, store, document) => _DocumentPage(
            open: () => _open(store, document),
            themeMode: _themeMode,
            onToggleTheme: _toggleTheme,
          ),
        ),
      ),
    );
  }
}

/// The screen of one document; makes its controller once with [open],
/// restores it and disposes it when closed, even if the route rebuilds.
class _DocumentPage extends StatefulWidget {
  const _DocumentPage({
    required this.open,
    required this.themeMode,
    required this.onToggleTheme,
  });

  final SessionController Function() open;
  final ValueListenable<ThemeMode> themeMode;
  final VoidCallback onToggleTheme;

  @override
  State<_DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<_DocumentPage> {
  late final SessionController _controller = widget.open();

  @override
  void initState() {
    super.initState();
    unawaited(_controller.restore());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: widget.themeMode,
    builder: (context, mode, _) => ReviewScreen(
      controller: _controller,
      themeMode: mode,
      onToggleTheme: widget.onToggleTheme,
    ),
  );
}

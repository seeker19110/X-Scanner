import 'dart:async';

import 'package:flutter/material.dart';

import '../core/scan_document.dart';
import '../storage/document_store.dart';
import '../storage/library_store.dart';
import '../storage/p1_migration.dart';
import 'library_controller.dart';

/// Builds the screen that edits one document of the library.
typedef DocumentScreenBuilder = Widget Function(
  BuildContext context,
  DocumentStore store,
  ScanDocument document,
);

/// The library (XS-09 §6): loading/migrating, failure with retry, empty
/// state, the document list with rename, a new document button and a
/// message for every [LibraryNotice].
class LibraryScreen extends StatefulWidget {
  /// Shows [controller] and opens documents with [documentScreen];
  /// [onToggleTheme] flips [themeMode].
  const LibraryScreen({
    super.key,
    required this.controller,
    required this.documentScreen,
    required this.themeMode,
    required this.onToggleTheme,
  });

  final LibraryController controller;
  final DocumentScreenBuilder documentScreen;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  static const String _newLabel = 'Tài liệu mới';

  /// Width of an extended new document button besides its label: icon,
  /// inner padding and the screen margins on both sides.
  static const double _newButtonChromeDp = 100;

  LibraryController get _controller => widget.controller;

  /// Whether a document is being created or opened, so only one document
  /// screen is ever pushed at a time.
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    // The queued start notifies after this frame's build.
    unawaited(_controller.start());
    WidgetsBinding.instance.addPostFrameCallback((_) => _showNotices());
  }

  @override
  void didUpdateWidget(LibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    _showNotices();
  }

  void _showNotices() {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    for (
      var n = _controller.takeNotice();
      n != null;
      n = _controller.takeNotice()
    ) {
      messenger.showSnackBar(SnackBar(content: Text(_message(n))));
    }
  }

  static String _message(LibraryNotice notice) => switch (notice) {
    LibraryNotice.migrationSourceUnreadable =>
      'Không chuyển được phiên cũ. '
          'Ảnh gốc vẫn được giữ trong bộ nhớ của app.',
    LibraryNotice.saveFailed => 'Không lưu được',
    LibraryNotice.pickRejected =>
      'Không thêm được ảnh chụp dở. '
          'Ảnh vẫn được giữ trong bộ nhớ của app.',
    LibraryNotice.pickKept =>
      'Ảnh chụp dở chưa được lưu. '
          'Ảnh vẫn được giữ; hãy mở lại app để thử lại.',
  };

  static String _failureText(MigrationFailure? failure) => switch (failure) {
    MigrationFailure.insufficientSpace =>
      'Không đủ bộ nhớ để nâng cấp dữ liệu. '
          'Hãy giải phóng bộ nhớ rồi thử lại.',
    MigrationFailure.io =>
      'Không nâng cấp được dữ liệu. Dữ liệu cũ vẫn còn nguyên.',
    null => 'Không đọc được thư viện.',
  };

  /// `dd/MM/yyyy HH:mm` of [time] in device time.
  static String _formatLocal(DateTime time) {
    final t = time.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(t.day)}/${two(t.month)}/${t.year.toString().padLeft(4, '0')} '
        '${two(t.hour)}:${two(t.minute)}';
  }

  /// Shows [document] of [store]; the list is refreshed once it is closed.
  /// Ignored while a new document is being created.
  Future<void> _openDocument(DocumentStore store, ScanDocument document) async {
    if (_creating) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => widget.documentScreen(context, store, document),
      ),
    );
    await _controller.refresh();
  }

  Future<void> _create() async {
    setState(() => _creating = true);
    final created = await _controller.createDocument();
    if (!mounted) return;
    setState(() => _creating = false);
    if (created == null) return;
    final (store, document) = created;
    await _openDocument(store, document);
  }

  Future<void> _rename(ScanDocument document) async {
    final title = await showDialog<String>(
      context: context,
      builder: (context) => _RenameDialog(initial: document.title),
    );
    if (title != null) await _controller.rename(document.id, title);
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.themeMode == ThemeMode.dark;
    final ready = _controller.status == LibraryStatus.ready;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thư viện'),
        actions: [
          IconButton(
            tooltip: dark ? 'Chế độ sáng' : 'Chế độ tối',
            icon: Icon(dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: switch (_controller.status) {
        LibraryStatus.loading => _loading(),
        LibraryStatus.failed => _failed(),
        LibraryStatus.ready => _list(),
      },
      floatingActionButton: ready
          ? FloatingActionButton.extended(
              onPressed: _creating ? null : _create,
              tooltip: _newLabel,
              isExtended: _newLabelFits(context),
              icon: const Icon(Icons.add),
              label: const Text(_newLabel),
            )
          : null,
    );
  }

  /// Whether the new document button's label fits the screen width at the
  /// current text size; otherwise only its icon is shown, named by its
  /// tooltip (UX-RESP-001).
  bool _newLabelFits(BuildContext context) {
    final theme = Theme.of(context);
    final label = TextPainter(
      text: TextSpan(
        text: _newLabel,
        style:
            theme.floatingActionButtonTheme.extendedTextStyle ??
            theme.textTheme.labelLarge,
      ),
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final width = label.width;
    label.dispose();
    return width + _newButtonChromeDp <= MediaQuery.sizeOf(context).width;
  }

  Widget _loading() => Center(
    child: _controller.migrating
        ? const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang nâng cấp dữ liệu…', textAlign: TextAlign.center),
            ],
          )
        : const CircularProgressIndicator(semanticsLabel: 'Đang tải thư viện'),
  );

  Widget _failed() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _failureText(_controller.migrationFailure),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _controller.start,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    ),
  );

  Widget _list() {
    final entries = _controller.entries;
    if (entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Chưa có tài liệu', textAlign: TextAlign.center),
        ),
      );
    }
    return ListView.builder(
      // Room for the new document button over the last row.
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      itemCount: entries.length,
      itemBuilder: (context, i) => switch (entries[i]) {
        LibraryDocument(:final document) => _documentRow(document),
        LibraryNeedsUpdate(:final docId) => _closedRow(
          docId,
          Icons.system_update,
          'Cần cập nhật app để mở',
        ),
        LibraryUnreadable(:final docId) => _closedRow(
          docId,
          Icons.error_outline,
          'Không mở được tài liệu này',
        ),
      },
    );
  }

  Widget _documentRow(ScanDocument document) {
    final pages = '${document.pages.length} trang';
    final time = _formatLocal(document.updatedAt);
    void open() =>
        unawaited(_openDocument(_controller.storeOf(document.id), document));
    return Card(
      key: ValueKey(document.id),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              container: true,
              button: true,
              label: '${document.title}, $pages, sửa lúc $time',
              onTap: open,
              excludeSemantics: true,
              child: InkWell(
                onTap: open,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          document.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text('$pages · $time'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Đổi tên',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _rename(document),
          ),
        ],
      ),
    );
  }

  /// A folder that cannot be opened or renamed; the icon and the text say
  /// why, not only a color.
  Widget _closedRow(String docId, IconData icon, String text) => Card(
    key: ValueKey(docId),
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    ),
  );
}

/// Asks for a new title; pops it untrimmed once [titleErrorOf] accepts it,
/// or null for "Huỷ". Errors are shown in place and keep the dialog open.
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initial,
  );
  TitleError? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  static String _errorText(TitleError error) => switch (error) {
    TitleError.empty => 'Tên không được để trống',
    TitleError.tooLong => 'Tên tối đa 120 ký tự',
    TitleError.invalid => 'Tên có ký tự không hợp lệ',
  };

  void _save() {
    final error = titleErrorOf(_text.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(_text.text);
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return AlertDialog(
      title: const Text('Đổi tên'),
      content: TextField(
        controller: _text,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Tên tài liệu',
          errorText: error == null ? null : _errorText(error),
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Huỷ'),
        ),
        FilledButton(onPressed: _save, child: const Text('Lưu')),
      ],
    );
  }
}

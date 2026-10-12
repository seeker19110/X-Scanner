import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/scan_page.dart';
import '../export/page_exporter.dart';
import 'quad_editor_screen.dart';
import 'session_controller.dart';

/// The session screen: empty state, page list with edits, capture/import,
/// Dark/Light switch and a message for every [SessionNotice].
class ReviewScreen extends StatefulWidget {
  /// Creates the screen for [controller]; [onToggleTheme] flips [themeMode].
  const ReviewScreen({
    super.key,
    required this.controller,
    required this.themeMode,
    required this.onToggleTheme,
  });

  final SessionController controller;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  static const String _emptyText =
      'Chưa có trang nào. Chụp hoặc nhập ảnh để bắt đầu.';
  static const String _openingText = 'Đang mở phiên…';
  static const double _thumbSide = 72;
  static const List<(ExportFormat, String)> _exportChoices = [
    (ExportFormat.pdf, 'PDF'),
    (ExportFormat.jpeg, 'JPG'),
    (ExportFormat.png, 'PNG'),
  ];

  SessionController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    // A notice raised before this screen subscribed is shown after layout.
    WidgetsBinding.instance.addPostFrameCallback((_) => _showNotices());
  }

  @override
  void didUpdateWidget(ReviewScreen oldWidget) {
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

  static String _message(SessionNotice notice) => switch (notice) {
    SessionNotice.restoreFailed =>
      'Không khôi phục được phiên trước. '
          'Ảnh gốc vẫn được giữ trong bộ nhớ của app.',
    SessionNotice.decodeFailed =>
      'Không đọc được ảnh này. Chưa thêm trang nào.',
    SessionNotice.saveFailed =>
      'Không lưu được (có thể bộ nhớ đầy). Phiên giữ nguyên như trước.',
    SessionNotice.exportFailed =>
      'Không xuất được tài liệu. Bản gốc vẫn còn nguyên.',
  };

  /// Asks a yes/no question; true only if [confirmLabel] was pressed.
  Future<bool> _confirm(String question, String confirmLabel) async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(question),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return answer ?? false;
  }

  Future<void> _remove(ScanPage page, int number) async {
    if (await _confirm('Xoá trang $number?', 'Xoá')) {
      await _controller.remove(page.id);
    }
  }

  Future<void> _retake(ScanPage page, int number) async {
    if (await _confirm(
      'Chụp lại trang $number? Ảnh cũ sẽ bị thay.',
      'Chụp lại',
    )) {
      await _controller.retake(page.id);
    }
  }

  Future<void> _clearAll() async {
    if (await _confirm('Xoá tất cả trang?', 'Xoá tất cả')) {
      await _controller.clearAll();
    }
  }

  /// Asks for a format and exports to it; dismissing the sheet does nothing.
  Future<void> _export() async {
    final format = await showModalBottomSheet<ExportFormat>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (format, label) in _exportChoices)
              ListTile(
                title: Text(label),
                onTap: () => Navigator.of(context).pop(format),
              ),
          ],
        ),
      ),
    );
    if (format != null) await _controller.exportAndShare(format);
  }

  Future<void> _edit(ScanPage page, Uint8List thumbnail) async {
    final edited = await Navigator.of(context).push<ScanPage>(
      MaterialPageRoute(
        builder: (_) => QuadEditorScreen(page: page, thumbnailBytes: thumbnail),
      ),
    );
    if (edited != null) await _controller.updatePage(edited);
  }

  @override
  Widget build(BuildContext context) {
    final busy = _controller.busy;
    final pages = _controller.session.pages;
    final dark = widget.themeMode == ThemeMode.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('X-Scanner'),
        actions: [
          IconButton(
            tooltip: dark ? 'Chế độ sáng' : 'Chế độ tối',
            icon: Icon(dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
          if (pages.isNotEmpty)
            IconButton(
              tooltip: 'Xuất',
              icon: const Icon(Icons.ios_share),
              onPressed: busy ? null : _export,
            ),
          if (pages.isNotEmpty)
            IconButton(
              tooltip: 'Xoá tất cả trang',
              icon: const Icon(Icons.delete_sweep),
              onPressed: busy ? null : _clearAll,
            ),
        ],
      ),
      body: Column(
        children: [
          // Fixed slot so the indicator never shifts or covers content.
          SizedBox(
            height: 4,
            child: busy
                ? const LinearProgressIndicator(semanticsLabel: 'Đang xử lý')
                : null,
          ),
          Expanded(
            child: pages.isEmpty
                ? (_controller.restoring ? _openingState() : _emptyState(busy))
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: pages.length,
                    // Off while busy like every button: a queued move would
                    // run later with indices that may no longer match.
                    buildDefaultDragHandles: !busy,
                    onReorderItem: (from, to) {
                      // The list still offers the Move up/down accessibility
                      // actions while the drag handles are off, and they
                      // call this directly.
                      if (_controller.busy) return;
                      unawaited(_controller.move(from, to));
                    },
                    itemBuilder: (context, i) =>
                        _pageRow(pages[i], i + 1, busy),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: pages.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: _sourceButtons(busy),
              ),
            ),
    );
  }

  Widget _emptyState(bool busy) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(_emptyText, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          _sourceButtons(busy),
        ],
      ),
    ),
  );

  /// Shown while a saved session may still be loading, so an empty list
  /// is not mistaken for a lost session.
  static Widget _openingState() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text(_openingText, textAlign: TextAlign.center),
      ],
    ),
  );

  Widget _sourceButtons(bool busy) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 12,
    runSpacing: 8,
    children: [
      FilledButton.icon(
        onPressed: busy ? null : _controller.capture,
        icon: const Icon(Icons.photo_camera),
        label: const Text('Chụp'),
      ),
      OutlinedButton.icon(
        onPressed: busy ? null : _controller.importFromGallery,
        icon: const Icon(Icons.photo_library),
        label: const Text('Nhập ảnh'),
      ),
    ],
  );

  Widget _pageRow(ScanPage page, int number, bool busy) {
    return Card(
      key: ValueKey(page.id),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      // The editor works on the uncropped thumbnail (FR-4); the tile shows
      // the cropped preview rendered from it.
      child: FutureBuilder<Uint8List>(
        future: _controller.thumbnailFor(page),
        builder: (context, snapshot) {
          final thumbnail = snapshot.data;
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: _thumbSide,
                  child: FutureBuilder<Uint8List>(
                    // A new revision starts from an empty snapshot, so the
                    // previous revision's preview is never shown meanwhile.
                    key: ValueKey((page.id, page.revision)),
                    future: _controller.croppedPreviewFor(page),
                    builder: (context, preview) =>
                        _thumbnail(preview, page, number, busy),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Trang $number'),
                      Wrap(
                        children: [
                          IconButton(
                            tooltip: 'Chỉnh góc',
                            icon: const Icon(Icons.crop),
                            onPressed: busy || thumbnail == null
                                ? null
                                : () => _edit(page, thumbnail),
                          ),
                          IconButton(
                            tooltip: 'Xoay 90°',
                            icon: const Icon(Icons.rotate_90_degrees_cw),
                            onPressed: busy
                                ? null
                                : () => _controller.updatePage(
                                    page.rotatedClockwise(),
                                  ),
                          ),
                          IconButton(
                            tooltip: 'Chụp lại',
                            icon: const Icon(Icons.flip_camera_android),
                            onPressed: busy
                                ? null
                                : () => _retake(page, number),
                          ),
                          IconButton(
                            tooltip: 'Xoá trang',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: busy
                                ? null
                                : () => _remove(page, number),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Preview cropped and rotated like the export, decoded at the tile's
  /// pixel size; a small spinner while loading and, if the original or the
  /// preview cannot be decoded, an error tile that asks the controller to
  /// decode both again.
  Widget _thumbnail(
    AsyncSnapshot<Uint8List> snapshot,
    ScanPage page,
    int number,
    bool busy,
  ) {
    final bytes = snapshot.data;
    if (bytes != null) {
      final px = (_thumbSide * MediaQuery.devicePixelRatioOf(context)).ceil();
      return Image(
        image: ResizeImage(
          MemoryImage(bytes),
          width: px,
          height: px,
          policy: ResizeImagePolicy.fit,
        ),
        fit: BoxFit.contain,
        gaplessPlayback: true,
      );
    }
    // A retry keeps the old error in the snapshot while it decodes again.
    if (snapshot.connectionState != ConnectionState.waiting &&
        snapshot.hasError) {
      final colors = Theme.of(context).colorScheme;
      return ColoredBox(
        color: colors.errorContainer,
        child: Center(
          child: IconButton(
            tooltip: 'Tải lại ảnh xem trước trang $number',
            icon: const Icon(Icons.broken_image_outlined),
            color: colors.onErrorContainer,
            onPressed: busy ? null : () => _controller.retryThumbnail(page),
          ),
        ),
      );
    }
    return const Center(
      child: SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/scan_page.dart';
import '../export/export_job.dart';
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
  static const double _thumbSide = 96;
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
    SessionNotice.exportCancelled => 'Đã huỷ xuất.',
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
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Text(
                    'Chọn định dạng',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                for (final (format, label) in _exportChoices)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    leading: Icon(
                      format == ExportFormat.pdf
                          ? Icons.picture_as_pdf_outlined
                          : Icons.image_outlined,
                    ),
                    title: Text(label),
                    subtitle: Text(switch (format) {
                      ExportFormat.pdf => 'Gộp các trang thành một tài liệu',
                      ExportFormat.jpeg => 'Mỗi trang là một ảnh JPG',
                      ExportFormat.png => 'Mỗi trang là một ảnh PNG',
                    }),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).pop(format),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
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
    final job = _controller.exportJob;
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
            child: job != null
                ? LinearProgressIndicator(
                    value: job.done == job.total ? null : job.done / job.total,
                    semanticsLabel: _exportLabel(job),
                  )
                : busy
                ? const LinearProgressIndicator(semanticsLabel: 'Đang xử lý')
                : null,
          ),
          Expanded(
            child: pages.isEmpty
                ? (_controller.restoring ? _openingState() : _emptyState(busy))
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    header: _documentSummary(pages.length),
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
          : _footer(
              job != null
                  ? _exportProgress(job)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          onPressed: busy ? null : _export,
                          icon: const Icon(Icons.ios_share),
                          label: const Text('Xuất tài liệu'),
                        ),
                        const SizedBox(height: 12),
                        _sourceButtons(busy),
                      ],
                    ),
            ),
    );
  }

  Widget _scrollableState(List<Widget> children) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          ),
        ),
      ),
    ),
  );

  Widget _emptyState(bool busy) {
    final colors = Theme.of(context).colorScheme;
    return _scrollableState([
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Icon(
          Icons.document_scanner_outlined,
          size: 56,
          color: colors.onPrimaryContainer,
        ),
      ),
      const SizedBox(height: 24),
      Text(
        'Tài liệu gọn gàng.\nBắt đầu thật dễ.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      const Text(_emptyText, textAlign: TextAlign.center),
      const SizedBox(height: 24),
      _sourceButtons(busy),
      const SizedBox(height: 24),
      Text(
        'Chỉnh góc · Sắp xếp · Xuất PDF hoặc ảnh',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: colors.onSurfaceVariant),
      ),
      const SizedBox(height: 8),
      Text(
        'Xử lý ngay trên thiết bị',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: colors.onSurfaceVariant),
      ),
    ]);
  }

  /// Shown while a saved session may still be loading, so an empty list
  /// is not mistaken for a lost session.
  Widget _openingState() => _scrollableState(const [
    CircularProgressIndicator(),
    SizedBox(height: 24),
    Text(_openingText, textAlign: TextAlign.center),
  ]);

  Widget _documentSummary(int count) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tài liệu của bạn',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '$count trang',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: colors.primary),
          ),
          const SizedBox(height: 4),
          Text(
            'Chỉnh từng trang, giữ để sắp xếp lại.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _footer(Widget child) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      border: Border(
        top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.32,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );

  /// "Exporting page i/N", where i is the page being exported.
  static String _exportLabel(ExportJob job) => job.cancelRequested
      ? 'Đang huỷ…'
      : job.done == job.total
      ? (job.format == ExportFormat.pdf ? 'Đang tạo PDF…' : 'Đang hoàn tất…')
      : 'Đang xuất trang ${min(job.done + 1, job.total)}/${job.total}';

  /// Takes the place of the source buttons during an export. Cancel stays
  /// enabled while busy, as the export itself keeps the controller busy,
  /// until it was pressed: the job then stops after the current page.
  Widget _exportProgress(ExportJob job) => ConstrainedBox(
    // At least as tall as the source buttons, so the bar does not jump.
    constraints: const BoxConstraints(minHeight: 48),
    child: Row(
      children: [
        Expanded(child: Text(_exportLabel(job))),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: job.cancelRequested ? null : _controller.cancelExport,
          child: const Text('Huỷ'),
        ),
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ColoredBox(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: FutureBuilder<Uint8List>(
                              // A new revision starts from an empty snapshot, so the
                              // previous revision's preview is never shown meanwhile.
                              key: ValueKey((page.id, page.revision)),
                              future: _controller.croppedPreviewFor(page),
                              builder: (context, preview) =>
                                  _thumbnail(preview, page, number, busy),
                            ),
                          ),
                          Positioned(
                            left: 4,
                            top: 4,
                            child: ExcludeSemantics(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  number.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trang $number',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
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

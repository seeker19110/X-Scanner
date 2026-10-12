import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;

import '../core/edit_history.dart';
import '../core/page_quad.dart';
import '../core/quad_editing.dart';
import '../core/scan_page.dart';
import '../imaging/page_render.dart';

/// Lets the user drag the four crop corners of [page] over its thumbnail,
/// shown with the page's rotation, and rotate it, with undo/redo. Pops the
/// edited [ScanPage] on "Lưu" if anything changed, otherwise `null`; back
/// with changes asks before discarding them.
class QuadEditorScreen extends StatefulWidget {
  /// Creates the editor; [thumbnailBytes] is the page's preview image.
  const QuadEditorScreen({
    super.key,
    required this.page,
    required this.thumbnailBytes,
  });

  final ScanPage page;
  final Uint8List thumbnailBytes;

  @override
  State<QuadEditorScreen> createState() => _QuadEditorScreenState();
}

class _QuadEditorScreenState extends State<QuadEditorScreen> {
  static const double _handleSize = 48;
  static const double _handleDot = 20;

  /// Keeps handles on screen and grabbable at the image border.
  static const double _margin = _handleSize / 2;

  static const double _loupeDiameter = 96;
  static const double _loupeScale = 2;

  /// Gap between the dragged corner and the loupe's center, clear of the
  /// finger.
  static const double _loupeGap = _loupeDiameter / 2 + _handleSize;

  /// One semantic nudge: 1 % of the shown width or height (XS-13 FR-9).
  static const double _nudgeStep = 0.01;

  static const String _invalidMessage = 'Góc này làm khung không hợp lệ.';

  /// Labels follow the corner's position on screen, not in the original.
  static const Map<QuadCorner, String> _labels = {
    QuadCorner.topLeft: 'Góc trên trái',
    QuadCorner.topRight: 'Góc trên phải',
    QuadCorner.bottomRight: 'Góc dưới phải',
    QuadCorner.bottomLeft: 'Góc dưới trái',
  };

  static const List<(CustomSemanticsAction, Offset)> _nudges = [
    (CustomSemanticsAction(label: 'Dịch lên'), Offset(0, -_nudgeStep)),
    (CustomSemanticsAction(label: 'Dịch xuống'), Offset(0, _nudgeStep)),
    (CustomSemanticsAction(label: 'Dịch sang trái'), Offset(-_nudgeStep, 0)),
    (CustomSemanticsAction(label: 'Dịch sang phải'), Offset(_nudgeStep, 0)),
  ];

  final GlobalKey _areaKey = GlobalKey();
  late final EditHistory<ScanPage> _history = EditHistory(widget.page);
  late final Size _imageSize = _readImageSize(widget.thumbnailBytes);
  bool _rejectionShown = false;

  /// The page when the current drag began, or `null` when not dragging.
  ScanPage? _dragStart;

  /// The displayed corner being dragged, or `null` when not dragging.
  QuadCorner? _dragCorner;

  /// Unsaved state of the current drag; becomes one history step on release.
  ScanPage? _draft;

  ScanPage get _page => _draft ?? _history.current;

  bool get _changed =>
      _page.quad != widget.page.quad ||
      _page.quarterTurns != widget.page.quarterTurns;

  /// Image size from the header only; falls back to a square if unknown.
  static Size _readImageSize(Uint8List bytes) {
    final size = imageSizeOf(bytes);
    if (size == null) return const Size(1, 1);
    return Size(size.width.toDouble(), size.height.toDouble());
  }

  /// Where the image, turned by the current rotation, is drawn
  /// (contain-fitted) inside an area of [area].
  Rect _imageRect(Size area) {
    final inner = Size(
      max(0, area.width - 2 * _margin),
      max(0, area.height - 2 * _margin),
    );
    final shown = _page.quarterTurns.isOdd ? _imageSize.flipped : _imageSize;
    final fitted = applyBoxFit(BoxFit.contain, shown, inner).destination;
    return Alignment.center.inscribe(fitted, Offset(_margin, _margin) & inner);
  }

  static Offset _toScreen(Rect rect, Point<double> p) =>
      Offset(rect.left + p.x * rect.width, rect.top + p.y * rect.height);

  /// Screen position of the corner shown at [shown].
  Offset _shownAt(Rect rect, QuadCorner shown) {
    final turns = _page.quarterTurns;
    final source = cornerOf(_page.quad, sourceCorner(shown, turns));
    return _toScreen(rect, toDisplay(source, turns));
  }

  /// Moves the corner shown at [shown] to the display point [to], or
  /// returns `null` if that makes the quad invalid.
  PageQuad? _moveShown(QuadCorner shown, Point<double> to) {
    final turns = _page.quarterTurns;
    return withCornerMoved(
      _page.quad,
      sourceCorner(shown, turns),
      fromDisplay(to, turns),
    );
  }

  void _showRejection() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text(_invalidMessage)));
  }

  /// Records [page] as one history step, ending any drag in progress. A
  /// page that looks the same as the current one (e.g. "Đặt lại" on the
  /// full frame, or a nudge that only clamps) is not a step.
  void _commit(ScanPage page) {
    final current = _history.current;
    final same =
        page.quad == current.quad && page.quarterTurns == current.quarterTurns;
    setState(() {
      _endDragState();
      if (!same) _history.push(page);
    });
  }

  void _endDragState() {
    _dragStart = null;
    _dragCorner = null;
    _draft = null;
  }

  void _onDragStart(QuadCorner shown) {
    _rejectionShown = false;
    setState(() {
      _dragStart = _history.current;
      _dragCorner = shown;
      _draft = null;
    });
  }

  void _onDrag(QuadCorner shown, Offset globalPosition) {
    final start = _dragStart;
    if (start == null) return;
    final box = _areaKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final rect = _imageRect(box.size);
    if (rect.isEmpty) return;
    final local = box.globalToLocal(globalPosition);
    final moved = _moveShown(
      shown,
      Point<double>(
        (local.dx - rect.left) / rect.width,
        (local.dy - rect.top) / rect.height,
      ),
    );
    if (moved != null) {
      // Derived from the start page so a whole drag costs one revision.
      setState(() => _draft = start.withQuad(moved));
    } else if (!_rejectionShown) {
      _rejectionShown = true;
      _showRejection();
    }
  }

  /// Ends a drag: one history step if the quad changed, none otherwise.
  void _onDragEnd() {
    final start = _dragStart;
    final draft = _draft;
    if (start != null && draft != null && draft.quad != start.quad) {
      _commit(draft);
    } else {
      setState(_endDragState);
    }
  }

  void _nudge(QuadCorner shown, Offset delta) {
    final turns = _page.quarterTurns;
    final at = toDisplay(
      cornerOf(_page.quad, sourceCorner(shown, turns)),
      turns,
    );
    final moved = _moveShown(
      shown,
      Point<double>(at.x + delta.dx, at.y + delta.dy),
    );
    if (moved == null) {
      _showRejection();
    } else {
      _commit(_page.withQuad(moved));
    }
  }

  void _undo() => setState(() {
    _endDragState();
    _history.undo();
  });

  void _redo() => setState(() {
    _endDragState();
    _history.redo();
  });

  /// Pops what is shown, including a drag still in progress.
  void _save() => Navigator.of(context).pop(_changed ? _page : null);

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bỏ thay đổi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Tiếp tục sửa'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Bỏ thay đổi'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  // DEBT: corners move by dragging or by screen-reader nudges only; there is no one-tap way for users who cannot drag and do not use a screen reader | trần: WCAG 2.2 2.5.7 not fully met in the editor | xem lại khi: XS-20.
  Widget _handle(QuadCorner shown, Offset center, ColorScheme colors) {
    return Positioned(
      left: center.dx - _handleSize / 2,
      top: center.dy - _handleSize / 2,
      width: _handleSize,
      height: _handleSize,
      child: Semantics(
        label: _labels[shown],
        customSemanticsActions: {
          for (final (action, delta) in _nudges)
            action: () => _nudge(shown, delta),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) => _onDragStart(shown),
          onPanUpdate: (d) => _onDrag(shown, d.globalPosition),
          onPanEnd: (_) => _onDragEnd(),
          onPanCancel: _onDragEnd,
          child: Center(
            child: Container(
              width: _handleDot,
              height: _handleDot,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primaryContainer,
                border: Border.all(color: colors.primary, width: 3),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A 2× loupe over [corner], above it or below it near the top edge,
  /// kept inside [area] horizontally (XS-13 FR-8).
  Widget _loupe(Offset corner, Size area, ColorScheme colors) {
    const radius = _loupeDiameter / 2;
    final above = corner.dy - _loupeGap - radius >= 0;
    final center = Offset(
      corner.dx.clamp(radius, max(radius, area.width - radius)),
      above ? corner.dy - _loupeGap : corner.dy + _loupeGap,
    );
    return Positioned(
      left: center.dx - radius,
      top: center.dy - radius,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: RawMagnifier(
            size: const Size.square(_loupeDiameter),
            magnificationScale: _loupeScale,
            focalPointOffset: corner - center,
            decoration: MagnifierDecoration(
              shape: CircleBorder(
                side: BorderSide(color: colors.primary, width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dragCorner = _dragCorner;
    return PopScope<ScanPage>(
      canPop: !_changed,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Chỉnh góc')),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final area = constraints.biggest;
              final rect = _imageRect(area);
              Offset at(QuadCorner shown) => _shownAt(rect, shown);
              return Stack(
                key: _areaKey,
                children: [
                  Positioned.fromRect(
                    rect: rect,
                    child: RotatedBox(
                      quarterTurns: _page.quarterTurns,
                      child: Image.memory(
                        widget.thumbnailBytes,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _QuadPainter(
                        corners: [for (final c in QuadCorner.values) at(c)],
                        color: colors.primary,
                      ),
                    ),
                  ),
                  for (final c in QuadCorner.values) _handle(c, at(c), colors),
                  // Last, so the loupe magnifies everything painted above.
                  if (dragCorner != null) _loupe(at(dragCorner), area, colors),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              alignment: WrapAlignment.spaceEvenly,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                IconButton(
                  tooltip: 'Hoàn tác',
                  onPressed: _history.canUndo ? _undo : null,
                  icon: const Icon(Icons.undo),
                ),
                IconButton(
                  tooltip: 'Làm lại',
                  onPressed: _history.canRedo ? _redo : null,
                  icon: const Icon(Icons.redo),
                ),
                TextButton(
                  onPressed: () =>
                      _commit(_history.current.withQuad(PageQuad.fullFrame)),
                  child: const Text('Đặt lại'),
                ),
                TextButton.icon(
                  onPressed: () => _commit(_history.current.rotatedClockwise()),
                  icon: const Icon(Icons.rotate_90_degrees_cw),
                  label: const Text('Xoay 90°'),
                ),
                Text('Xoay: ${_page.quarterTurns * 90}°'),
                FilledButton(onPressed: _save, child: const Text('Lưu')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Outlines the crop quad through [corners] (screen coordinates).
class _QuadPainter extends CustomPainter {
  const _QuadPainter({required this.corners, required this.color});

  final List<Offset> corners;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addPolygon(corners, true);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_QuadPainter old) =>
      old.color != color || !listEquals(old.corners, corners);
}

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../core/page_quad.dart';
import '../core/quad_editing.dart';
import '../core/scan_page.dart';
import '../imaging/page_render.dart';

/// Lets the user drag the four crop corners of [page] over its thumbnail
/// and rotate it. Pops the edited [ScanPage] on "Lưu", or `null` on back.
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

  static const Map<QuadCorner, String> _labels = {
    QuadCorner.topLeft: 'Góc trên trái',
    QuadCorner.topRight: 'Góc trên phải',
    QuadCorner.bottomRight: 'Góc dưới phải',
    QuadCorner.bottomLeft: 'Góc dưới trái',
  };

  final GlobalKey _areaKey = GlobalKey();
  late ScanPage _page = widget.page;
  late final Size _imageSize = _readImageSize(widget.thumbnailBytes);
  bool _rejectionShown = false;

  /// Image size from the header only; falls back to a square if unknown.
  static Size _readImageSize(Uint8List bytes) {
    final size = imageSizeOf(bytes);
    if (size == null) return const Size(1, 1);
    return Size(size.width.toDouble(), size.height.toDouble());
  }

  /// Where the image is drawn (contain-fitted) inside an area of [area].
  Rect _imageRect(Size area) {
    final inner = Size(
      max(0, area.width - 2 * _margin),
      max(0, area.height - 2 * _margin),
    );
    final fitted = applyBoxFit(BoxFit.contain, _imageSize, inner).destination;
    return Alignment.center.inscribe(fitted, Offset(_margin, _margin) & inner);
  }

  static Offset _toScreen(Rect rect, Point<double> p) =>
      Offset(rect.left + p.x * rect.width, rect.top + p.y * rect.height);

  void _onDrag(QuadCorner corner, Offset globalPosition) {
    final box = _areaKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final rect = _imageRect(box.size);
    if (rect.isEmpty) return;
    final local = box.globalToLocal(globalPosition);
    final moved = withCornerMoved(
      _page.quad,
      corner,
      Point<double>(
        (local.dx - rect.left) / rect.width,
        (local.dy - rect.top) / rect.height,
      ),
    );
    if (moved != null) {
      setState(() => _page = _page.withQuad(moved));
    } else if (!_rejectionShown) {
      _rejectionShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Góc này làm khung không hợp lệ.')),
      );
    }
  }

  // DEBT: corners move only by dragging; screen-reader users can reset to the full frame but not adjust a corner | trần: WCAG 2.2 2.5.7 not met in the editor | xem lại khi: P2 adds guided capture or edge detection.
  Widget _handle(QuadCorner corner, Offset center, ColorScheme colors) {
    return Positioned(
      left: center.dx - _handleSize / 2,
      top: center.dy - _handleSize / 2,
      width: _handleSize,
      height: _handleSize,
      child: Semantics(
        label: _labels[corner],
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) => _rejectionShown = false,
          onPanUpdate: (d) => _onDrag(corner, d.globalPosition),
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh góc')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final rect = _imageRect(constraints.biggest);
            Offset at(QuadCorner c) => _toScreen(rect, cornerOf(_page.quad, c));
            return Stack(
              key: _areaKey,
              children: [
                Positioned.fromRect(
                  rect: rect,
                  child: Image.memory(
                    widget.thumbnailBytes,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
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
              TextButton(
                onPressed: () =>
                    setState(() => _page = _page.withQuad(PageQuad.fullFrame)),
                child: const Text('Đặt lại'),
              ),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _page = _page.rotatedClockwise()),
                icon: const Icon(Icons.rotate_90_degrees_cw),
                label: const Text('Xoay 90°'),
              ),
              Text('Xoay: ${_page.quarterTurns * 90}°'),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(_page),
                child: const Text('Lưu'),
              ),
            ],
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

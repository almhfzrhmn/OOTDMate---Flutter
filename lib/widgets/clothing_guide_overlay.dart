import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ootdmate_frontend/core/theme/app_theme.dart';

/// Overlay widget yang menampilkan panduan posisi pakaian.
/// Menampilkan area target dengan dashed border dan instruksi teks.
class ClothingGuideOverlay extends StatelessWidget {
  /// Ukuran area overlay (width & height mengikuti parent)
  final double? width;
  final double? height;

  /// Apakah guide ditampilkan atau disembunyikan
  final bool visible;

  const ClothingGuideOverlay({
    super.key,
    this.width,
    this.height,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return IgnorePointer(
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _GuideOverlayPainter(),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Spacer(flex: 2),
                // Icon panduan
                Icon(
                  Icons.checkroom_rounded,
                  size: 48,
                  color: AppTheme.neonBlue.withAlpha(80),
                ),
                const SizedBox(height: 8),
                // Teks instruksi
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(180),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.neonBlue.withAlpha(60),
                      width: 0.5,
                    ),
                  ),
                  child: const Text(
                    'Position the clothing within the designated area.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// CustomPainter yang menggambar dashed border sebagai guide area
class _GuideOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double padding = 24;
    final Rect guideRect = Rect.fromLTRB(
      padding,
      padding,
      size.width - padding,
      size.height - padding,
    );

    // Draw semi-transparent dimming outside the guide area
    final Paint dimPaint = Paint()
      ..color = AppTheme.primary.withAlpha(120)
      ..style = PaintingStyle.fill;

    // Draw outer dim area using path difference
    final Path outerPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final Path innerPath = Path()
      ..addRRect(RRect.fromRectAndRadius(guideRect, const Radius.circular(16)));
    final Path dimPath = Path.combine(PathOperation.difference, outerPath, innerPath);
    canvas.drawPath(dimPath, dimPaint);

    // Draw dashed border
    final Paint dashPaint = Paint()
      ..color = AppTheme.neonBlue.withAlpha(150)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    _drawDashedRRect(
      canvas,
      RRect.fromRectAndRadius(guideRect, const Radius.circular(16)),
      dashPaint,
      dashWidth: 8,
      dashSpace: 6,
    );

    // Draw corner accents (L-shaped corners)
    final Paint cornerPaint = Paint()
      ..color = AppTheme.neonBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    const double cornerLen = 20;

    // Top-left corner
    canvas.drawLine(
      Offset(guideRect.left, guideRect.top + cornerLen),
      Offset(guideRect.left, guideRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(guideRect.left, guideRect.top),
      Offset(guideRect.left + cornerLen, guideRect.top),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(guideRect.right - cornerLen, guideRect.top),
      Offset(guideRect.right, guideRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(guideRect.right, guideRect.top),
      Offset(guideRect.right, guideRect.top + cornerLen),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(guideRect.left, guideRect.bottom - cornerLen),
      Offset(guideRect.left, guideRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(guideRect.left, guideRect.bottom),
      Offset(guideRect.left + cornerLen, guideRect.bottom),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(guideRect.right - cornerLen, guideRect.bottom),
      Offset(guideRect.right, guideRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(guideRect.right, guideRect.bottom),
      Offset(guideRect.right, guideRect.bottom - cornerLen),
      cornerPaint,
    );
  }

  /// Menggambar dashed rounded rectangle
  void _drawDashedRRect(
    Canvas canvas,
    RRect rrect,
    Paint paint, {
    double dashWidth = 8,
    double dashSpace = 5,
  }) {
    final Path path = Path()..addRRect(rrect);
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      double distance = 0;
      bool draw = true;

      while (distance < metric.length) {
        final double length = draw ? dashWidth : dashSpace;
        final double end = math.min(distance + length, metric.length);

        if (draw) {
          final extractedPath = metric.extractPath(distance, end);
          canvas.drawPath(extractedPath, paint);
        }

        distance = end;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/scanned_page.dart';

class QuadCropPainter extends CustomPainter {
  final List<PointCoord> corners; // 0: TL, 1: TR, 2: BR, 3: BL
  final Size imageDisplaySize;

  QuadCropPainter({
    required this.corners,
    required this.imageDisplaySize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (corners.length < 4) return;

    final tl = Offset(corners[0].x * size.width, corners[0].y * size.height);
    final tr = Offset(corners[1].x * size.width, corners[1].y * size.height);
    final br = Offset(corners[2].x * size.width, corners[2].y * size.height);
    final bl = Offset(corners[3].x * size.width, corners[3].y * size.height);

    // 1. Shaded overlay outside polygon
    final path = Path()
      ..moveTo(tl.dx, tl.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(br.dx, br.dy)
      ..lineTo(bl.dx, bl.dy)
      ..close();

    final shadePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final screenPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final overlayPath = Path.combine(PathOperation.difference, screenPath, path);
    canvas.drawPath(overlayPath, shadePaint);

    // 2. Crop border
    final borderPaint = Paint()
      ..color = AppColors.primaryLight
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, borderPaint);

    // 3. Grid lines inside crop polygon
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw horizontal 1/3 and 2/3 lines
    for (double f in [1 / 3, 2 / 3]) {
      final left = Offset.lerp(tl, bl, f)!;
      final right = Offset.lerp(tr, br, f)!;
      canvas.drawLine(left, right, gridPaint);
    }
    // Draw vertical 1/3 and 2/3 lines
    for (double f in [1 / 3, 2 / 3]) {
      final top = Offset.lerp(tl, tr, f)!;
      final bottom = Offset.lerp(bl, br, f)!;
      canvas.drawLine(top, bottom, gridPaint);
    }

    // 4. Corner control handles
    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final handleBorder = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (final pt in [tl, tr, br, bl]) {
      canvas.drawCircle(pt, 12, handlePaint);
      canvas.drawCircle(pt, 12, handleBorder);
    }
  }

  @override
  bool shouldRepaint(covariant QuadCropPainter oldDelegate) {
    return true;
  }
}

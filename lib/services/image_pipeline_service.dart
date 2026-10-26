import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../domain/models/enhancement_preset.dart';
import '../domain/models/scanned_page.dart';

class ImagePipelineService {
  /// Applies document enhancement presets to image bytes.
  static Uint8List applyPreset(Uint8List imageBytes, EnhancementPreset preset) {
    if (preset == EnhancementPreset.original) {
      return imageBytes;
    }

    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw ArgumentError('Failed to decode image bytes for enhancement');
    }

    img.Image processed;
    switch (preset) {
      case EnhancementPreset.grayscale:
        processed = img.grayscale(decoded);
        break;
      case EnhancementPreset.blackAndWhite:
        final gray = img.grayscale(decoded);
        final contrast = img.contrast(gray, contrast: 140);
        processed = img.luminanceThreshold(contrast, threshold: 0.52);
        break;
      case EnhancementPreset.enhancedColor:
        processed = img.adjustColor(
          decoded,
          contrast: 1.2,
          saturation: 1.15,
          brightness: 1.05,
        );
        break;
      case EnhancementPreset.original:
        processed = decoded;
        break;
    }

    return Uint8List.fromList(img.encodeJpg(processed, quality: 90));
  }

  /// Rotates the image clockwise by 90, 180, or 270 degrees.
  static Uint8List rotate(Uint8List imageBytes, int degrees) {
    if (degrees % 360 == 0) return imageBytes;
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw ArgumentError('Failed to decode image bytes for rotation');
    }
    final rotated = img.copyRotate(decoded, angle: degrees.toDouble());
    return Uint8List.fromList(img.encodeJpg(rotated, quality: 90));
  }

  /// Warps a 4-point quadrilateral into a rectified rectangle (perspective crop).
  static Uint8List perspectiveCrop(
    Uint8List imageBytes, {
    required PointCoord topLeft,
    required PointCoord topRight,
    required PointCoord bottomRight,
    required PointCoord bottomLeft,
    int? targetWidth,
    int? targetHeight,
  }) {
    final src = img.decodeImage(imageBytes);
    if (src == null) {
      throw ArgumentError('Failed to decode image bytes for crop');
    }

    final widthTop = (topRight.x - topLeft.x).abs();
    final widthBottom = (bottomRight.x - bottomLeft.x).abs();
    final heightLeft = (bottomLeft.y - topLeft.y).abs();
    final heightRight = (bottomRight.y - topRight.y).abs();

    final outW = targetWidth ?? ((widthTop + widthBottom) / 2).round().clamp(100, 4000);
    final outH = targetHeight ?? ((heightLeft + heightRight) / 2).round().clamp(100, 4000);

    final dst = img.Image(width: outW, height: outH);

    for (int y = 0; y < outH; y++) {
      final v = y / (outH - 1);
      for (int x = 0; x < outW; x++) {
        final u = x / (outW - 1);

        final srcX = (1 - u) * (1 - v) * topLeft.x +
            u * (1 - v) * topRight.x +
            u * v * bottomRight.x +
            (1 - u) * v * bottomLeft.x;

        final srcY = (1 - u) * (1 - v) * topLeft.y +
            u * (1 - v) * topRight.y +
            u * v * bottomRight.y +
            (1 - u) * v * bottomLeft.y;

        final px = src.getPixelInterpolate(srcX, srcY, interpolation: img.Interpolation.linear);
        dst.setPixel(x, y, px);
      }
    }

    return Uint8List.fromList(img.encodeJpg(dst, quality: 90));
  }

  /// Generates a fast, lightweight thumbnail from image bytes.
  static Uint8List generateThumbnail(Uint8List imageBytes, {int maxDimension = 320}) {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw ArgumentError('Failed to decode image bytes for thumbnail');
    }

    final int targetW;
    final int targetH;
    if (decoded.width > decoded.height) {
      targetW = maxDimension;
      targetH = (decoded.height * (maxDimension / decoded.width)).round();
    } else {
      targetH = maxDimension;
      targetW = (decoded.width * (maxDimension / decoded.height)).round();
    }

    final thumbnail = img.copyResize(
      decoded,
      width: targetW,
      height: targetH,
      interpolation: img.Interpolation.average,
    );

    return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 80));
  }
}

import 'dart:typed_data';
import 'package:image/image.dart' as img;

enum EnhancementFilter {
  original,
  grayscale,
  blackAndWhite,
  enhancedColor,
}

class Point2D {
  final double x;
  final double y;
  const Point2D(this.x, this.y);
}

class ImageProcessingPipeline {
  /// Applies document enhancement filters to image bytes.
  static Uint8List applyEnhancement(Uint8List imageBytes, EnhancementFilter filter) {
    if (filter == EnhancementFilter.original) {
      return imageBytes;
    }

    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw ArgumentError('Failed to decode image bytes');
    }

    img.Image processed;
    switch (filter) {
      case EnhancementFilter.grayscale:
        processed = img.grayscale(decoded);
        break;
      case EnhancementFilter.blackAndWhite:
        final gray = img.grayscale(decoded);
        // Contrast enhancement then thresholding
        final contrast = img.contrast(gray, contrast: 150);
        // Binarize based on mean luminance
        processed = img.luminanceThreshold(contrast, threshold: 0.5);
        break;
      case EnhancementFilter.enhancedColor:
        processed = img.adjustColor(
          decoded,
          contrast: 1.25,
          saturation: 1.15,
          brightness: 1.05,
        );
        break;
      case EnhancementFilter.original:
        processed = decoded;
        break;
    }

    return Uint8List.fromList(img.encodeJpg(processed, quality: 88));
  }

  /// Rotates the image by 90, 180, or 270 degrees.
  static Uint8List rotateImage(Uint8List imageBytes, int degrees) {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw ArgumentError('Failed to decode image bytes');
    }

    final rotated = img.copyRotate(decoded, angle: degrees.toDouble());
    return Uint8List.fromList(img.encodeJpg(rotated, quality: 90));
  }

  /// Compresses the image to target JPEG quality (0-100).
  static Uint8List compressImage(Uint8List imageBytes, {int quality = 75}) {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw ArgumentError('Failed to decode image bytes');
    }
    return Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
  }

  /// Warps a 4-point quadrilateral into a rectified rectangle (perspective crop).
  static Uint8List perspectiveCrop(
    Uint8List imageBytes, {
    required Point2D topLeft,
    required Point2D topRight,
    required Point2D bottomRight,
    required Point2D bottomLeft,
    int? targetWidth,
    int? targetHeight,
  }) {
    final src = img.decodeImage(imageBytes);
    if (src == null) {
      throw ArgumentError('Failed to decode image bytes');
    }

    // Determine target dimensions if not provided
    final widthTop = (topRight.x - topLeft.x).abs();
    final widthBottom = (bottomRight.x - bottomLeft.x).abs();
    final heightLeft = (bottomLeft.y - topLeft.y).abs();
    final heightRight = (bottomRight.y - topRight.y).abs();

    final outW = targetWidth ?? ((widthTop + widthBottom) / 2).round().clamp(100, 4000);
    final outH = targetHeight ?? ((heightLeft + heightRight) / 2).round().clamp(100, 4000);

    final dst = img.Image(width: outW, height: outH);

    // Bilinear interpolation reverse-mapping
    for (int y = 0; y < outH; y++) {
      final v = y / (outH - 1);
      for (int x = 0; x < outW; x++) {
        final u = x / (outW - 1);

        // Bilinear interpolation on quad corners
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
}

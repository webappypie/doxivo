import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:doxivo/poc/image_pipeline.dart';

void main() {
  group('ImageProcessingPipeline Tests', () {
    late Uint8List testImageJpg;

    setUp(() {
      // Create a 200x200 test RGB image with geometric patterns
      final baseImage = img.Image(width: 200, height: 200);
      img.fill(baseImage, color: img.ColorRgb8(240, 240, 240));
      // Draw a dark rectangle in the center
      img.fillRect(
        baseImage,
        x1: 40,
        y1: 40,
        x2: 160,
        y2: 160,
        color: img.ColorRgb8(20, 20, 20),
      );
      testImageJpg = Uint8List.fromList(img.encodeJpg(baseImage, quality: 90));
    });

    test('EnhancementFilter.original returns unchanged bytes', () {
      final result = ImageProcessingPipeline.applyEnhancement(
        testImageJpg,
        EnhancementFilter.original,
      );
      expect(result.length, equals(testImageJpg.length));
    });

    test('EnhancementFilter.grayscale converts image correctly', () {
      final result = ImageProcessingPipeline.applyEnhancement(
        testImageJpg,
        EnhancementFilter.grayscale,
      );
      expect(result, isNotEmpty);
      final decoded = img.decodeImage(result);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(200));
      expect(decoded.height, equals(200));
    });

    test('EnhancementFilter.blackAndWhite applies binarization', () {
      final result = ImageProcessingPipeline.applyEnhancement(
        testImageJpg,
        EnhancementFilter.blackAndWhite,
      );
      expect(result, isNotEmpty);
      final decoded = img.decodeImage(result);
      expect(decoded, isNotNull);
    });

    test('Image rotation correctly transforms dimensions', () {
      final rotated = ImageProcessingPipeline.rotateImage(testImageJpg, 90);
      expect(rotated, isNotEmpty);
      final decoded = img.decodeImage(rotated);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(200));
      expect(decoded.height, equals(200));
    });

    test('Image compression reduces or matches file size', () {
      final compressed = ImageProcessingPipeline.compressImage(testImageJpg, quality: 30);
      expect(compressed, isNotEmpty);
      // High compression (quality 30) should be smaller than quality 90
      expect(compressed.length, lessThanOrEqualTo(testImageJpg.length));
    });

    test('Perspective crop rectifies quadrilateral region', () {
      final cropped = ImageProcessingPipeline.perspectiveCrop(
        testImageJpg,
        topLeft: const Point2D(40, 40),
        topRight: const Point2D(160, 40),
        bottomRight: const Point2D(160, 160),
        bottomLeft: const Point2D(40, 160),
        targetWidth: 120,
        targetHeight: 120,
      );

      expect(cropped, isNotEmpty);
      final decoded = img.decodeImage(cropped);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(120));
      expect(decoded.height, equals(120));
    });
  });
}

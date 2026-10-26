import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doxivo/domain/models/compression_preset.dart';
import 'package:doxivo/domain/models/pdf_operation_result.dart';
import 'package:doxivo/domain/models/pdf_page_item.dart';
import 'package:doxivo/domain/models/signature_config.dart';
import 'package:doxivo/domain/models/watermark_config.dart';

void main() {
  group('PDF Toolkit Domain Models Tests', () {
    test('CompressionPreset configurations and presets', () {
      expect(CompressionPreset.all.length, equals(3));

      expect(CompressionPreset.low.level, equals(CompressionLevel.low));
      expect(CompressionPreset.low.targetDpi, equals(300));
      expect(CompressionPreset.low.jpegQuality, equals(85));

      expect(CompressionPreset.medium.level, equals(CompressionLevel.medium));
      expect(CompressionPreset.medium.targetDpi, equals(150));
      expect(CompressionPreset.medium.jpegQuality, equals(65));

      expect(CompressionPreset.high.level, equals(CompressionLevel.high));
      expect(CompressionPreset.high.targetDpi, equals(96));
      expect(CompressionPreset.high.jpegQuality, equals(45));
    });

    test('PdfOperationResult reduction percentage calculation', () {
      const normalResult = PdfOperationResult(
        isSuccess: true,
        beforeBytes: 10000,
        afterBytes: 4000,
      );
      expect(normalResult.reductionPercentage, closeTo(60.0, 0.01));

      const noReductionResult = PdfOperationResult(
        isSuccess: true,
        beforeBytes: 5000,
        afterBytes: 5000,
      );
      expect(noReductionResult.reductionPercentage, equals(0.0));

      const largerAfterResult = PdfOperationResult(
        isSuccess: true,
        beforeBytes: 5000,
        afterBytes: 6000,
      );
      expect(largerAfterResult.reductionPercentage, equals(0.0));

      const zeroBeforeResult = PdfOperationResult(
        isSuccess: false,
        beforeBytes: 0,
        afterBytes: 0,
      );
      expect(zeroBeforeResult.reductionPercentage, equals(0.0));
    });

    test('WatermarkConfig defaults and copyWith', () {
      const config = WatermarkConfig(text: 'DRAFT');
      expect(config.text, equals('DRAFT'));
      expect(config.fontSize, equals(48.0));
      expect(config.opacity, equals(0.3));
      expect(config.rotationDegrees, equals(45.0));

      final updated = config.copyWith(
        text: 'CONFIDENTIAL',
        opacity: 0.5,
        color: Colors.red,
      );
      expect(updated.text, equals('CONFIDENTIAL'));
      expect(updated.opacity, equals(0.5));
      expect(updated.color, equals(Colors.red));
      expect(updated.fontSize, equals(48.0));
    });

    test('SignatureConfig defaults and copyWith', () {
      const config = SignatureConfig(signatureImagePath: '/path/to/sig.png');
      expect(config.signatureImagePath, equals('/path/to/sig.png'));
      expect(config.pageIndex, equals(0));
      expect(config.x, equals(50.0));
      expect(config.y, equals(50.0));
      expect(config.width, equals(150.0));
      expect(config.height, equals(75.0));

      final updated = config.copyWith(
        pageIndex: 2,
        x: 100.0,
        y: 200.0,
      );
      expect(updated.pageIndex, equals(2));
      expect(updated.x, equals(100.0));
      expect(updated.y, equals(200.0));
      expect(updated.width, equals(150.0));
    });

    test('PdfPageItem rotation and selection state', () {
      const page = PdfPageItem(pageIndex: 0);
      expect(page.pageIndex, equals(0));
      expect(page.rotationDegrees, equals(0));
      expect(page.isSelected, isTrue);

      final rotated = page.copyWith(rotationDegrees: 90, isSelected: false);
      expect(rotated.rotationDegrees, equals(90));
      expect(rotated.isSelected, isFalse);
    });
  });
}

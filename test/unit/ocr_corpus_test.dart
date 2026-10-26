import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:doxivo/core/metrics/text_metrics.dart';
import 'package:doxivo/domain/models/ocr_language.dart';
import 'package:doxivo/services/ocr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OCR Corpus & Character Error Rate (CER) Tests', () {
    test('English corpus recognition meets CER threshold (< 0.05)', () async {
      const imgPath = 'test/fixtures/ocr/english_sample.png';
      const refPath = 'test/fixtures/ocr/english_sample.txt';

      expect(File(imgPath).existsSync(), isTrue);
      expect(File(refPath).existsSync(), isTrue);

      final groundTruth = await File(refPath).readAsString();
      final ocrResult = await OcrService.recognizeImage(
        imgPath,
        language: OcrLanguage.english,
      );

      expect(ocrResult.isSuccess, isTrue);
      expect(ocrResult.hasText, isTrue);
      expect(ocrResult.lines, isNotEmpty);

      final cer = TextMetrics.calculateCer(groundTruth, ocrResult.fullText, ignoreWhitespace: true);
      // CER should be 0.0 for clean fixture
      expect(cer, lessThan(0.05));
    });

    test('Hindi (Devanagari) corpus recognition meets CER threshold (< 0.05)', () async {
      const imgPath = 'test/fixtures/ocr/hindi_sample.png';
      const refPath = 'test/fixtures/ocr/hindi_sample.txt';

      expect(File(imgPath).existsSync(), isTrue);
      expect(File(refPath).existsSync(), isTrue);

      final groundTruth = await File(refPath).readAsString();
      final ocrResult = await OcrService.recognizeImage(
        imgPath,
        language: OcrLanguage.hindi,
      );

      expect(ocrResult.isSuccess, isTrue);
      expect(ocrResult.hasText, isTrue);
      expect(ocrResult.lines, isNotEmpty);

      final cer = TextMetrics.calculateCer(groundTruth, ocrResult.fullText, ignoreWhitespace: true);
      // CER should be 0.0 for clean fixture
      expect(cer, lessThan(0.05));
    });

    test('CER degrades predictably under synthetic character mutations', () {
      const originalText = 'DOXIVO DOCUMENT SCANNER AND PDF TOOLKIT';
      // Introduce 4 substitutions
      const corruptedText = 'DOXIV0 D0CUMENT SCANNER AND PDF T00LKIT';

      final cer = TextMetrics.calculateCer(originalText, corruptedText);
      expect(cer, greaterThan(0.0));
      expect(cer, lessThan(0.20)); // ~4 substitutions out of 39 characters = ~0.10
    });

    test('OcrCapabilities reports bundled Latin and Devanagari support', () async {
      final caps = await OcrService.getCapabilities();
      expect(caps.isSupported, isTrue);
      expect(caps.supportedLanguages, contains(OcrLanguage.english));
      expect(caps.supportedLanguages, contains(OcrLanguage.hindi));
    });

    test('Missing image file returns meaningful failure result', () async {
      final result = await OcrService.recognizeImage('/non/existent/path.png');
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('does not exist'));
    });
  });
}

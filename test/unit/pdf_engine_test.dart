import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:doxivo/poc/pdf_engine.dart';

void main() {
  group('PdfEngineService Tests', () {
    late Uint8List page1Jpg;
    late Uint8List page2Jpg;

    setUp(() {
      final img1 = img.Image(width: 300, height: 400);
      img.fill(img1, color: img.ColorRgb8(255, 255, 255));
      page1Jpg = Uint8List.fromList(img.encodeJpg(img1));

      final img2 = img.Image(width: 300, height: 400);
      img.fill(img2, color: img.ColorRgb8(245, 245, 245));
      page2Jpg = Uint8List.fromList(img.encodeJpg(img2));
    });

    test('Generates valid single-page PDF with magic header', () async {
      final pdfBytes = await PdfEngineService.createPdfFromImages([page1Jpg]);

      expect(pdfBytes, isNotEmpty);
      // Validate PDF magic number %PDF-
      final header = utf8.decode(pdfBytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('Generates multi-page PDF', () async {
      final pdfBytes = await PdfEngineService.createPdfFromImages([page1Jpg, page2Jpg]);

      expect(pdfBytes, isNotEmpty);
      final header = utf8.decode(pdfBytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
      // Valid PDF documents contain EOF marker
      final tail = String.fromCharCodes(pdfBytes.sublist(pdfBytes.length - 30));
      expect(tail.contains('%%EOF'), isTrue);
    });

    test('Generates PDF with watermark', () async {
      final pdfBytesWithout = await PdfEngineService.createPdfFromImages([page1Jpg]);
      final pdfBytesWith = await PdfEngineService.createPdfFromImages(
        [page1Jpg],
        watermarkText: 'CONFIDENTIAL',
      );

      expect(pdfBytesWith, isNotEmpty);
      expect(utf8.decode(pdfBytesWith.sublist(0, 5)), equals('%PDF-'));
      // Watermarked PDF has additional content streams and objects
      expect(pdfBytesWith.length, greaterThan(pdfBytesWithout.length));
    });
  });
}

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:doxivo/core/storage/file_storage_service.dart';
import 'package:doxivo/domain/models/ocr_language.dart';
import 'package:doxivo/domain/models/ocr_result.dart';
import 'package:doxivo/domain/models/ocr_text_geometry.dart';
import 'package:doxivo/services/pdf_toolkit_service.dart';
import 'package:doxivo/services/searchable_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late FileStorageService fileStorageService;
  late PdfToolkitService pdfToolkitService;
  late SearchablePdfService searchablePdfService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('doxivo_searchable_test_');
    fileStorageService = FileStorageService();
    await fileStorageService.initialize(customBaseDir: tempDir);
    pdfToolkitService = PdfToolkitService();
    searchablePdfService = SearchablePdfService(fileStorageService: fileStorageService);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('SearchablePdfService Tests', () {
    test('generateSearchablePdfFromImages creates valid PDF with magic header', () async {
      const fixtureImgPath = 'test/fixtures/ocr/english_sample.png';
      expect(File(fixtureImgPath).existsSync(), isTrue);

      final ocrResult = OcrResult(
        fullText: 'DOXIVO INVOICE INV-2026-9041',
        lines: [
          OcrLine(
            text: 'DOXIVO INVOICE INV-2026-9041',
            boundingBox: const OcrRect(left: 40, top: 40, width: 300, height: 20),
          ),
        ],
        language: OcrLanguage.english,
        imageWidth: 600,
        imageHeight: 800,
      );

      final outputFile = await searchablePdfService.generateSearchablePdfFromImages(
        imagePaths: [fixtureImgPath],
        ocrResults: [ocrResult],
      );

      expect(await outputFile.exists(), isTrue);
      final bytes = await outputFile.readAsBytes();
      expect(bytes.length, greaterThan(100));

      // PDF Magic Header validation
      final magicHeader = String.fromCharCodes(bytes.take(5));
      expect(magicHeader, equals('%PDF-'));
    });

    test('makePdfSearchable converts existing document using on-device OCR', () async {
      // First create a base dummy PDF using PdfToolkitService mock
      final basePdfFile = File('${tempDir.path}/base_document.pdf');
      await basePdfFile.writeAsBytes(List.filled(200, 0x25));

      final searchableFile = await searchablePdfService.makePdfSearchable(
        basePdfFile.path,
        pdfToolkitService: pdfToolkitService,
        language: OcrLanguage.english,
      );

      expect(await searchableFile.exists(), isTrue);
      final bytes = await searchableFile.readAsBytes();
      final header = String.fromCharCodes(bytes.take(5));
      expect(header, equals('%PDF-'));
    });

    test('throws ArgumentError on empty image paths', () async {
      expect(
        () => searchablePdfService.generateSearchablePdfFromImages(
          imagePaths: [],
          ocrResults: [],
        ),
        throwsArgumentError,
      );
    });
  });
}

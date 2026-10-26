import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:doxivo/core/storage/file_storage_service.dart';
import 'package:doxivo/domain/models/compression_preset.dart';
import 'package:doxivo/domain/models/scanned_page.dart';
import 'package:doxivo/domain/models/signature_config.dart';
import 'package:doxivo/domain/models/watermark_config.dart';
import 'package:doxivo/services/pdf_service.dart';
import 'package:doxivo/services/pdf_toolkit_service.dart';
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfToolkitService Operations Tests', () {
    late Directory tempDir;
    late FileStorageService storageService;
    late PdfService pdfService;
    late PdfToolkitService toolkitService;
    late String sampleDoc1Path;
    late String sampleDoc2Path;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('pdf_toolkit_test_');
      storageService = FileStorageService();
      await storageService.initialize(customBaseDir: tempDir);
      pdfService = PdfService(fileStorageService: storageService);
      toolkitService = PdfToolkitService();

      // Create a test page image
      final sampleImg = img.Image(width: 100, height: 100);
      img.fill(sampleImg, color: img.ColorRgb8(255, 255, 255));
      final imgBytes = img.encodeJpg(sampleImg);
      final imgFile1 = File('${tempDir.path}/page1.jpg');
      await imgFile1.writeAsBytes(imgBytes);

      final imgFile2 = File('${tempDir.path}/page2.jpg');
      await imgFile2.writeAsBytes(imgBytes);

      // Create 2 test PDFs via PdfService
      final doc1 = await pdfService.createDocumentFromPages(
        title: 'Doc One',
        pages: [
          ScannedPage(id: 'p1', originalPath: imgFile1.path, currentPath: imgFile1.path),
          ScannedPage(id: 'p2', originalPath: imgFile2.path, currentPath: imgFile2.path),
        ],
      );
      sampleDoc1Path = doc1.filePath;

      final doc2 = await pdfService.createDocumentFromPages(
        title: 'Doc Two',
        pages: [
          ScannedPage(id: 'p3', originalPath: imgFile1.path, currentPath: imgFile1.path),
        ],
      );
      sampleDoc2Path = doc2.filePath;
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('getPageCount returns estimated or actual page count', () async {
      final count = await toolkitService.getPageCount(sampleDoc1Path);
      expect(count, greaterThanOrEqualTo(1));
    });

    test('mergePdfs throws if fewer than 2 input paths', () async {
      final outPath = '${tempDir.path}/merged_invalid.pdf';
      expect(
        () => toolkitService.mergePdfs(inputPaths: [sampleDoc1Path], outputPath: outPath),
        throwsArgumentError,
      );
    });

    test('mergePdfs combines multiple files into output PDF', () async {
      final outPath = '${tempDir.path}/merged_success.pdf';
      final result = await toolkitService.mergePdfs(
        inputPaths: [sampleDoc1Path, sampleDoc2Path],
        outputPath: outPath,
      );

      expect(result, equals(outPath));
      final outFile = File(outPath);
      expect(outFile.existsSync(), isTrue);
      final bytes = await outFile.readAsBytes();
      expect(String.fromCharCodes(bytes.sublist(0, 5)), equals('%PDF-'));
    });

    test('splitPdf produces split document files', () async {
      final splitDir = '${tempDir.path}/splits';
      final parts = await toolkitService.splitPdf(
        inputPath: sampleDoc1Path,
        outputDir: splitDir,
      );

      expect(parts.isNotEmpty, isTrue);
      for (final part in parts) {
        final partFile = File(part);
        expect(partFile.existsSync(), isTrue);
        final bytes = await partFile.readAsBytes();
        expect(String.fromCharCodes(bytes.sublist(0, 5)), equals('%PDF-'));
      }
    });

    test('extractPages extracts specified pages', () async {
      final outPath = '${tempDir.path}/extracted.pdf';
      final result = await toolkitService.extractPages(
        inputPath: sampleDoc1Path,
        outputPath: outPath,
        pageIndices: [0],
      );

      expect(result, equals(outPath));
      final outFile = File(outPath);
      expect(outFile.existsSync(), isTrue);
      final bytes = await outFile.readAsBytes();
      expect(String.fromCharCodes(bytes.sublist(0, 5)), equals('%PDF-'));
    });

    test('reorderAndRotatePages outputs valid transformed PDF', () async {
      final outPath = '${tempDir.path}/reordered.pdf';
      final result = await toolkitService.reorderAndRotatePages(
        inputPath: sampleDoc1Path,
        outputPath: outPath,
        pageIndices: [1, 0],
        rotations: [90, 180],
      );

      expect(result, equals(outPath));
      final outFile = File(outPath);
      expect(outFile.existsSync(), isTrue);
      final bytes = await outFile.readAsBytes();
      expect(String.fromCharCodes(bytes.sublist(0, 5)), equals('%PDF-'));
    });

    test('addWatermark overlays watermark and outputs valid PDF', () async {
      final outPath = '${tempDir.path}/watermarked_out.pdf';
      final result = await toolkitService.addWatermark(
        inputPath: sampleDoc1Path,
        outputPath: outPath,
        config: const WatermarkConfig(text: 'SAMPLE TEST'),
      );

      expect(result, equals(outPath));
      final outFile = File(outPath);
      expect(outFile.existsSync(), isTrue);
      final bytes = await outFile.readAsBytes();
      expect(String.fromCharCodes(bytes.sublist(0, 5)), equals('%PDF-'));
    });

    test('addSignature places signature image and outputs valid PDF', () async {
      final sigFile = File('${tempDir.path}/sig.png');
      await sigFile.writeAsBytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]); // PNG header

      final outPath = '${tempDir.path}/signed_out.pdf';
      final result = await toolkitService.addSignature(
        inputPath: sampleDoc1Path,
        outputPath: outPath,
        config: SignatureConfig(signatureImagePath: sigFile.path),
      );

      expect(result, equals(outPath));
      final outFile = File(outPath);
      expect(outFile.existsSync(), isTrue);
      final bytes = await outFile.readAsBytes();
      expect(String.fromCharCodes(bytes.sublist(0, 5)), equals('%PDF-'));
    });

    test('compressPdf executes and returns result reporting sizes', () async {
      final outPath = '${tempDir.path}/compressed_out.pdf';
      final result = await toolkitService.compressPdf(
        inputPath: sampleDoc1Path,
        outputPath: outPath,
        preset: CompressionPreset.medium,
      );

      expect(result.isSuccess, isTrue);
      expect(result.beforeBytes, greaterThan(0));
      expect(result.afterBytes, greaterThan(0));
      expect(File(outPath).existsSync(), isTrue);
    });
  });
}

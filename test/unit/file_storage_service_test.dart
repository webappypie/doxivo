import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:doxivo/core/storage/file_storage_service.dart';

void main() {
  group('FileStorageService Tests', () {
    late Directory tempTestDir;
    late FileStorageService storageService;

    setUp(() async {
      tempTestDir = await Directory.systemTemp.createTemp('doxivo_test_storage_');
      storageService = FileStorageService();
      await storageService.initialize(customBaseDir: tempTestDir);
    });

    tearDown(() async {
      if (await tempTestDir.exists()) {
        await tempTestDir.delete(recursive: true);
      }
    });

    test('Initializes required subdirectories', () {
      expect(storageService.documentsDir.existsSync(), isTrue);
      expect(storageService.thumbnailsDir.existsSync(), isTrue);
      expect(storageService.tempDir.existsSync(), isTrue);
    });

    test('Sanitizes dangerous filename characters', () {
      expect(
        FileStorageService.sanitizeFilename('invoice/2026:01*test?.pdf'),
        equals('invoice_2026_01_test_.pdf'),
      );
      expect(
        FileStorageService.sanitizeFilename('  my   document  '),
        equals('my document'),
      );
    });

    test('Writes data atomically via temporary file', () async {
      final destPath = '${storageService.documentsDir.path}/test_doc.txt';
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      final file = await storageService.writeBytesAtomically(destPath, bytes);
      expect(file.existsSync(), isTrue);
      expect(await file.readAsBytes(), equals(bytes));
    });

    test('Saves managed PDF and thumbnail correctly', () async {
      final dummyPdf = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D]); // %PDF-
      final pdfFile = await storageService.saveManagedPdf('Report 2026', dummyPdf);

      expect(pdfFile.existsSync(), isTrue);
      expect(pdfFile.path.endsWith('Report 2026.pdf'), isTrue);

      final dummyThumb = Uint8List.fromList([0xFF, 0xD8, 0xFF]);
      final thumbFile = await storageService.saveThumbnail('doc_123', dummyThumb);

      expect(thumbFile.existsSync(), isTrue);
      expect(thumbFile.path.contains('doc_123_thumb.jpg'), isTrue);
    });

    test('Cleans temp directory files', () async {
      final tempFile1 = File(storageService.createTempFilePath(extension: 'jpg'));
      await tempFile1.writeAsString('temp data 1');
      final tempFile2 = File(storageService.createTempFilePath(extension: 'tmp'));
      await tempFile2.writeAsString('temp data 2');

      expect(storageService.tempDir.listSync().length, equals(2));

      final deleted = await storageService.cleanTempDirectory();
      expect(deleted, equals(2));
      expect(storageService.tempDir.listSync().isEmpty, isTrue);
    });
  });
}

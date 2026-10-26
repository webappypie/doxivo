import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:doxivo/core/database/app_database.dart';
import 'package:doxivo/domain/models/document_model.dart';
import 'package:doxivo/domain/models/ocr_result.dart';
import 'package:doxivo/domain/repositories/document_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase appDatabase;
  late DocumentRepository repository;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('doxivo_ocr_db_test_');
    final dbPath = '${tempDir.path}/test_ocr_library.db';
    appDatabase = AppDatabase();
    await appDatabase.initDatabase(customPath: dbPath);
    repository = DocumentRepository(appDatabase: appDatabase);
  });

  tearDown(() async {
    await appDatabase.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('OCR Indexing & Search Tests', () {
    test('indexes OCR results and checks indexed status', () async {
      final doc = DocumentModel(
        id: 'doc_tax_2026',
        title: 'Q4 Financial Report',
        filePath: '${tempDir.path}/doc_tax.pdf',
        pageCount: 2,
        byteSize: 4096,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repository.insertDocument(doc);

      expect(await repository.isDocumentIndexed(doc.id), isFalse);

      final ocrPages = [
        const OcrResult(
          fullText: 'Quarterly financial overview with subtotal \$50,000 and net margin 22%.',
          pageIndex: 0,
        ),
        const OcrResult(
          fullText: 'Invoice details: Vendor Acquirer Corp, Tax ID: TAX-9901-XYZ.',
          pageIndex: 1,
        ),
      ];

      await repository.indexDocumentOcr(doc.id, ocrPages);

      expect(await repository.isDocumentIndexed(doc.id), isTrue);
      final indexedPages = await repository.getOcrIndexedPages(doc.id);
      expect(indexedPages.length, equals(2));
      expect(indexedPages[0].textContent, contains('subtotal'));
      expect(indexedPages[1].textContent, contains('Acquirer Corp'));
    });

    test('search finds matches by document title and by OCR text content', () async {
      final doc1 = DocumentModel(
        id: 'doc_1',
        title: 'Healthcare Insurance Policy',
        filePath: '${tempDir.path}/policy.pdf',
        pageCount: 1,
        byteSize: 1024,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final doc2 = DocumentModel(
        id: 'doc_2',
        title: 'Scanned Receipt',
        filePath: '${tempDir.path}/receipt.pdf',
        pageCount: 1,
        byteSize: 1024,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.insertDocument(doc1);
      await repository.insertDocument(doc2);

      // doc2 has OCR text containing "Hospital" even though its title is "Scanned Receipt"
      await repository.indexDocumentOcr(doc2.id, [
        const OcrResult(
          fullText: 'Paid to Central City Hospital pharmacy department total: \$45.00',
          pageIndex: 0,
        ),
      ]);

      // 1. Search for "Healthcare" -> matches doc1 by title
      final titleMatches = await repository.search('Healthcare');
      expect(titleMatches.length, equals(1));
      expect(titleMatches.first.document.id, equals(doc1.id));
      expect(titleMatches.first.matchedTitle, isTrue);
      expect(titleMatches.first.hasOcrMatches, isFalse);

      // 2. Search for "Hospital" -> matches doc2 by OCR index text!
      final ocrMatches = await repository.search('Hospital');
      expect(ocrMatches.length, equals(1));
      expect(ocrMatches.first.document.id, equals(doc2.id));
      expect(ocrMatches.first.matchedTitle, isFalse);
      expect(ocrMatches.first.hasOcrMatches, isTrue);

      final snippet = ocrMatches.first.ocrMatches.first;
      expect(snippet.matchedText, equals('Hospital'));
      expect(snippet.snippetContext, contains('Hospital'));
      expect(snippet.pageIndex, equals(0));
    });

    test('reindex clears old index and updates with new OCR results', () async {
      final doc = DocumentModel(
        id: 'doc_reindex',
        title: 'Draft Contract',
        filePath: '${tempDir.path}/contract.pdf',
        pageCount: 1,
        byteSize: 1024,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repository.insertDocument(doc);

      // Initial index with draft text
      await repository.indexDocumentOcr(doc.id, [
        const OcrResult(fullText: 'Preliminary terms draft v1'),
      ]);

      var matches = await repository.search('Preliminary');
      expect(matches.length, equals(1));

      // Re-index with finalized text
      await repository.indexDocumentOcr(doc.id, [
        const OcrResult(fullText: 'Final executed agreement signed'),
      ]);

      // Old keyword should no longer match
      matches = await repository.search('Preliminary');
      expect(matches, isEmpty);

      // New keyword matches
      matches = await repository.search('executed agreement');
      expect(matches.length, equals(1));
    });

    test('deleting a document removes its OCR index cascadingly', () async {
      final doc = DocumentModel(
        id: 'doc_to_delete',
        title: 'Delete Test Doc',
        filePath: '${tempDir.path}/del.pdf',
        pageCount: 1,
        byteSize: 1024,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repository.insertDocument(doc);
      await repository.indexDocumentOcr(doc.id, [
        const OcrResult(fullText: 'Secret sensitive indexed data'),
      ]);

      expect(await repository.isDocumentIndexed(doc.id), isTrue);

      await repository.deleteDocument(doc.id);

      expect(await repository.isDocumentIndexed(doc.id), isFalse);
      final searchRes = await repository.search('Secret sensitive');
      expect(searchRes, isEmpty);
    });
  });
}

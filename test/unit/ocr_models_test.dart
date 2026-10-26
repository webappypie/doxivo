import 'package:flutter_test/flutter_test.dart';
import 'package:doxivo/domain/models/document_model.dart';
import 'package:doxivo/domain/models/document_search_result.dart';
import 'package:doxivo/domain/models/ocr_index_item.dart';
import 'package:doxivo/domain/models/ocr_language.dart';
import 'package:doxivo/domain/models/ocr_result.dart';
import 'package:doxivo/domain/models/ocr_text_geometry.dart';

void main() {
  group('OCR Domain Models Tests', () {
    test('OcrLanguage enum mappings and fromCode', () {
      expect(OcrLanguage.english.code, equals('en'));
      expect(OcrLanguage.english.scriptName, equals('Latin'));
      expect(OcrLanguage.hindi.code, equals('hi'));
      expect(OcrLanguage.hindi.scriptName, equals('Devanagari'));

      expect(OcrLanguage.fromCode('en'), equals(OcrLanguage.english));
      expect(OcrLanguage.fromCode('hi'), equals(OcrLanguage.hindi));
      expect(OcrLanguage.fromCode('HI'), equals(OcrLanguage.hindi));
      expect(OcrLanguage.fromCode('unknown'), equals(OcrLanguage.english));
    });

    test('OcrRect geometry and serialization', () {
      const rect = OcrRect(left: 10.0, top: 20.0, width: 100.0, height: 50.0);
      expect(rect.right, equals(110.0));
      expect(rect.bottom, equals(70.0));

      final map = rect.toMap();
      final reconstructed = OcrRect.fromMap(map);
      expect(reconstructed.left, equals(10.0));
      expect(reconstructed.top, equals(20.0));
      expect(reconstructed.width, equals(100.0));
      expect(reconstructed.height, equals(50.0));
    });

    test('OcrResult helper metrics and failure constructor', () {
      const emptyResult = OcrResult(fullText: '');
      expect(emptyResult.hasText, isFalse);
      expect(emptyResult.wordCount, equals(0));
      expect(emptyResult.lineCount, equals(0));

      const validResult = OcrResult(
        fullText: 'Doxivo Scanner\nInvoice #1042\nTotal: \$120',
        language: OcrLanguage.english,
      );
      expect(validResult.hasText, isTrue);
      expect(validResult.wordCount, equals(6));
      expect(validResult.lineCount, equals(3));

      final failure = OcrResult.failure(
        errorMessage: 'Invalid image format',
        language: OcrLanguage.hindi,
        pageIndex: 2,
      );
      expect(failure.isSuccess, isFalse);
      expect(failure.errorMessage, contains('Invalid image format'));
      expect(failure.language, equals(OcrLanguage.hindi));
      expect(failure.pageIndex, equals(2));
    });

    test('OcrIndexItem map serialization', () {
      final now = DateTime.now();
      final item = OcrIndexItem(
        id: 'idx_1',
        documentId: 'doc_100',
        pageIndex: 0,
        textContent: 'Scanned receipt details',
        language: 'en',
        createdAt: now,
      );

      final map = item.toMap();
      expect(map['id'], equals('idx_1'));
      expect(map['document_id'], equals('doc_100'));
      expect(map['page_index'], equals(0));
      expect(map['text_content'], equals('Scanned receipt details'));

      final reconstructed = OcrIndexItem.fromMap(map);
      expect(reconstructed.id, equals('idx_1'));
      expect(reconstructed.documentId, equals('doc_100'));
      expect(reconstructed.pageIndex, equals(0));
      expect(reconstructed.textContent, equals('Scanned receipt details'));
    });

    test('DocumentSearchResult aggregates title and OCR matches', () {
      final doc = DocumentModel(
        id: 'doc_1',
        title: 'Q3 Tax Invoice',
        filePath: '/tmp/doc1.pdf',
        pageCount: 2,
        byteSize: 2048,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      const snippet = OcrSearchSnippet(
        pageIndex: 1,
        matchedText: 'Tax',
        snippetContext: '...Tax (18%): \$225.00...',
      );

      final result = DocumentSearchResult(
        document: doc,
        matchedTitle: true,
        ocrMatches: const [snippet],
      );

      expect(result.matchedTitle, isTrue);
      expect(result.hasOcrMatches, isTrue);
      expect(result.totalMatches, equals(2));
      expect(result.ocrMatches.first.pageIndex, equals(1));
    });
  });
}

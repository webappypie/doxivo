import 'dart:io';
import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../models/document_model.dart';
import '../models/document_search_result.dart';
import '../models/ocr_index_item.dart';
import '../models/ocr_result.dart';

class DocumentRepository {
  final AppDatabase appDatabase;

  DocumentRepository({required this.appDatabase});

  Future<void> insertDocument(DocumentModel doc) async {
    final db = await appDatabase.database;
    await db.insert(
      'documents',
      doc.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateDocument(DocumentModel doc) async {
    final db = await appDatabase.database;
    await db.update(
      'documents',
      doc.toMap(),
      where: 'id = ?',
      whereArgs: [doc.id],
    );
  }

  Future<DocumentModel?> getDocumentById(String id) async {
    final db = await appDatabase.database;
    final results = await db.query(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return DocumentModel.fromMap(results.first);
  }

  Future<List<DocumentModel>> getAllDocuments({
    String? searchQuery,
    bool favoritesOnly = false,
  }) async {
    final db = await appDatabase.database;

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final searchResults = await search(searchQuery.trim(), favoritesOnly: favoritesOnly);
      return searchResults.map((r) => r.document).toList();
    }

    String? whereClause;
    List<dynamic> whereArgs = [];

    if (favoritesOnly) {
      whereClause = 'is_favorite = 1';
    }

    final results = await db.query(
      'documents',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
    );

    return results.map((map) => DocumentModel.fromMap(map)).toList();
  }

  Future<void> toggleFavorite(String id) async {
    final doc = await getDocumentById(id);
    if (doc == null) return;
    final updated = doc.copyWith(
      isFavorite: !doc.isFavorite,
      updatedAt: DateTime.now(),
    );
    await updateDocument(updated);
  }

  Future<void> renameDocument(String id, String newTitle) async {
    final doc = await getDocumentById(id);
    if (doc == null) return;
    final updated = doc.copyWith(
      title: newTitle.trim(),
      updatedAt: DateTime.now(),
    );
    await updateDocument(updated);
  }

  Future<void> deleteDocument(String id) async {
    final doc = await getDocumentById(id);
    if (doc != null) {
      // Clean up physical files safely
      try {
        final file = File(doc.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}

      if (doc.thumbnailPath != null) {
        try {
          final thumb = File(doc.thumbnailPath!);
          if (await thumb.exists()) {
            await thumb.delete();
          }
        } catch (_) {}
      }
    }

    final db = await appDatabase.database;
    await db.delete(
      'ocr_indexes',
      where: 'document_id = ?',
      whereArgs: [id],
    );

    await db.delete(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- OCR Indexing & Search ---

  Future<void> insertOcrIndex(OcrIndexItem item) async {
    final db = await appDatabase.database;
    await db.insert(
      'ocr_indexes',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearDocumentOcrIndex(String documentId) async {
    final db = await appDatabase.database;
    await db.delete(
      'ocr_indexes',
      where: 'document_id = ?',
      whereArgs: [documentId],
    );
  }

  Future<void> indexDocumentOcr(String documentId, List<OcrResult> results) async {
    await clearDocumentOcrIndex(documentId);
    final now = DateTime.now();

    for (int i = 0; i < results.length; i++) {
      final res = results[i];
      if (res.hasText) {
        final item = OcrIndexItem(
          id: '${documentId}_page_$i',
          documentId: documentId,
          pageIndex: i,
          textContent: res.fullText,
          language: res.language.code,
          createdAt: now,
        );
        await insertOcrIndex(item);
      }
    }
  }

  Future<bool> isDocumentIndexed(String documentId) async {
    final db = await appDatabase.database;
    final res = await db.query(
      'ocr_indexes',
      columns: ['id'],
      where: 'document_id = ?',
      whereArgs: [documentId],
      limit: 1,
    );
    return res.isNotEmpty;
  }

  Future<List<OcrIndexItem>> getOcrIndexedPages(String documentId) async {
    final db = await appDatabase.database;
    final res = await db.query(
      'ocr_indexes',
      where: 'document_id = ?',
      whereArgs: [documentId],
      orderBy: 'page_index ASC',
    );
    return res.map((m) => OcrIndexItem.fromMap(m)).toList();
  }

  Future<List<DocumentSearchResult>> search(
    String query, {
    bool favoritesOnly = false,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      final all = await getAllDocuments(favoritesOnly: favoritesOnly);
      return all.map((d) => DocumentSearchResult(document: d)).toList();
    }

    final db = await appDatabase.database;
    final searchPattern = '%$trimmed%';

    // 1. Search by document title
    String titleWhere = 'title LIKE ?';
    List<dynamic> titleArgs = [searchPattern];
    if (favoritesOnly) {
      titleWhere += ' AND is_favorite = 1';
    }

    final titleRows = await db.query(
      'documents',
      where: titleWhere,
      whereArgs: titleArgs,
      orderBy: 'created_at DESC',
    );

    final titleDocs = titleRows.map((r) => DocumentModel.fromMap(r)).toList();

    // 2. Search by OCR index text
    final ocrRows = await db.rawQuery('''
      SELECT o.document_id, o.page_index, o.text_content, d.*
      FROM ocr_indexes o
      INNER JOIN documents d ON o.document_id = d.id
      WHERE o.text_content LIKE ? ${favoritesOnly ? 'AND d.is_favorite = 1' : ''}
      ORDER BY d.created_at DESC
    ''', [searchPattern]);

    final Map<String, DocumentSearchResult> resultsMap = {};

    // Populate title matches
    for (final doc in titleDocs) {
      resultsMap[doc.id] = DocumentSearchResult(
        document: doc,
        matchedTitle: true,
        ocrMatches: [],
      );
    }

    // Populate OCR text matches with snippets
    for (final row in ocrRows) {
      final docId = row['document_id'] as String;
      final pageIndex = row['page_index'] as int;
      final textContent = row['text_content'] as String;

      final snippet = _extractSnippet(textContent, trimmed, pageIndex);

      if (resultsMap.containsKey(docId)) {
        final existing = resultsMap[docId]!;
        final updatedSnippets = List<OcrSearchSnippet>.from(existing.ocrMatches)..add(snippet);
        resultsMap[docId] = DocumentSearchResult(
          document: existing.document,
          matchedTitle: existing.matchedTitle,
          ocrMatches: updatedSnippets,
        );
      } else {
        final doc = DocumentModel.fromMap(row);
        resultsMap[docId] = DocumentSearchResult(
          document: doc,
          matchedTitle: false,
          ocrMatches: [snippet],
        );
      }
    }

    return resultsMap.values.toList();
  }

  static OcrSearchSnippet _extractSnippet(String text, String term, int pageIndex) {
    final lowerText = text.toLowerCase();
    final lowerTerm = term.toLowerCase();
    final matchIndex = lowerText.indexOf(lowerTerm);

    if (matchIndex < 0) {
      final preview = text.length > 80 ? '${text.substring(0, 80)}...' : text;
      return OcrSearchSnippet(
        pageIndex: pageIndex,
        matchedText: term,
        snippetContext: preview.replaceAll('\n', ' '),
      );
    }

    final start = (matchIndex - 35).clamp(0, text.length);
    final end = (matchIndex + term.length + 35).clamp(0, text.length);

    String snippet = text.substring(start, end).replaceAll('\n', ' ').trim();
    if (start > 0) snippet = '...$snippet';
    if (end < text.length) snippet = '$snippet...';

    return OcrSearchSnippet(
      pageIndex: pageIndex,
      matchedText: term,
      snippetContext: snippet,
    );
  }
}

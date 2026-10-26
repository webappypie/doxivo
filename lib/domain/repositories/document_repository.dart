import 'dart:io';
import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../models/document_model.dart';

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
    String? whereClause;
    List<dynamic> whereArgs = [];

    if (favoritesOnly) {
      whereClause = 'is_favorite = 1';
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final searchPattern = '%${searchQuery.trim()}%';
      if (whereClause != null) {
        whereClause += ' AND title LIKE ?';
      } else {
        whereClause = 'title LIKE ?';
      }
      whereArgs.add(searchPattern);
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
      'documents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:doxivo/core/database/app_database.dart';
import 'package:doxivo/domain/models/document_model.dart';
import 'package:doxivo/domain/repositories/document_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('DocumentRepository CRUD & Queries', () {
    late AppDatabase appDatabase;
    late DocumentRepository repository;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('doxivo_repo_test_');
      final dbPath = '${tempDir.path}/test_lib.db';
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

    test('Inserts and retrieves document by ID', () async {
      final doc = DocumentModel(
        id: 'doc_1',
        title: 'Tax Document',
        filePath: '${tempDir.path}/tax.pdf',
        pageCount: 3,
        byteSize: 10240,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.insertDocument(doc);
      final retrieved = await repository.getDocumentById('doc_1');

      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('doc_1'));
      expect(retrieved.title, equals('Tax Document'));
      expect(retrieved.pageCount, equals(3));
      expect(retrieved.byteSize, equals(10240));
      expect(retrieved.isFavorite, isFalse);
    });

    test('Toggles favorite status', () async {
      final doc = DocumentModel(
        id: 'doc_2',
        title: 'Passport',
        filePath: '${tempDir.path}/passport.pdf',
        pageCount: 1,
        byteSize: 5000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite: false,
      );

      await repository.insertDocument(doc);
      await repository.toggleFavorite('doc_2');

      final favDoc = await repository.getDocumentById('doc_2');
      expect(favDoc!.isFavorite, isTrue);

      await repository.toggleFavorite('doc_2');
      final unFavDoc = await repository.getDocumentById('doc_2');
      expect(unFavDoc!.isFavorite, isFalse);
    });

    test('Renames document', () async {
      final doc = DocumentModel(
        id: 'doc_3',
        title: 'Draft Invoice',
        filePath: '${tempDir.path}/inv.pdf',
        pageCount: 2,
        byteSize: 8000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.insertDocument(doc);
      await repository.renameDocument('doc_3', 'Final Invoice');

      final renamed = await repository.getDocumentById('doc_3');
      expect(renamed!.title, equals('Final Invoice'));
    });

    test('Filters documents by search query and favorite flag', () async {
      final now = DateTime.now();
      await repository.insertDocument(
        DocumentModel(
          id: '1',
          title: 'Electricity Bill',
          filePath: '${tempDir.path}/1.pdf',
          pageCount: 1,
          byteSize: 2000,
          createdAt: now,
          updatedAt: now,
          isFavorite: false,
        ),
      );
      await repository.insertDocument(
        DocumentModel(
          id: '2',
          title: 'Water Bill',
          filePath: '${tempDir.path}/2.pdf',
          pageCount: 1,
          byteSize: 2000,
          createdAt: now.add(const Duration(seconds: 1)),
          updatedAt: now,
          isFavorite: true,
        ),
      );
      await repository.insertDocument(
        DocumentModel(
          id: '3',
          title: 'Bank Statement',
          filePath: '${tempDir.path}/3.pdf',
          pageCount: 5,
          byteSize: 25000,
          createdAt: now.add(const Duration(seconds: 2)),
          updatedAt: now,
          isFavorite: true,
        ),
      );

      // All documents
      final all = await repository.getAllDocuments();
      expect(all.length, equals(3));

      // Search query
      final bills = await repository.getAllDocuments(searchQuery: 'Bill');
      expect(bills.length, equals(2));

      // Favorites only
      final favs = await repository.getAllDocuments(favoritesOnly: true);
      expect(favs.length, equals(2));

      // Search + Favorites
      final favBills = await repository.getAllDocuments(searchQuery: 'Water', favoritesOnly: true);
      expect(favBills.length, equals(1));
      expect(favBills.first.title, equals('Water Bill'));
    });

    test('Deletes document and associated physical files', () async {
      final pdfFile = File('${tempDir.path}/delete_me.pdf');
      await pdfFile.writeAsString('test pdf');
      final thumbFile = File('${tempDir.path}/delete_me_thumb.jpg');
      await thumbFile.writeAsString('test thumb');

      final doc = DocumentModel(
        id: 'doc_del',
        title: 'To Delete',
        filePath: pdfFile.path,
        thumbnailPath: thumbFile.path,
        pageCount: 1,
        byteSize: 100,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.insertDocument(doc);
      expect(pdfFile.existsSync(), isTrue);
      expect(thumbFile.existsSync(), isTrue);

      await repository.deleteDocument('doc_del');

      final retrieved = await repository.getDocumentById('doc_del');
      expect(retrieved, isNull);
      expect(pdfFile.existsSync(), isFalse);
      expect(thumbFile.existsSync(), isFalse);
    });
  });
}

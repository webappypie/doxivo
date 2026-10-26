import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:doxivo/core/database/app_database.dart';
import 'package:doxivo/core/storage/file_storage_service.dart';
import 'package:doxivo/domain/models/document_model.dart';
import 'package:doxivo/domain/repositories/document_repository.dart';
import 'package:doxivo/presentation/ocr/ocr_screen.dart';
import 'package:doxivo/services/pdf_toolkit_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;
  late AppDatabase appDatabase;
  late DocumentRepository documentRepository;
  late FileStorageService fileStorageService;
  late PdfToolkitService pdfToolkitService;
  late DocumentModel sampleDoc;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('doxivo_ocr_screen_test_');
    final dbPath = '${tempDir.path}/test_ocr_screen.db';
    appDatabase = AppDatabase();
    await appDatabase.initDatabase(customPath: dbPath);
    documentRepository = DocumentRepository(appDatabase: appDatabase);

    fileStorageService = FileStorageService();
    await fileStorageService.initialize(customBaseDir: tempDir);
    pdfToolkitService = PdfToolkitService();

    final pdfFile = File('${tempDir.path}/sample.pdf');
    await pdfFile.writeAsBytes(List.filled(200, 0x25));

    sampleDoc = DocumentModel(
      id: 'doc_ocr_test',
      title: 'Tax Invoice 2026',
      filePath: pdfFile.path,
      pageCount: 1,
      byteSize: 200,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await documentRepository.insertDocument(sampleDoc);
  });

  tearDown(() async {
    await appDatabase.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('OcrScreen displays document title, language chips, and actions', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: OcrScreen(
            document: sampleDoc,
            documentRepository: documentRepository,
            fileStorageService: fileStorageService,
            pdfToolkitService: pdfToolkitService,
          ),
        ),
      );

      // Allow real file I/O & asynchronous recognition to complete
      await Future.delayed(const Duration(milliseconds: 500));
    });

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify title and script chips
    expect(find.text('Tax Invoice 2026'), findsOneWidget);
    expect(find.text('English (Latin)'), findsOneWidget);
    expect(find.text('Hindi (Devanagari)'), findsOneWidget);

    // Verify bottom actions
    expect(find.text('Searchable PDF'), findsOneWidget);
  });
}

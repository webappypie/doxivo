import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:doxivo/core/database/app_database.dart';
import 'package:doxivo/core/storage/file_storage_service.dart';
import 'package:doxivo/domain/repositories/document_repository.dart';
import 'package:doxivo/presentation/toolkit/tools_hub_screen.dart';
import 'package:doxivo/services/pdf_toolkit_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('ToolsHubScreen lists all PDF toolkit operations', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tempDir = Directory.systemTemp.createTempSync('tools_hub_test_');

    final storage = FileStorageService();
    final db = AppDatabase();

    await tester.runAsync(() async {
      await storage.initialize(customBaseDir: tempDir);
      await db.initDatabase(customPath: '${tempDir.path}/test_tools.db');
    });

    final repo = DocumentRepository(appDatabase: db);
    final toolkitService = PdfToolkitService();

    await tester.pumpWidget(
      MaterialApp(
        home: ToolsHubScreen(
          documentRepository: repo,
          fileStorageService: storage,
          pdfToolkitService: toolkitService,
        ),
      ),
    );

    await tester.pump();

    // Verify all tool entries are listed
    expect(find.text('PDF Toolkit'), findsOneWidget);
    expect(find.text('Import External PDF'), findsOneWidget);
    expect(find.text('Merge PDFs'), findsOneWidget);
    expect(find.text('Split PDF'), findsOneWidget);
    expect(find.text('Organize & Rotate Pages'), findsOneWidget);
    expect(find.text('Compress PDF'), findsOneWidget);
    expect(find.text('Protect PDF (Password)'), findsOneWidget);
    expect(find.text('Sign PDF'), findsOneWidget);
    expect(find.text('Add Watermark'), findsOneWidget);
    expect(find.text('Export as Images'), findsOneWidget);

    // Tap Merge PDFs
    await tester.tap(find.text('Merge PDFs'));
    await tester.pumpAndSettle();

    expect(find.text('Merge PDFs'), findsWidgets);
    expect(find.text('From Library'), findsOneWidget);
    expect(find.text('From Device'), findsOneWidget);

    await tester.runAsync(() async {
      await db.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}

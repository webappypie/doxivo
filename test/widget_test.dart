import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:doxivo/core/database/app_database.dart';
import 'package:doxivo/core/storage/file_storage_service.dart';
import 'package:doxivo/domain/repositories/document_repository.dart';
import 'package:doxivo/main.dart';
import 'package:doxivo/services/pdf_service.dart';
import 'package:doxivo/services/scanner_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('Doxivo App and Home Screen initial smoke test', (WidgetTester tester) async {
    final tempDir = Directory.systemTemp.createTempSync('doxivo_widget_test_');

    final storage = FileStorageService();
    final db = AppDatabase();

    await tester.runAsync(() async {
      await storage.initialize(customBaseDir: tempDir);
      await db.initDatabase(customPath: '${tempDir.path}/widget_test.db');
    });

    final repo = DocumentRepository(appDatabase: db);
    final pdfService = PdfService(fileStorageService: storage);
    final scanner = ScannerService();

    await tester.pumpWidget(
      DoxivoApp(
        fileStorageService: storage,
        documentRepository: repo,
        pdfService: pdfService,
        scannerService: scanner,
      ),
    );

    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();

    // Verify Brand title in AppBar
    expect(find.text('Doxivo'), findsOneWidget);

    // Verify Primary CTAs in QuickActionBar
    expect(find.text('Scan Documents'), findsOneWidget);
    expect(find.text('Import Images to PDF'), findsOneWidget);

    // Verify Search and Filters
    expect(find.text('Search documents...'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);

    // Verify Initial Empty State
    expect(find.text('No Documents Yet'), findsOneWidget);
    expect(find.text('Scan First Document'), findsOneWidget);

    await tester.runAsync(() async {
      await db.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}

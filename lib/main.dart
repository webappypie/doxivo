import 'package:flutter/material.dart';
import 'core/database/app_database.dart';
import 'core/storage/file_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'domain/repositories/document_repository.dart';
import 'presentation/home/home_screen.dart';
import 'services/pdf_service.dart';
import 'services/scanner_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize local file storage
  final fileStorageService = FileStorageService();
  await fileStorageService.initialize();

  // Clean any stale temp files from prior interrupted sessions
  fileStorageService.cleanTempDirectory();

  // 2. Initialize local SQLite metadata database
  final appDatabase = AppDatabase();
  await appDatabase.initDatabase();

  final documentRepository = DocumentRepository(appDatabase: appDatabase);
  final pdfService = PdfService(fileStorageService: fileStorageService);
  final scannerService = ScannerService();

  runApp(
    DoxivoApp(
      fileStorageService: fileStorageService,
      documentRepository: documentRepository,
      pdfService: pdfService,
      scannerService: scannerService,
    ),
  );
}

class DoxivoApp extends StatelessWidget {
  final FileStorageService fileStorageService;
  final DocumentRepository documentRepository;
  final PdfService pdfService;
  final ScannerService scannerService;

  const DoxivoApp({
    super.key,
    required this.fileStorageService,
    required this.documentRepository,
    required this.pdfService,
    required this.scannerService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doxivo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: HomeScreen(
        fileStorageService: fileStorageService,
        documentRepository: documentRepository,
        pdfService: pdfService,
        scannerService: scannerService,
      ),
    );
  }
}

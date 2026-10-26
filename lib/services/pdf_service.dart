import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../core/storage/file_storage_service.dart';
import '../domain/models/document_model.dart';
import '../domain/models/scanned_page.dart';
import 'image_pipeline_service.dart';

class PdfService {
  final FileStorageService fileStorageService;

  PdfService({required this.fileStorageService});

  /// Assembles a multi-page PDF from a list of scanned pages and commits it to managed storage.
  Future<DocumentModel> createDocumentFromPages({
    required String title,
    required List<ScannedPage> pages,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    double margin = 16.0,
    String? watermarkText,
  }) async {
    if (pages.isEmpty) {
      throw ArgumentError('Cannot create a PDF document with zero pages');
    }

    final pdf = pw.Document();
    Uint8List? firstPageBytes;

    for (int i = 0; i < pages.length; i++) {
      final page = pages[i];
      final pageFile = File(page.currentPath);
      if (!await pageFile.exists()) {
        throw StateError('Page image not found: ${page.currentPath}');
      }
      final rawBytes = await pageFile.readAsBytes();
      if (i == 0) {
        firstPageBytes = rawBytes;
      }

      final image = pw.MemoryImage(rawBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.all(margin),
          build: (pw.Context context) {
            final content = pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );

            if (watermarkText != null && watermarkText.isNotEmpty) {
              return pw.Stack(
                alignment: pw.Alignment.center,
                children: [
                  content,
                  pw.Transform.rotate(
                    angle: -0.5,
                    child: pw.Opacity(
                      opacity: 0.25,
                      child: pw.Text(
                        watermarkText,
                        style: pw.TextStyle(
                          color: PdfColors.grey700,
                          fontSize: 48,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return content;
          },
        ),
      );
    }

    final pdfBytes = await pdf.save();

    // Verify valid PDF header
    if (pdfBytes.length < 5 || String.fromCharCodes(pdfBytes.sublist(0, 5)) != '%PDF-') {
      throw StateError('Generated PDF output is corrupt or missing magic header');
    }

    final docId = 'doc_${DateTime.now().millisecondsSinceEpoch}';
    final savedPdfFile = await fileStorageService.saveManagedPdf(title, pdfBytes);

    String? thumbnailPath;
    if (firstPageBytes != null) {
      try {
        final thumbBytes = ImagePipelineService.generateThumbnail(firstPageBytes);
        final thumbFile = await fileStorageService.saveThumbnail(docId, thumbBytes);
        thumbnailPath = thumbFile.path;
      } catch (_) {
        // Thumbnail generation is non-fatal
      }
    }

    final now = DateTime.now();
    return DocumentModel(
      id: docId,
      title: title,
      filePath: savedPdfFile.path,
      thumbnailPath: thumbnailPath,
      pageCount: pages.length,
      byteSize: pdfBytes.length,
      createdAt: now,
      updatedAt: now,
    );
  }
}

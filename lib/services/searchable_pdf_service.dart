import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../core/storage/file_storage_service.dart';
import '../domain/models/ocr_language.dart';
import '../domain/models/ocr_result.dart';
import 'ocr_service.dart';
import 'pdf_toolkit_service.dart';

class SearchablePdfService {
  final FileStorageService fileStorageService;

  SearchablePdfService({required this.fileStorageService});

  /// Generates a searchable PDF document from a list of page image paths and their OCR results.
  Future<File> generateSearchablePdfFromImages({
    required List<String> imagePaths,
    required List<OcrResult> ocrResults,
    String? outputPdfPath,
  }) async {
    if (imagePaths.isEmpty) {
      throw ArgumentError('imagePaths cannot be empty');
    }

    final pdf = pw.Document(
      title: 'Searchable PDF',
      author: 'Doxivo',
      creator: 'Doxivo On-Device OCR',
    );

    for (int i = 0; i < imagePaths.length; i++) {
      final imgPath = imagePaths[i];
      final imgFile = File(imgPath);
      if (!await imgFile.exists()) {
        continue;
      }

      final imageBytes = await imgFile.readAsBytes();
      final pageImage = pw.MemoryImage(imageBytes);

      final ocrResult = (i < ocrResults.length) ? ocrResults[i] : null;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            final pageW = PdfPageFormat.a4.width;
            final pageH = PdfPageFormat.a4.height;

            final children = <pw.Widget>[
              // Visual layer: the original scanned page image
              pw.Positioned.fill(
                child: pw.Image(
                  pageImage,
                  fit: pw.BoxFit.fill,
                ),
              ),
            ];

            // Invisible text layer for searchability and text selection
            if (ocrResult != null && ocrResult.hasText) {
              final scaleX = ocrResult.imageWidth > 0 ? (pageW / ocrResult.imageWidth) : 1.0;
              final scaleY = ocrResult.imageHeight > 0 ? (pageH / ocrResult.imageHeight) : 1.0;

              if (ocrResult.lines.isNotEmpty) {
                for (final line in ocrResult.lines) {
                  final box = line.boundingBox;
                  if (box != null && box.width > 0 && box.height > 0) {
                    final left = (box.left * scaleX).clamp(0.0, pageW - 20.0);
                    final top = (box.top * scaleY).clamp(0.0, pageH - 20.0);
                    final fSize = (box.height * scaleY * 0.8).clamp(8.0, 36.0);

                    children.add(
                      pw.Positioned(
                        left: left,
                        top: top,
                        child: pw.Text(
                          line.text,
                          style: pw.TextStyle(
                            color: const PdfColor(0, 0, 0, 0), // Invisible / transparent text
                            fontSize: fSize,
                          ),
                        ),
                      ),
                    );
                  } else {
                    // Fallback line positioning if no bounding box
                    children.add(
                      pw.Positioned(
                        left: 20,
                        top: 20 + (ocrResult.lines.indexOf(line) * 20.0).clamp(0.0, pageH - 40.0),
                        child: pw.Text(
                          line.text,
                          style: const pw.TextStyle(
                            color: PdfColor(0, 0, 0, 0),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }
                }
              } else {
                // If only fullText is available without line breakdown
                final lines = ocrResult.fullText.split('\n');
                for (int lineIdx = 0; lineIdx < lines.length; lineIdx++) {
                  final textLine = lines[lineIdx].trim();
                  if (textLine.isNotEmpty) {
                    children.add(
                      pw.Positioned(
                        left: 20,
                        top: 20 + (lineIdx * 20.0).clamp(0.0, pageH - 40.0),
                        child: pw.Text(
                          textLine,
                          style: const pw.TextStyle(
                            color: PdfColor(0, 0, 0, 0),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }
                }
              }
            }

            return pw.Stack(children: children);
          },
        ),
      );
    }

    final Uint8List pdfBytes = await pdf.save();
    final destPath = outputPdfPath ??
        fileStorageService.createTempFilePath(extension: 'pdf');

    return await fileStorageService.writeBytesAtomically(destPath, pdfBytes);
  }

  /// Converts an existing non-searchable PDF into a searchable PDF by rendering each page,
  /// executing on-device OCR, and embedding aligned invisible text layers.
  Future<File> makePdfSearchable(
    String inputPdfPath, {
    required PdfToolkitService pdfToolkitService,
    OcrLanguage language = OcrLanguage.english,
    String? outputPdfPath,
    void Function(int current, int total, String status)? onProgress,
  }) async {
    final pageCount = await pdfToolkitService.getPageCount(inputPdfPath);
    if (pageCount <= 0) {
      throw ArgumentError('Cannot process PDF with 0 pages at $inputPdfPath');
    }

    onProgress?.call(0, pageCount, 'Rendering document pages...');
    final tempDir = fileStorageService.tempDirectory;
    final pageImagePaths = await pdfToolkitService.renderPagesToImages(
      inputPath: inputPdfPath,
      outputDir: tempDir.path,
      format: 'png',
      dpi: 150,
    );

    final List<OcrResult> ocrResults = [];
    try {
      for (int i = 0; i < pageImagePaths.length; i++) {
        onProgress?.call(
          i + 1,
          pageImagePaths.length,
          'Recognizing page ${i + 1} of ${pageImagePaths.length} (${language.displayName})...',
        );
        final result = await OcrService.recognizeImage(
          pageImagePaths[i],
          language: language,
          pageIndex: i,
        );
        ocrResults.add(result);
      }

      onProgress?.call(pageCount, pageCount, 'Generating searchable PDF...');
      final searchableFile = await generateSearchablePdfFromImages(
        imagePaths: pageImagePaths,
        ocrResults: ocrResults,
        outputPdfPath: outputPdfPath,
      );

      return searchableFile;
    } finally {
      // Clean up temporary rendered images
      for (final p in pageImagePaths) {
        try {
          final f = File(p);
          if (await f.exists()) {
            await f.delete();
          }
        } catch (_) {}
      }
    }
  }
}

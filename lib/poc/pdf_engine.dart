import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfEngineService {
  static const MethodChannel _cryptoChannel = MethodChannel('com.webappypie.doxivo/pdf_crypto');

  /// Creates a multi-page PDF from a list of image bytes with optional watermarking.
  static Future<Uint8List> createPdfFromImages(
    List<Uint8List> imageBytesList, {
    String? watermarkText,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    double margin = 20.0,
  }) async {
    final pdf = pw.Document();

    for (final bytes in imageBytesList) {
      final image = pw.MemoryImage(bytes);

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

    return pdf.save();
  }

  /// Encrypts an existing PDF file with AES-256 standard security handler using the platform channel.
  static Future<String> encryptPdf({
    required String inputPath,
    required String outputPath,
    required String userPassword,
    String? ownerPassword,
    int keyLength = 256,
  }) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('PDFBox encryption channel is currently supported on Android.');
    }

    final result = await _cryptoChannel.invokeMethod<String>('encryptPdf', {
      'inputPath': inputPath,
      'outputPath': outputPath,
      'userPassword': userPassword,
      'ownerPassword': ownerPassword ?? userPassword,
      'keyLength': keyLength,
    });

    if (result == null) {
      throw StateError('Encryption returned null output path');
    }
    return result;
  }
}

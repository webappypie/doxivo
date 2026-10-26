import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:doxivo/poc/pdf_engine.dart';

void main() {
  test('Generate physical PoC PDF files for independent verification', () async {
    final outDir = Directory('build/poc_output');
    if (!outDir.existsSync()) {
      outDir.createSync(recursive: true);
    }

    final page1 = img.Image(width: 800, height: 1100);
    img.fill(page1, color: img.ColorRgb8(255, 255, 255));
    img.drawRect(page1, x1: 40, y1: 40, x2: 760, y2: 1060, color: img.ColorRgb8(30, 58, 138));
    img.fillRect(page1, x1: 60, y1: 60, x2: 740, y2: 160, color: img.ColorRgb8(30, 58, 138));
    final page1Bytes = Uint8List.fromList(img.encodeJpg(page1, quality: 90));

    final page2 = img.Image(width: 800, height: 1100);
    img.fill(page2, color: img.ColorRgb8(250, 250, 250));
    img.drawRect(page2, x1: 40, y1: 40, x2: 760, y2: 1060, color: img.ColorRgb8(16, 185, 129));
    final page2Bytes = Uint8List.fromList(img.encodeJpg(page2, quality: 90));

    // 1. Single page
    final pdf1 = await PdfEngineService.createPdfFromImages([page1Bytes]);
    final singlePageFile = File('${outDir.path}/single_page.pdf');
    singlePageFile.writeAsBytesSync(pdf1);
    expect(singlePageFile.existsSync(), isTrue);
    expect(singlePageFile.lengthSync(), greaterThan(1000));

    // 2. Watermarked
    final pdfWatermark = await PdfEngineService.createPdfFromImages(
      [page1Bytes],
      watermarkText: 'CONFIDENTIAL DOXIVO',
    );
    final watermarkFile = File('${outDir.path}/watermarked.pdf');
    watermarkFile.writeAsBytesSync(pdfWatermark);
    expect(watermarkFile.existsSync(), isTrue);
    expect(watermarkFile.lengthSync(), greaterThan(singlePageFile.lengthSync()));

    // 3. Multi page
    final pdfMulti = await PdfEngineService.createPdfFromImages([page1Bytes, page2Bytes]);
    final multiPageFile = File('${outDir.path}/multipage.pdf');
    multiPageFile.writeAsBytesSync(pdfMulti);
    expect(multiPageFile.existsSync(), isTrue);
    expect(multiPageFile.lengthSync(), greaterThan(singlePageFile.lengthSync()));
  });
}

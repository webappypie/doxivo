import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'poc/pdf_engine.dart';
import 'poc/image_pipeline.dart';
import 'poc/scanner_service.dart';
import 'poc/text_metrics.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DoxivoApp());
}

class DoxivoApp extends StatelessWidget {
  const DoxivoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doxivo Proof of Concept',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const PocHomeScreen(),
    );
  }
}

class PocHomeScreen extends StatefulWidget {
  const PocHomeScreen({super.key});

  @override
  State<PocHomeScreen> createState() => _PocHomeScreenState();
}

class _PocHomeScreenState extends State<PocHomeScreen> {
  String _statusLog = 'Ready. Select a proof-of-concept operation below.';
  Uint8List? _previewImageBytes;
  String? _ocrRecognizedText;
  bool _isProcessing = false;

  void _log(String message) {
    setState(() {
      _statusLog = message;
    });
  }

  /// Generates a synthetic test document image with geometric borders and text pattern.
  Uint8List _createSyntheticDocumentImage() {
    final docImage = img.Image(width: 600, height: 800);
    img.fill(docImage, color: img.ColorRgb8(250, 250, 250));

    // Outer border
    img.drawRect(
      docImage,
      x1: 20,
      y1: 20,
      x2: 580,
      y2: 780,
      color: img.ColorRgb8(30, 58, 138),
    );

    // Header bar
    img.fillRect(
      docImage,
      x1: 40,
      y1: 40,
      x2: 560,
      y2: 120,
      color: img.ColorRgb8(30, 58, 138),
    );

    // Simulated content lines
    for (int y = 160; y < 650; y += 40) {
      img.fillRect(
        docImage,
        x1: 50,
        y1: y,
        x2: 550,
        y2: y + 16,
        color: img.ColorRgb8(180, 180, 180),
      );
    }

    return Uint8List.fromList(img.encodeJpg(docImage, quality: 90));
  }

  Future<void> _testPdfCreation({bool withWatermark = false}) async {
    setState(() => _isProcessing = true);
    try {
      final sampleImage = _createSyntheticDocumentImage();
      final pdfBytes = await PdfEngineService.createPdfFromImages(
        [sampleImage],
        watermarkText: withWatermark ? 'DOXIVO VERIFIED' : null,
      );

      final magicHeader = String.fromCharCodes(pdfBytes.sublist(0, 5));
      _log('PDF generated successfully!\nSize: ${pdfBytes.length} bytes\nHeader: $magicHeader\nWatermark: ${withWatermark ? "Yes" : "None"}');
    } catch (e) {
      _log('PDF creation failed: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _testImageFilters(EnhancementFilter filter) async {
    setState(() => _isProcessing = true);
    try {
      final sample = _createSyntheticDocumentImage();
      final filtered = ImageProcessingPipeline.applyEnhancement(sample, filter);
      setState(() {
        _previewImageBytes = filtered;
      });
      _log('Applied ${filter.name} filter. Output size: ${filtered.length} bytes.');
    } catch (e) {
      _log('Filter failed: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _testPerspectiveCrop() async {
    setState(() => _isProcessing = true);
    try {
      final sample = _createSyntheticDocumentImage();
      final cropped = ImageProcessingPipeline.perspectiveCrop(
        sample,
        topLeft: const Point2D(40, 40),
        topRight: const Point2D(560, 60),
        bottomRight: const Point2D(550, 750),
        bottomLeft: const Point2D(50, 770),
        targetWidth: 400,
        targetHeight: 600,
      );
      setState(() {
        _previewImageBytes = cropped;
      });
      _log('Perspective warp & crop completed: 400x600 px.');
    } catch (e) {
      _log('Perspective crop failed: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _testScanner() async {
    setState(() => _isProcessing = true);
    try {
      _log('Launching native document scanner...');
      final scannedPaths = await ScannerService.scanDocuments(noOfPages: 3);
      if (scannedPaths == null || scannedPaths.isEmpty) {
        _log('Scan session cancelled by user or no pages captured.');
      } else {
        _log('Scan complete! Captured ${scannedPaths.length} pages:\n${scannedPaths.join('\n')}');
      }
    } catch (e) {
      _log('Scanner error (Check device camera / Play services): $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _testCerMetrics() async {
    const groundTruth = 'Doxivo Document Scanner Phase 00';
    const testOcrOutput = 'Doxivo Document Scaner Phase OO'; // 2 simulated character errors: 'n', 'OO'

    final distance = TextMetrics.levenshteinDistance(groundTruth, testOcrOutput);
    final cer = TextMetrics.calculateCer(groundTruth, testOcrOutput);

    setState(() {
      _ocrRecognizedText = 'Ground Truth: "$groundTruth"\nHypothesis:   "$testOcrOutput"';
    });

    _log('CER Evaluation:\nEdit Distance: $distance\nCER: ${(cer * 100).toStringAsFixed(2)}% (Formula: (S+D+I)/N)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doxivo — Phase 00 PoC'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Privacy & Architecture Card
            Card(
              elevation: 2,
              color: const Color(0xFFF0FDF4),
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield_outlined, color: Color(0xFF16A34A)),
                        SizedBox(width: 8),
                        Text(
                          'Privacy Boundary: Local-First',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      '• Application ID: com.webappypie.doxivo (Android)\n'
                      '• Bundle ID: com.webappypie.doxivo.ios (iOS)\n'
                      '• Core scanning, image processing, OCR & PDF creation are 100% on-device.\n'
                      '• No document content or metadata is uploaded to any remote server.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF14532D)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Status Card
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Diagnostic Log / Execution Output:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        _statusLog,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Section: PDF Engine Proof of Concept
            const Text(
              '1. PDF Engine PoC (Creation & Watermark)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : () => _testPdfCreation(withWatermark: false),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Create PDF'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : () => _testPdfCreation(withWatermark: true),
                    icon: const Icon(Icons.branding_watermark),
                    label: const Text('Watermark PDF'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section: Image Pipeline & Filters
            const Text(
              '2. Document Image Pipeline',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Grayscale'),
                  onPressed: _isProcessing ? null : () => _testImageFilters(EnhancementFilter.grayscale),
                ),
                ActionChip(
                  label: const Text('Black & White'),
                  onPressed: _isProcessing ? null : () => _testImageFilters(EnhancementFilter.blackAndWhite),
                ),
                ActionChip(
                  label: const Text('Enhanced Color'),
                  onPressed: _isProcessing ? null : () => _testImageFilters(EnhancementFilter.enhancedColor),
                ),
                ActionChip(
                  label: const Text('Perspective Crop'),
                  onPressed: _isProcessing ? null : _testPerspectiveCrop,
                ),
              ],
            ),
            if (_previewImageBytes != null) ...[
              const SizedBox(height: 10),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Image.memory(
                    _previewImageBytes!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Section: Native Scanner
            const Text(
              '3. Native Document Scanner',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _testScanner,
              icon: const Icon(Icons.document_scanner),
              label: const Text('Launch Document Scanner (Play Services / VisionKit)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Section: OCR & CER Evaluation
            const Text(
              '4. Offline OCR & CER Evaluation',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _testCerMetrics,
              icon: const Icon(Icons.spellcheck),
              label: const Text('Run Levenshtein CER Metric Test'),
            ),
            if (_ocrRecognizedText != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border.all(color: Colors.amber.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _ocrRecognizedText!,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

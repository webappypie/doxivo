import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/storage/file_storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/document_model.dart';
import '../../domain/models/signature_config.dart';
import '../../domain/repositories/document_repository.dart';
import '../../services/pdf_toolkit_service.dart';
import '../common/doxivo_button.dart';
import '../common/processing_dialog.dart';
import '../viewer/pdf_viewer_screen.dart';
import 'signature/signature_pad_widget.dart';

class SignatureScreen extends StatefulWidget {
  final DocumentModel document;
  final PdfToolkitService pdfToolkitService;
  final FileStorageService fileStorageService;
  final DocumentRepository documentRepository;

  const SignatureScreen({
    super.key,
    required this.document,
    required this.pdfToolkitService,
    required this.fileStorageService,
    required this.documentRepository,
  });

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  final GlobalKey<SignaturePadWidgetState> _padKey = GlobalKey<SignaturePadWidgetState>();
  int _targetPage = 0;
  int _totalPages = 1;
  double _posX = 150.0;
  double _posY = 100.0;
  final double _sigWidth = 140.0;
  final double _sigHeight = 70.0;
  bool _signatureCaptured = false;
  File? _tempSignatureImage;

  @override
  void initState() {
    super.initState();
    _totalPages = widget.document.pageCount;
    _checkPageCount();
  }

  Future<void> _checkPageCount() async {
    try {
      final count = await widget.pdfToolkitService.getPageCount(widget.document.filePath);
      if (mounted) setState(() => _totalPages = count);
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_tempSignatureImage != null && _tempSignatureImage!.existsSync()) {
      _tempSignatureImage!.deleteSync();
    }
    super.dispose();
  }

  Future<void> _captureSignature() async {
    final bytes = await _padKey.currentState?.exportPngBytes();
    if (bytes == null || bytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please draw your signature first')),
        );
      }
      return;
    }

    final tempFile = widget.fileStorageService.createTempFile(extension: 'png');
    await tempFile.writeAsBytes(bytes);
    setState(() {
      _tempSignatureImage = tempFile;
      _signatureCaptured = true;
    });
  }

  Future<void> _applySignature() async {
    if (_tempSignatureImage == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const ProcessingDialog(message: 'Placing signature on PDF...'),
    );

    try {
      final tempOutputFile = widget.fileStorageService.createTempFile(extension: 'pdf');
      final config = SignatureConfig(
        signatureImagePath: _tempSignatureImage!.path,
        pageIndex: _targetPage,
        x: _posX,
        y: _posY,
        width: _sigWidth,
        height: _sigHeight,
      );

      await widget.pdfToolkitService.addSignature(
        inputPath: widget.document.filePath,
        outputPath: tempOutputFile.path,
        config: config,
      );

      final newTitle = '${widget.document.title} (Signed)';
      final bytes = await tempOutputFile.readAsBytes();
      final savedDoc = await widget.fileStorageService.saveManagedPdf(newTitle, bytes);

      final now = DateTime.now();
      final newDoc = DocumentModel(
        id: 'doc_${now.millisecondsSinceEpoch}',
        title: newTitle,
        filePath: savedDoc.path,
        thumbnailPath: widget.document.thumbnailPath,
        pageCount: widget.document.pageCount,
        byteSize: bytes.length,
        createdAt: now,
        updatedAt: now,
      );

      await widget.documentRepository.insertDocument(newDoc);

      if (tempOutputFile.existsSync()) {
        tempOutputFile.deleteSync();
      }

      if (mounted) {
        Navigator.of(context).pop(); // dismiss dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document signed successfully!')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => PdfViewerScreen(
              document: newDoc,
              documentRepository: widget.documentRepository,
              pdfToolkitService: widget.pdfToolkitService,
              fileStorageService: widget.fileStorageService,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign document: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign PDF'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_signatureCaptured) ...[
                Text('Draw Your Signature', style: AppTypography.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Sign below using your finger or stylus, then tap "Place Signature".',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 16),
                SignaturePadWidget(key: _padKey),
                const SizedBox(height: 20),
                DoxivoButton(
                  label: 'Confirm Signature & Place on Page',
                  icon: Icons.draw,
                  onPressed: _captureSignature,
                ),
              ] else ...[
                // Placement Configuration
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Place on Page', style: AppTypography.titleMedium),
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Re-draw'),
                      onPressed: () => setState(() => _signatureCaptured = false),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Target page selector
                Row(
                  children: [
                    const Text('Target Page: '),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: _targetPage,
                      items: List.generate(_totalPages, (i) {
                        return DropdownMenuItem(
                          value: i,
                          child: Text('Page ${i + 1} of $_totalPages'),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) setState(() => _targetPage = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Interactive Document Placement Canvas
                Container(
                  height: 260,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Document background hints
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Document Page ${_targetPage + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              height: 1,
                              width: 160,
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Authorized Signature',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Draggable Signature Stamp
                      Positioned(
                        left: _posX,
                        top: _posY,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              _posX = (_posX + details.delta.dx).clamp(10.0, 200.0);
                              _posY = (_posY + details.delta.dy).clamp(10.0, 180.0);
                            });
                          },
                          child: Container(
                            width: _sigWidth,
                            height: _sigHeight,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.primaryLight, width: 1.5),
                              color: AppColors.primaryLight.withAlpha(20),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (_tempSignatureImage != null && _tempSignatureImage!.existsSync())
                                  Image.file(_tempSignatureImage!, fit: BoxFit.contain),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryLight,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.open_with, size: 10, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Drag the signature box to position it anywhere on the page.',
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                DoxivoButton(
                  label: 'Stamp Signature & Save PDF',
                  icon: Icons.check,
                  onPressed: _applySignature,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

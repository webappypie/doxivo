import 'package:flutter/material.dart';
import '../../core/storage/file_storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/document_model.dart';
import '../../domain/models/watermark_config.dart';
import '../../domain/repositories/document_repository.dart';
import '../../services/pdf_toolkit_service.dart';
import '../common/doxivo_button.dart';
import '../common/processing_dialog.dart';
import '../viewer/pdf_viewer_screen.dart';

class WatermarkScreen extends StatefulWidget {
  final DocumentModel document;
  final PdfToolkitService pdfToolkitService;
  final FileStorageService fileStorageService;
  final DocumentRepository documentRepository;

  const WatermarkScreen({
    super.key,
    required this.document,
    required this.pdfToolkitService,
    required this.fileStorageService,
    required this.documentRepository,
  });

  @override
  State<WatermarkScreen> createState() => _WatermarkScreenState();
}

class _WatermarkScreenState extends State<WatermarkScreen> {
  final TextEditingController _textController = TextEditingController(text: 'CONFIDENTIAL');
  double _opacity = 0.25;
  double _fontSize = 42.0;
  double _rotation = 45.0;

  final List<String> _presets = ['CONFIDENTIAL', 'DRAFT', 'DO NOT COPY', 'SAMPLE', 'APPROVED'];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _applyWatermark() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter watermark text')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const ProcessingDialog(message: 'Applying watermark to all pages...'),
    );

    try {
      final config = WatermarkConfig(
        text: text,
        fontSize: _fontSize,
        opacity: _opacity,
        rotationDegrees: _rotation,
      );

      final tempOutputFile = widget.fileStorageService.createTempFile(extension: 'pdf');
      await widget.pdfToolkitService.addWatermark(
        inputPath: widget.document.filePath,
        outputPath: tempOutputFile.path,
        config: config,
      );

      final newTitle = '${widget.document.title} (Watermarked)';
      final bytes = await tempOutputFile.readAsBytes();
      final savedDoc = await widget.fileStorageService.saveManagedPdf(newTitle, bytes);

      // Create new document entry
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
        // Replace with viewer showing the watermarked PDF
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
        Navigator.of(context).pop(); // dismiss dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply watermark: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Watermark'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Visual Preview Box
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Mock Document Lines in Background
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(height: 12, width: 140, color: Colors.grey.withAlpha(50)),
                          const SizedBox(height: 12),
                          Container(height: 8, width: double.infinity, color: Colors.grey.withAlpha(30)),
                          const SizedBox(height: 8),
                          Container(height: 8, width: double.infinity, color: Colors.grey.withAlpha(30)),
                          const SizedBox(height: 8),
                          Container(height: 8, width: 200, color: Colors.grey.withAlpha(30)),
                        ],
                      ),
                    ),

                    // Rotating Watermark Text
                    Transform.rotate(
                      angle: -_rotation * 3.14159 / 180,
                      child: Opacity(
                        opacity: _opacity,
                        child: Text(
                          _textController.text.isEmpty ? 'WATERMARK' : _textController.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: _fontSize * 0.7, // scaled for preview
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Presets
              Text('Quick Presets', style: AppTypography.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presets.map((preset) {
                  final isSelected = _textController.text == preset;
                  return ChoiceChip(
                    label: Text(preset),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _textController.text = preset);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Custom Text Input
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Watermark Text',
                  hintText: 'Enter custom watermark text',
                  prefixIcon: Icon(Icons.edit_note),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Opacity Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Opacity: ${(_opacity * 100).toInt()}%', style: AppTypography.bodyMedium),
                  Text('${(_opacity * 100).toInt()}%', style: AppTypography.bodySmall),
                ],
              ),
              Slider(
                value: _opacity,
                min: 0.1,
                max: 0.8,
                divisions: 14,
                onChanged: (val) => setState(() => _opacity = val),
              ),

              // Font Size Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Font Size: ${_fontSize.toInt()} pt', style: AppTypography.bodyMedium),
                  Text('${_fontSize.toInt()}', style: AppTypography.bodySmall),
                ],
              ),
              Slider(
                value: _fontSize,
                min: 24,
                max: 72,
                divisions: 16,
                onChanged: (val) => setState(() => _fontSize = val),
              ),

              // Rotation Angle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Rotation Angle: ${_rotation.toInt()}°', style: AppTypography.bodyMedium),
                  Text('${_rotation.toInt()}°', style: AppTypography.bodySmall),
                ],
              ),
              Slider(
                value: _rotation,
                min: 0,
                max: 90,
                divisions: 6,
                onChanged: (val) => setState(() => _rotation = val),
              ),

              const SizedBox(height: 24),
              DoxivoButton(
                label: 'Apply Watermark to PDF',
                icon: Icons.check,
                onPressed: _applyWatermark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/storage/file_storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/compression_preset.dart';
import '../../domain/models/document_model.dart';
import '../../domain/models/pdf_operation_result.dart';
import '../../domain/repositories/document_repository.dart';
import '../../services/pdf_toolkit_service.dart';
import '../common/doxivo_button.dart';
import '../common/processing_dialog.dart';
import '../viewer/pdf_viewer_screen.dart';

class CompressScreen extends StatefulWidget {
  final DocumentModel document;
  final PdfToolkitService pdfToolkitService;
  final FileStorageService fileStorageService;
  final DocumentRepository documentRepository;

  const CompressScreen({
    super.key,
    required this.document,
    required this.pdfToolkitService,
    required this.fileStorageService,
    required this.documentRepository,
  });

  @override
  State<CompressScreen> createState() => _CompressScreenState();
}

class _CompressScreenState extends State<CompressScreen> {
  CompressionPreset _selectedPreset = CompressionPreset.medium;

  Future<void> _compressPdf() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const ProcessingDialog(message: 'Optimizing and compressing PDF...'),
    );

    try {
      final tempOutputFile = widget.fileStorageService.createTempFile(extension: 'pdf');
      final result = await widget.pdfToolkitService.compressPdf(
        inputPath: widget.document.filePath,
        outputPath: tempOutputFile.path,
        preset: _selectedPreset,
      );

      if (!result.isSuccess) {
        throw StateError(result.errorMessage ?? 'Compression failed');
      }

      final newTitle = '${widget.document.title} (Compressed)';
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
        _showSuccessDialog(newDoc, result);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Compression failed: $e')),
        );
      }
    }
  }

  void _showSuccessDialog(DocumentModel newDoc, PdfOperationResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 8),
            Text('Compression Complete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Original size: ${_formatBytes(result.beforeBytes)}'),
            Text('New size: ${_formatBytes(result.afterBytes)}'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Reduced by ${result.reductionPercentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
          ),
          FilledButton(
            child: const Text('Open Document'),
            onPressed: () {
              Navigator.of(ctx).pop();
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
            },
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compress PDF'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Current File Stats Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.picture_as_pdf, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.document.title,
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Current size: ${widget.document.formattedSize} • ${widget.document.pageCount} pages',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text('Select Compression Level', style: AppTypography.titleMedium),
              const SizedBox(height: 12),

              // Preset options
              ...CompressionPreset.all.map((preset) {
                final isSelected = _selectedPreset.level == preset.level;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withAlpha(15) : (isDark ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _selectedPreset = preset),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isSelected ? AppColors.primary : Colors.grey,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  preset.title,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppColors.primary : null,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(preset.description, style: AppTypography.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),
              DoxivoButton(
                label: 'Compress PDF',
                icon: Icons.compress,
                onPressed: _compressPdf,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

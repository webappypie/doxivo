import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/storage/file_storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/document_model.dart';
import '../../services/pdf_toolkit_service.dart';
import '../common/doxivo_button.dart';
import '../common/processing_dialog.dart';

class ExportImagesScreen extends StatefulWidget {
  final DocumentModel document;
  final PdfToolkitService pdfToolkitService;
  final FileStorageService fileStorageService;

  const ExportImagesScreen({
    super.key,
    required this.document,
    required this.pdfToolkitService,
    required this.fileStorageService,
  });

  @override
  State<ExportImagesScreen> createState() => _ExportImagesScreenState();
}

class _ExportImagesScreenState extends State<ExportImagesScreen> {
  String _format = 'jpg';
  int _dpi = 150;
  int _totalPages = 1;
  late final Set<int> _selectedPages;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _totalPages = widget.document.pageCount;
    _selectedPages = Set<int>.from(List.generate(_totalPages, (i) => i));
    _checkPageCount();
  }

  Future<void> _checkPageCount() async {
    try {
      final count = await widget.pdfToolkitService.getPageCount(widget.document.filePath);
      if (mounted) {
        setState(() {
          _totalPages = count;
          _selectedPages.clear();
          _selectedPages.addAll(List.generate(_totalPages, (i) => i));
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportImages() async {
    if (_selectedPages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 1 page to export')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const ProcessingDialog(message: 'Rendering PDF pages to images...'),
    );

    try {
      final exportDir = Directory('${widget.fileStorageService.tempDirectory.path}/export_${DateTime.now().millisecondsSinceEpoch}');
      await exportDir.create(recursive: true);

      final sortedIndices = _selectedPages.toList()..sort();
      final renderedPaths = await widget.pdfToolkitService.renderPagesToImages(
        inputPath: widget.document.filePath,
        outputDir: exportDir.path,
        pageIndices: sortedIndices,
        dpi: _dpi,
        format: _format,
      );

      if (mounted) {
        Navigator.of(context).pop(); // dismiss dialog

        if (renderedPaths.isNotEmpty) {
          final xFiles = renderedPaths.map((p) => XFile(p)).toList();
          await SharePlus.instance.share(
            ShareParams(
              files: xFiles,
              subject: '${widget.document.title} - Exported Images',
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No images were generated')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export images: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Pages as Images'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Format selector
                    Text('Image Format', style: AppTypography.titleMedium),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'jpg', label: Text('JPEG (Compact)')),
                        ButtonSegment(value: 'png', label: Text('PNG (Lossless)')),
                      ],
                      selected: {_format},
                      onSelectionChanged: (val) => setState(() => _format = val.first),
                    ),
                    const SizedBox(height: 20),

                    // Resolution selector
                    Text('Resolution', style: AppTypography.titleMedium),
                    const SizedBox(height: 8),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 150, label: Text('Standard (150 DPI)')),
                        ButtonSegment(value: 300, label: Text('High Print (300 DPI)')),
                      ],
                      selected: {_dpi},
                      onSelectionChanged: (val) => setState(() => _dpi = val.first),
                    ),
                    const SizedBox(height: 24),

                    // Pages Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Select Pages (${_selectedPages.length}/$_totalPages)', style: AppTypography.titleMedium),
                        TextButton(
                          child: Text(_selectedPages.length == _totalPages ? 'Deselect All' : 'Select All'),
                          onPressed: () {
                            setState(() {
                              if (_selectedPages.length == _totalPages) {
                                _selectedPages.clear();
                              } else {
                                _selectedPages.addAll(List.generate(_totalPages, (i) => i));
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Page Checkboxes Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _totalPages,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedPages.contains(index);
                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedPages.remove(index);
                              } else {
                                _selectedPages.add(index);
                              }
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withAlpha(20) : Colors.grey.withAlpha(15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : Colors.grey.withAlpha(50),
                                width: isSelected ? 2.0 : 1.0,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image,
                                  size: 32,
                                  color: isSelected ? AppColors.primary : Colors.grey,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Page ${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? AppColors.primary : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 28),

                    DoxivoButton(
                      label: 'Export ${_selectedPages.length} Images',
                      icon: Icons.share,
                      onPressed: _exportImages,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

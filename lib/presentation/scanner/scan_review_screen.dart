import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/storage/file_storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/scanned_page.dart';
import '../../domain/repositories/document_repository.dart';
import '../../services/pdf_service.dart';
import '../../services/scanner_service.dart';
import '../common/processing_dialog.dart';
import 'crop_enhancement_screen.dart';

class ScanReviewScreen extends StatefulWidget {
  final List<String> initialImagePaths;
  final FileStorageService fileStorageService;
  final DocumentRepository documentRepository;
  final PdfService pdfService;
  final ScannerService scannerService;

  const ScanReviewScreen({
    super.key,
    required this.initialImagePaths,
    required this.fileStorageService,
    required this.documentRepository,
    required this.pdfService,
    required this.scannerService,
  });

  @override
  State<ScanReviewScreen> createState() => _ScanReviewScreenState();
}

class _ScanReviewScreenState extends State<ScanReviewScreen> {
  final List<ScannedPage> _pages = [];
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.initialImagePaths.length; i++) {
      final path = widget.initialImagePaths[i];
      _pages.add(
        ScannedPage(
          id: 'page_${DateTime.now().microsecondsSinceEpoch}_$i',
          originalPath: path,
          currentPath: path,
        ),
      );
    }
  }

  void _rotateCurrentPage() {
    if (_pages.isEmpty) return;
    final page = _pages[_currentPageIndex];
    setState(() {
      page.rotation = (page.rotation + 90) % 360;
    });
  }

  void _deleteCurrentPage() {
    if (_pages.isEmpty) return;
    setState(() {
      _pages.removeAt(_currentPageIndex);
      if (_currentPageIndex >= _pages.length) {
        _currentPageIndex = (_pages.length - 1).clamp(0, 9999);
      }
    });

    if (_pages.isEmpty) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _openCropEditor() async {
    if (_pages.isEmpty) return;
    final page = _pages[_currentPageIndex];
    final updated = await Navigator.of(context).push<ScannedPage>(
      MaterialPageRoute(
        builder: (ctx) => CropEnhancementScreen(
          page: page,
          fileStorageService: widget.fileStorageService,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        _pages[_currentPageIndex] = updated;
      });
    }
  }

  Future<void> _addMorePages() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.document_scanner, color: AppColors.primary),
                title: const Text('Scan with Camera'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final newPaths = await widget.scannerService.scanWithDocumentScanner(maxPages: 10);
                  if (newPaths != null && newPaths.isNotEmpty && mounted) {
                    setState(() {
                      for (final p in newPaths) {
                        _pages.add(
                          ScannedPage(
                            id: 'page_${DateTime.now().microsecondsSinceEpoch}',
                            originalPath: p,
                            currentPath: p,
                          ),
                        );
                      }
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.secondary),
                title: const Text('Import from Photos'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final newPaths = await widget.scannerService.pickImagesFromGallery();
                  if (newPaths != null && newPaths.isNotEmpty && mounted) {
                    setState(() {
                      for (final p in newPaths) {
                        _pages.add(
                          ScannedPage(
                            id: 'page_${DateTime.now().microsecondsSinceEpoch}',
                            originalPath: p,
                            currentPath: p,
                          ),
                        );
                      }
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveAsPdf() async {
    if (_pages.isEmpty) return;

    final now = DateTime.now();
    final defaultTitle = 'Scan_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final titleController = TextEditingController(text: defaultTitle);

    final confirmedTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save PDF Document'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Document Name',
            hintText: 'Enter document name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = titleController.text.trim();
              Navigator.of(ctx).pop(val.isNotEmpty ? val : defaultTitle);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmedTitle == null || !mounted) return;

    ProcessingDialog.show(context, message: 'Assembling and saving PDF...');

    try {
      final doc = await widget.pdfService.createDocumentFromPages(
        title: confirmedTitle,
        pages: _pages,
      );

      await widget.documentRepository.insertDocument(doc);

      if (mounted) {
        ProcessingDialog.hide(context);
        Navigator.of(context).pop(doc);
      }
    } catch (e) {
      if (mounted) {
        ProcessingDialog.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pages.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No pages scanned')),
      );
    }

    final currentPage = _pages[_currentPageIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark preview canvas
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: Text(
          'Page ${_currentPageIndex + 1} of ${_pages.length}',
          style: AppTypography.titleMedium.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.crop),
            tooltip: 'Adjust Crop / Filter',
            onPressed: _openCropEditor,
          ),
          IconButton(
            icon: const Icon(Icons.rotate_right),
            tooltip: 'Rotate',
            onPressed: _rotateCurrentPage,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            tooltip: 'Delete Page',
            onPressed: _deleteCurrentPage,
          ),
        ],
      ),
      body: Column(
        children: [
          // Main Preview of Current Page
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: RotatedBox(
                  quarterTurns: currentPage.rotation ~/ 90,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(currentPage.currentPath),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Thumbnail Strip & Save Bar
          Container(
            color: const Color(0xFF1E293B),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Horizontal Thumbnail Rail
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _pages.length + 1,
                      separatorBuilder: (context, index) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        if (index == _pages.length) {
                          // Add Page Button
                          return Center(
                            child: InkWell(
                              onTap: _addMorePages,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 56,
                                height: 74,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white30, width: 1.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.add, color: Colors.white, size: 28),
                              ),
                            ),
                          );
                        }

                        final page = _pages[index];
                        final isSelected = index == _currentPageIndex;

                        return GestureDetector(
                          onTap: () {
                            setState(() => _currentPageIndex = index);
                          },
                          child: Container(
                            width: 56,
                            height: 74,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? AppColors.primaryLight : Colors.transparent,
                                width: 2.5,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: RotatedBox(
                                quarterTurns: page.rotation ~/ 90,
                                child: Image.file(
                                  File(page.currentPath),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bottom Action Bar
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _addMorePages,
                          icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
                          label: const Text('Add Page', style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white30),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _saveAsPdf,
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: Text(
                            'Save PDF (${_pages.length} ${_pages.length == 1 ? "page" : "pages"})',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryLight,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

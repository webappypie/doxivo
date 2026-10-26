import 'package:flutter/material.dart';
import '../../core/storage/file_storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/document_model.dart';
import '../../domain/models/pdf_page_item.dart';
import '../../domain/repositories/document_repository.dart';
import '../../services/pdf_toolkit_service.dart';
import '../common/doxivo_button.dart';
import '../common/processing_dialog.dart';
import '../viewer/pdf_viewer_screen.dart';

class OrganizePagesScreen extends StatefulWidget {
  final DocumentModel document;
  final PdfToolkitService pdfToolkitService;
  final FileStorageService fileStorageService;
  final DocumentRepository documentRepository;

  const OrganizePagesScreen({
    super.key,
    required this.document,
    required this.pdfToolkitService,
    required this.fileStorageService,
    required this.documentRepository,
  });

  @override
  State<OrganizePagesScreen> createState() => _OrganizePagesScreenState();
}

class _OrganizePagesScreenState extends State<OrganizePagesScreen> {
  final List<PdfPageItem> _pages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initPages();
  }

  Future<void> _initPages() async {
    try {
      final count = await widget.pdfToolkitService.getPageCount(widget.document.filePath);
      for (int i = 0; i < count; i++) {
        _pages.add(PdfPageItem(pageIndex: i));
      }
    } catch (_) {
      for (int i = 0; i < widget.document.pageCount; i++) {
        _pages.add(PdfPageItem(pageIndex: i));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _rotatePage(int listIndex) {
    setState(() {
      final item = _pages[listIndex];
      final newRot = (item.rotationDegrees + 90) % 360;
      _pages[listIndex] = item.copyWith(rotationDegrees: newRot);
    });
  }

  void _deletePage(int listIndex) {
    if (_pages.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A document must have at least one page')),
      );
      return;
    }
    setState(() {
      _pages.removeAt(listIndex);
    });
  }

  Future<void> _saveOrganizedPdf() async {
    if (_pages.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const ProcessingDialog(message: 'Saving updated document...'),
    );

    try {
      final tempOutputFile = widget.fileStorageService.createTempFile(extension: 'pdf');
      final pageIndices = _pages.map((p) => p.pageIndex).toList();
      final rotations = _pages.map((p) => p.rotationDegrees).toList();

      await widget.pdfToolkitService.reorderAndRotatePages(
        inputPath: widget.document.filePath,
        outputPath: tempOutputFile.path,
        pageIndices: pageIndices,
        rotations: rotations,
      );

      final newTitle = '${widget.document.title} (Organized)';
      final bytes = await tempOutputFile.readAsBytes();
      final savedDoc = await widget.fileStorageService.saveManagedPdf(newTitle, bytes);

      final now = DateTime.now();
      final newDoc = DocumentModel(
        id: 'doc_${now.millisecondsSinceEpoch}',
        title: newTitle,
        filePath: savedDoc.path,
        thumbnailPath: widget.document.thumbnailPath,
        pageCount: _pages.length,
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
          const SnackBar(content: Text('Organized PDF saved successfully!')),
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
          SnackBar(content: Text('Failed to save organized PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organize & Rotate Pages'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Drag items to reorder pages. Tap rotate or delete as needed.',
                      style: AppTypography.bodySmall,
                    ),
                  ),

                  // Reorderable list of pages
                  Expanded(
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _pages.length,
                      onReorderItem: (oldIndex, newIndex) {
                        setState(() {
                          final item = _pages.removeAt(oldIndex);
                          _pages.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final page = _pages[index];
                        return Card(
                          key: ValueKey('page_${page.pageIndex}_$index'),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                // Page badge with rotation angle
                                Container(
                                  width: 50,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.primary.withAlpha(40)),
                                  ),
                                  child: RotatedBox(
                                    quarterTurns: (page.rotationDegrees ~/ 90),
                                    child: const Center(
                                      child: Icon(Icons.description, color: AppColors.primary),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Page metadata
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Page ${index + 1} (Original #${page.pageIndex + 1})',
                                        style: AppTypography.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        page.rotationDegrees == 0
                                            ? 'Standard orientation'
                                            : 'Rotated ${page.rotationDegrees}°',
                                        style: AppTypography.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),

                                // Actions: Rotate, Delete, Drag
                                IconButton(
                                  icon: const Icon(Icons.rotate_right),
                                  tooltip: 'Rotate 90°',
                                  onPressed: () => _rotatePage(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: 'Delete page',
                                  onPressed: () => _deletePage(index),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.drag_handle, color: Colors.grey),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom Save CTA
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DoxivoButton(
                      label: 'Save Changes (${_pages.length} Pages)',
                      icon: Icons.check,
                      onPressed: _saveOrganizedPdf,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

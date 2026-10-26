import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/storage/file_storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/document_model.dart';
import '../../domain/repositories/document_repository.dart';
import '../../services/pdf_toolkit_service.dart';
import '../common/doxivo_button.dart';
import '../common/processing_dialog.dart';

enum SplitMode {
  allSinglePages,
  selectedPages,
}

class SplitScreen extends StatefulWidget {
  final DocumentModel document;
  final PdfToolkitService pdfToolkitService;
  final FileStorageService fileStorageService;
  final DocumentRepository documentRepository;

  const SplitScreen({
    super.key,
    required this.document,
    required this.pdfToolkitService,
    required this.fileStorageService,
    required this.documentRepository,
  });

  @override
  State<SplitScreen> createState() => _SplitScreenState();
}

class _SplitScreenState extends State<SplitScreen> {
  SplitMode _splitMode = SplitMode.allSinglePages;
  late final Set<int> _selectedPages;
  int _totalPages = 1;
  bool _loadingPages = true;

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
          _loadingPages = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingPages = false);
      }
    }
  }

  Future<void> _executeSplit() async {
    if (_splitMode == SplitMode.selectedPages && _selectedPages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 1 page to extract')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const ProcessingDialog(message: 'Splitting document pages...'),
    );

    try {
      final tempDir = widget.fileStorageService.tempDirectory;
      final createdDocs = <DocumentModel>[];

      if (_splitMode == SplitMode.allSinglePages) {
        final splitPaths = await widget.pdfToolkitService.splitPdf(
          inputPath: widget.document.filePath,
          outputDir: tempDir.path,
          prefix: '${widget.document.title}_part',
        );

        for (int i = 0; i < splitPaths.length; i++) {
          final path = splitPaths[i];
          final file = File(path);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            final partTitle = '${widget.document.title} - Page ${i + 1}';
            final saved = await widget.fileStorageService.saveManagedPdf(partTitle, bytes);

            final now = DateTime.now();
            final doc = DocumentModel(
              id: 'doc_${now.millisecondsSinceEpoch}_$i',
              title: partTitle,
              filePath: saved.path,
              pageCount: 1,
              byteSize: bytes.length,
              createdAt: now,
              updatedAt: now,
            );
            await widget.documentRepository.insertDocument(doc);
            createdDocs.add(doc);
            file.deleteSync();
          }
        }
      } else {
        // Extract selected pages as a single document
        final sortedPages = _selectedPages.toList()..sort();
        final tempOutputFile = widget.fileStorageService.createTempFile(extension: 'pdf');

        await widget.pdfToolkitService.extractPages(
          inputPath: widget.document.filePath,
          outputPath: tempOutputFile.path,
          pageIndices: sortedPages,
        );

        final bytes = await tempOutputFile.readAsBytes();
        final partTitle = '${widget.document.title} (Extracted ${sortedPages.length} pages)';
        final saved = await widget.fileStorageService.saveManagedPdf(partTitle, bytes);

        final now = DateTime.now();
        final doc = DocumentModel(
          id: 'doc_${now.millisecondsSinceEpoch}',
          title: partTitle,
          filePath: saved.path,
          pageCount: sortedPages.length,
          byteSize: bytes.length,
          createdAt: now,
          updatedAt: now,
        );
        await widget.documentRepository.insertDocument(doc);
        createdDocs.add(doc);
        tempOutputFile.deleteSync();
      }

      if (mounted) {
        Navigator.of(context).pop(); // dismiss dialog
        _showSplitSummary(createdDocs);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Split failed: $e')),
        );
      }
    }
  }

  void _showSplitSummary(List<DocumentModel> docs) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 8),
            Text('Split Complete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Created ${docs.length} new ${docs.length == 1 ? "document" : "documents"} in your library:'),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: docs.length,
                itemBuilder: (ctx, i) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.picture_as_pdf, size: 20, color: AppColors.primary),
                  title: Text(docs[i].title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${docs[i].pageCount} pages • ${docs[i].formattedSize}'),
                ),
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            child: const Text('Back to Library'),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Split PDF'),
      ),
      body: SafeArea(
        child: _loadingPages
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mode Selector
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SegmentedButton<SplitMode>(
                      segments: const [
                        ButtonSegment(
                          value: SplitMode.allSinglePages,
                          label: Text('Each Page'),
                          icon: Icon(Icons.splitscreen),
                        ),
                        ButtonSegment(
                          value: SplitMode.selectedPages,
                          label: Text('Selected Pages'),
                          icon: Icon(Icons.check_box_outlined),
                        ),
                      ],
                      selected: {_splitMode},
                      onSelectionChanged: (val) => setState(() => _splitMode = val.first),
                    ),
                  ),

                  // Header info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _splitMode == SplitMode.allSinglePages
                              ? 'Will generate $_totalPages single-page files'
                              : 'Select pages to extract (${_selectedPages.length}/$_totalPages)',
                          style: AppTypography.titleMedium,
                        ),
                        if (_splitMode == SplitMode.selectedPages)
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
                  ),
                  const SizedBox(height: 8),

                  // Page Grid
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _totalPages,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedPages.contains(index);
                        return GestureDetector(
                          onTap: _splitMode == SplitMode.selectedPages
                              ? () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedPages.remove(index);
                                    } else {
                                      _selectedPages.add(index);
                                    }
                                  });
                                }
                              : null,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withAlpha(20) : Colors.grey.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : Colors.grey.withAlpha(60),
                                width: isSelected ? 2.0 : 1.0,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.description_outlined,
                                      size: 36,
                                      color: isSelected ? AppColors.primary : Colors.grey,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Page ${index + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? AppColors.primary : null,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_splitMode == SplitMode.selectedPages)
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Icon(
                                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                                      color: isSelected ? AppColors.primary : Colors.grey,
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom CTA
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DoxivoButton(
                      label: _splitMode == SplitMode.allSinglePages
                          ? 'Split Into $_totalPages Documents'
                          : 'Extract ${_selectedPages.length} Pages',
                      icon: Icons.splitscreen,
                      onPressed: _executeSplit,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

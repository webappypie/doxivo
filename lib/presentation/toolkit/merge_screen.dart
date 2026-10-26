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
import '../viewer/pdf_viewer_screen.dart';

class MergeScreen extends StatefulWidget {
  final List<DocumentModel>? initialDocuments;
  final PdfToolkitService pdfToolkitService;
  final FileStorageService fileStorageService;
  final DocumentRepository documentRepository;

  const MergeScreen({
    super.key,
    this.initialDocuments,
    required this.pdfToolkitService,
    required this.fileStorageService,
    required this.documentRepository,
  });

  @override
  State<MergeScreen> createState() => _MergeScreenState();
}

class _MergeFileEntry {
  final String title;
  final String path;
  final int pageCount;
  final int byteSize;

  _MergeFileEntry({
    required this.title,
    required this.path,
    required this.pageCount,
    required this.byteSize,
  });
}

class _MergeScreenState extends State<MergeScreen> {
  final List<_MergeFileEntry> _entries = [];
  final TextEditingController _titleController = TextEditingController(text: 'Merged Document');

  @override
  void initState() {
    super.initState();
    if (widget.initialDocuments != null) {
      for (final doc in widget.initialDocuments!) {
        _entries.add(_MergeFileEntry(
          title: doc.title,
          path: doc.filePath,
          pageCount: doc.pageCount,
          byteSize: doc.byteSize,
        ));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFromLibrary() async {
    final allDocs = await widget.documentRepository.getAllDocuments();
    if (!mounted) return;

    final selectedDocs = await showDialog<List<DocumentModel>>(
      context: context,
      builder: (ctx) {
        final selectedIds = <String>{};
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Select from Library'),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: allDocs.isEmpty
                    ? const Center(child: Text('No documents found in library'))
                    : ListView.builder(
                        itemCount: allDocs.length,
                        itemBuilder: (ctx, idx) {
                          final doc = allDocs[idx];
                          final isSelected = selectedIds.contains(doc.id);
                          return CheckboxListTile(
                            title: Text(doc.title),
                            subtitle: Text('${doc.pageCount} pages • ${doc.formattedSize}'),
                            value: isSelected,
                            onChanged: (val) {
                              setModalState(() {
                                if (val == true) {
                                  selectedIds.add(doc.id);
                                } else {
                                  selectedIds.remove(doc.id);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(ctx).pop(null),
                ),
                FilledButton(
                  child: const Text('Add Selected'),
                  onPressed: () {
                    final chosen = allDocs.where((d) => selectedIds.contains(d.id)).toList();
                    Navigator.of(ctx).pop(chosen);
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedDocs != null && selectedDocs.isNotEmpty) {
      setState(() {
        for (final doc in selectedDocs) {
          _entries.add(_MergeFileEntry(
            title: doc.title,
            path: doc.filePath,
            pageCount: doc.pageCount,
            byteSize: doc.byteSize,
          ));
        }
      });
    }
  }

  Future<void> _pickExternalPdfs() async {
    try {
      final paths = await widget.pdfToolkitService.pickExternalPdfs(allowMultiple: true);
      if (paths != null && paths.isNotEmpty) {
        for (final path in paths) {
          final file = File(path);
          final size = await file.length();
          final count = await widget.pdfToolkitService.getPageCount(path);
          final fileName = path.split(Platform.pathSeparator).last.replaceAll('.pdf', '');

          setState(() {
            _entries.add(_MergeFileEntry(
              title: fileName,
              path: path,
              pageCount: count,
              byteSize: size,
            ));
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick files: $e')),
        );
      }
    }
  }

  Future<void> _executeMerge() async {
    if (_entries.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 2 PDF files to merge')),
      );
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a document title')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const ProcessingDialog(message: 'Merging PDF documents...'),
    );

    try {
      final tempOutputFile = widget.fileStorageService.createTempFile(extension: 'pdf');
      final inputPaths = _entries.map((e) => e.path).toList();

      await widget.pdfToolkitService.mergePdfs(
        inputPaths: inputPaths,
        outputPath: tempOutputFile.path,
      );

      final bytes = await tempOutputFile.readAsBytes();
      final savedDoc = await widget.fileStorageService.saveManagedPdf(title, bytes);

      final totalPages = _entries.fold<int>(0, (sum, e) => sum + e.pageCount);
      final now = DateTime.now();
      final newDoc = DocumentModel(
        id: 'doc_${now.millisecondsSinceEpoch}',
        title: title,
        filePath: savedDoc.path,
        pageCount: totalPages,
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
          SnackBar(content: Text('Merged ${_entries.length} documents successfully!')),
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
          SnackBar(content: Text('Merge failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merge PDFs'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Merged Document Title',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
            ),

            // Top action buttons to add files
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.folder_open, size: 18),
                      label: const Text('From Library'),
                      onPressed: _pickFromLibrary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.file_upload_outlined, size: 18),
                      label: const Text('From Device'),
                      onPressed: _pickExternalPdfs,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // List of PDFs to merge with drag handle
            Expanded(
              child: _entries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.call_merge, size: 48, color: Colors.grey.withAlpha(100)),
                          const SizedBox(height: 12),
                          const Text('No documents added yet'),
                          const SizedBox(height: 4),
                          Text('Add 2 or more PDFs to combine them into one', style: AppTypography.bodySmall),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _entries.length,
                      onReorderItem: (oldIndex, newIndex) {
                        setState(() {
                          final item = _entries.removeAt(oldIndex);
                          _entries.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        return Card(
                          key: ValueKey('merge_${entry.path}_$index'),
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withAlpha(20),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                            title: Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text('${entry.pageCount} pages • ${(entry.byteSize / 1024).toStringAsFixed(1)} KB'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () => setState(() => _entries.removeAt(index)),
                                ),
                                const Icon(Icons.drag_handle, color: Colors.grey),
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
                label: 'Merge ${_entries.length} Documents',
                icon: Icons.call_merge,
                onPressed: _entries.length >= 2 ? _executeMerge : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

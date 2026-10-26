import 'dart:io';
import 'package:flutter/material.dart';

import '../../core/storage/file_storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/document_model.dart';
import '../../domain/models/ocr_language.dart';
import '../../domain/repositories/document_repository.dart';
import '../../services/pdf_toolkit_service.dart';
import '../../services/searchable_pdf_service.dart';
import '../viewer/pdf_viewer_screen.dart';

class SearchablePdfScreen extends StatefulWidget {
  final DocumentModel document;
  final DocumentRepository documentRepository;
  final FileStorageService fileStorageService;
  final PdfToolkitService pdfToolkitService;

  const SearchablePdfScreen({
    super.key,
    required this.document,
    required this.documentRepository,
    required this.fileStorageService,
    required this.pdfToolkitService,
  });

  @override
  State<SearchablePdfScreen> createState() => _SearchablePdfScreenState();
}

class _SearchablePdfScreenState extends State<SearchablePdfScreen> {
  late TextEditingController _titleController;
  OcrLanguage _selectedLanguage = OcrLanguage.english;
  bool _isProcessing = false;
  double _progress = 0.0;
  String _statusText = '';
  DocumentModel? _createdDocument;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: '${widget.document.title} (Searchable)');
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _startConversion() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid document title')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _progress = 0.0;
      _statusText = 'Preparing on-device OCR pipeline...';
    });

    try {
      final service = SearchablePdfService(fileStorageService: widget.fileStorageService);

      final resultFile = await service.makePdfSearchable(
        widget.document.filePath,
        pdfToolkitService: widget.pdfToolkitService,
        language: _selectedLanguage,
        onProgress: (current, total, status) {
          if (mounted) {
            setState(() {
              _progress = total > 0 ? (current / total) : 0.0;
              _statusText = status;
            });
          }
        },
      );

      final destPath = widget.fileStorageService.createManagedPdfPath(title);
      await resultFile.copy(destPath);
      final stat = await File(destPath).stat();

      final newDoc = DocumentModel(
        id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        filePath: destPath,
        thumbnailPath: widget.document.thumbnailPath,
        pageCount: widget.document.pageCount,
        byteSize: stat.size,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await widget.documentRepository.insertDocument(newDoc);

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _createdDocument = newDoc;
          _statusText = 'Successfully generated searchable PDF!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText = 'Error generating searchable PDF: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make PDF Searchable'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.find_in_page_outlined, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.document.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.document.pageCount} pages • ${widget.document.formattedSize}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Explanatory Note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accentTeal.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accentTeal.withAlpha(50)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 20, color: AppColors.accentTeal),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Searchable PDF embeds an invisible text layer over scanned images. This allows text selection, copying, and full-text keyword search in any PDF reader while preserving visual quality.',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Document Title
            TextField(
              controller: _titleController,
              enabled: !_isProcessing && _createdDocument == null,
              decoration: const InputDecoration(
                labelText: 'Searchable Document Title',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Language Selection
            const Text(
              'OCR Language / Script',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('English (Latin)')),
                    selected: _selectedLanguage == OcrLanguage.english,
                    onSelected: _isProcessing || _createdDocument != null
                        ? null
                        : (selected) {
                            if (selected) setState(() => _selectedLanguage = OcrLanguage.english);
                          },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Hindi (Devanagari)')),
                    selected: _selectedLanguage == OcrLanguage.hindi,
                    onSelected: _isProcessing || _createdDocument != null
                        ? null
                        : (selected) {
                            if (selected) setState(() => _selectedLanguage = OcrLanguage.hindi);
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Progress / Status indicator
            if (_isProcessing) ...[
              LinearProgressIndicator(value: _progress > 0 ? _progress : null),
              const SizedBox(height: 12),
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              const Text(
                '100% On-device processing. No files uploaded.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 24),
            ],

            // Success View
            if (_createdDocument != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentTeal.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentTeal),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.accentTeal, size: 40),
                    const SizedBox(height: 10),
                    const Text(
                      'Searchable PDF Ready!',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _createdDocument!.title,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (ctx) => PdfViewerScreen(
                              document: _createdDocument!,
                              documentRepository: widget.documentRepository,
                              fileStorageService: widget.fileStorageService,
                              pdfToolkitService: widget.pdfToolkitService,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('Open Searchable Document'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Action Button
            if (_createdDocument == null)
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _startConversion,
                icon: const Icon(Icons.find_in_page),
                label: Text(_isProcessing ? 'Processing...' : 'Make Document Searchable'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

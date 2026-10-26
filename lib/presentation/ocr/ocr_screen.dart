import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/storage/file_storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/document_model.dart';
import '../../domain/models/ocr_language.dart';
import '../../domain/models/ocr_result.dart';
import '../../domain/repositories/document_repository.dart';
import '../../services/ocr_service.dart';
import '../../services/pdf_toolkit_service.dart';
import '../../services/searchable_pdf_service.dart';
import '../viewer/pdf_viewer_screen.dart';

class OcrScreen extends StatefulWidget {
  final DocumentModel? document;
  final String? imagePath;
  final DocumentRepository documentRepository;
  final FileStorageService fileStorageService;
  final PdfToolkitService pdfToolkitService;

  const OcrScreen({
    super.key,
    this.document,
    this.imagePath,
    required this.documentRepository,
    required this.fileStorageService,
    required this.pdfToolkitService,
  });

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  OcrLanguage _selectedLanguage = OcrLanguage.english;
  bool _isLoading = false;
  String _statusMessage = '';
  List<OcrResult> _pageResults = [];
  int _currentPageIndex = 0;
  bool _isDocumentIndexed = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkIndexedStatus();
    _startOcr();
  }

  Future<void> _checkIndexedStatus() async {
    if (widget.document != null) {
      final indexed = await widget.documentRepository.isDocumentIndexed(widget.document!.id);
      if (mounted) {
        setState(() {
          _isDocumentIndexed = indexed;
        });
      }
    }
  }

  Future<void> _startOcr() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = 'Initializing on-device OCR...';
    });

    try {
      if (widget.document != null) {
        // PDF recognition
        final results = await OcrService.recognizePdf(
          widget.document!.filePath,
          pdfToolkitService: widget.pdfToolkitService,
          fileStorageService: widget.fileStorageService,
          language: _selectedLanguage,
          onProgress: (current, total) {
            if (mounted) {
              setState(() {
                _statusMessage = 'Recognizing page $current of $total (${_selectedLanguage.displayName})...';
              });
            }
          },
        );

        if (mounted) {
          setState(() {
            _pageResults = results;
            _isLoading = false;
            _statusMessage = '';
          });
        }
      } else if (widget.imagePath != null) {
        // Single image recognition
        setState(() {
          _statusMessage = 'Recognizing text (${_selectedLanguage.displayName})...';
        });

        final result = await OcrService.recognizeImage(
          widget.imagePath!,
          language: _selectedLanguage,
        );

        if (mounted) {
          setState(() {
            _pageResults = [result];
            _isLoading = false;
            _statusMessage = '';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'No document or image source provided.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'OCR processing failed: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _copyToClipboard() {
    final text = _getCurrentPageText();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No text available to copy')),
      );
      return;
    }

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Extracted text copied to clipboard')),
    );
  }

  Future<void> _shareText() async {
    final text = _getCurrentPageText();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No text available to share')),
      );
      return;
    }

    final title = widget.document?.title ?? 'Extracted Text';
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: '$title - OCR Text',
      ),
    );
  }

  String _getCurrentPageText() {
    if (_pageResults.isEmpty || _currentPageIndex >= _pageResults.length) {
      return '';
    }
    return _pageResults[_currentPageIndex].fullText;
  }

  String _getAllPagesText() {
    return _pageResults.map((r) => r.fullText).join('\n\n--- Page Break ---\n\n');
  }

  Future<void> _toggleIndexStatus() async {
    if (widget.document == null) return;

    final docId = widget.document!.id;
    if (_isDocumentIndexed) {
      await widget.documentRepository.clearDocumentOcrIndex(docId);
      if (mounted) {
        setState(() => _isDocumentIndexed = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document removed from local OCR search index')),
        );
      }
    } else {
      if (_pageResults.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No OCR text available to index')),
        );
        return;
      }

      await widget.documentRepository.indexDocumentOcr(docId, _pageResults);
      if (mounted) {
        setState(() => _isDocumentIndexed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document indexed for on-device search')),
        );
      }
    }
  }

  Future<void> _generateSearchablePdf() async {
    if (widget.document == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Searchable PDF generation requires a document source')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('Generating searchable PDF with aligned text layer...')),
          ],
        ),
      ),
    );

    try {
      final searchableService = SearchablePdfService(fileStorageService: widget.fileStorageService);
      final searchableFile = await searchableService.makePdfSearchable(
        widget.document!.filePath,
        pdfToolkitService: widget.pdfToolkitService,
        language: _selectedLanguage,
      );

      // Save to managed library
      final destPath = widget.fileStorageService.createManagedPdfPath('searchable_${widget.document!.title}');
      await searchableFile.copy(destPath);
      final stat = await File(destPath).stat();

      final newDoc = DocumentModel(
        id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
        title: '${widget.document!.title} (Searchable)',
        filePath: destPath,
        thumbnailPath: widget.document!.thumbnailPath,
        pageCount: widget.document!.pageCount,
        byteSize: stat.size,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await widget.documentRepository.insertDocument(newDoc);
      if (_pageResults.isNotEmpty) {
        await widget.documentRepository.indexDocumentOcr(newDoc.id, _pageResults);
      }

      if (mounted) {
        Navigator.of(context).pop(); // dismiss dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Searchable PDF created: ${newDoc.title}'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => PdfViewerScreen(
                      document: newDoc,
                      documentRepository: widget.documentRepository,
                      fileStorageService: widget.fileStorageService,
                      pdfToolkitService: widget.pdfToolkitService,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // dismiss dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate searchable PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.document?.title ?? 'OCR Recognition';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, overflow: TextOverflow.ellipsis),
        actions: [
          if (!_isLoading && _pageResults.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copy page text',
              onPressed: _copyToClipboard,
            ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share text',
              onPressed: _shareText,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Language selector bar & Index toggle
          _buildControlHeader(),
          const Divider(height: 1),

          // Main body: loading, error, or recognized text
          Expanded(
            child: _buildContent(),
          ),

          // Bottom Action Footer
          if (!_isLoading && _pageResults.isNotEmpty) _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildControlHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              const Text('Script: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ChoiceChip(
                label: const Text('English (Latin)'),
                selected: _selectedLanguage == OcrLanguage.english,
                onSelected: (selected) {
                  if (selected && _selectedLanguage != OcrLanguage.english) {
                    setState(() => _selectedLanguage = OcrLanguage.english);
                    _startOcr();
                  }
                },
              ),
              ChoiceChip(
                label: const Text('Hindi (Devanagari)'),
                selected: _selectedLanguage == OcrLanguage.hindi,
                onSelected: (selected) {
                  if (selected && _selectedLanguage != OcrLanguage.hindi) {
                    setState(() => _selectedLanguage = OcrLanguage.hindi);
                    _startOcr();
                  }
                },
              ),
            ],
          ),
          if (widget.document != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  _isDocumentIndexed ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 16,
                  color: _isDocumentIndexed ? AppColors.accentTeal : Colors.grey,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _isDocumentIndexed ? 'Indexed for on-device search' : 'Not indexed in local search',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isDocumentIndexed ? AppColors.accentTeal : Colors.grey[700],
                      fontWeight: _isDocumentIndexed ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: _toggleIndexStatus,
                  child: Text(
                    _isDocumentIndexed ? 'Remove Index' : 'Index for Search',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isDocumentIndexed ? AppColors.errorRed : AppColors.primaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              const Text(
                '100% On-Device Processing. No data leaves your phone.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.errorRed),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.errorRed),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _startOcr,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Recognition'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pageResults.isEmpty || !_pageResults.any((r) => r.hasText)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.text_fields_outlined, size: 56, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No Readable Text Detected',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Make sure the scanned page has clear printed or digital text with sufficient contrast and lighting.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _startOcr,
                icon: const Icon(Icons.refresh),
                label: const Text('Re-scan Page'),
              ),
            ],
          ),
        ),
      );
    }

    final currentResult = _pageResults[_currentPageIndex];

    return Column(
      children: [
        // Multi-page navigation bar
        if (_pageResults.length > 1) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).cardColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPageIndex > 0
                      ? () => setState(() => _currentPageIndex--)
                      : null,
                ),
                Text(
                  'Page ${_currentPageIndex + 1} of ${_pageResults.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPageIndex < _pageResults.length - 1
                      ? () => setState(() => _currentPageIndex++)
                      : null,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],

        // Extracted text display
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${currentResult.wordCount} words • ${currentResult.lineCount} lines',
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    if (currentResult.confidence != null)
                      Text(
                        'Confidence: ${(currentResult.confidence! * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: SelectableText(
                    currentResult.fullText.isNotEmpty
                        ? currentResult.fullText
                        : '(No text on this page)',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                final allText = _getAllPagesText();
                Clipboard.setData(ClipboardData(text: allText));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Copied all ${_pageResults.length} pages of text')),
                );
              },
              icon: const Icon(Icons.copy_all, size: 18),
              label: const Text('Copy All'),
            ),
          ),
          const SizedBox(width: 12),
          if (widget.document != null)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _generateSearchablePdf,
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text('Searchable PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

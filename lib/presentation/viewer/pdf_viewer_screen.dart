import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/document_model.dart';
import '../../domain/repositories/document_repository.dart';

class PdfViewerScreen extends StatefulWidget {
  final DocumentModel document;
  final DocumentRepository documentRepository;

  const PdfViewerScreen({
    super.key,
    required this.document,
    required this.documentRepository,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late DocumentModel _doc;
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _doc = widget.document;
  }

  Future<void> _toggleFavorite() async {
    await widget.documentRepository.toggleFavorite(_doc.id);
    setState(() {
      _doc = _doc.copyWith(isFavorite: !_doc.isFavorite);
    });
  }

  Future<void> _sharePdf() async {
    final file = File(_doc.filePath);
    if (await file.exists()) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(_doc.filePath, mimeType: 'application/pdf', name: '${_doc.title}.pdf')],
          text: 'Document: ${_doc.title}',
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File not found to share')),
        );
      }
    }
  }

  Future<void> _renameDocument() async {
    final controller = TextEditingController(text: _doc.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.of(ctx).pop(text);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle != _doc.title) {
      await widget.documentRepository.renameDocument(_doc.id, newTitle);
      setState(() {
        _doc = _doc.copyWith(title: newTitle);
      });
    }
  }

  Future<void> _deleteDocument() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document?'),
        content: Text('Are you sure you want to permanently delete "${_doc.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await widget.documentRepository.deleteDocument(_doc.id);
      if (mounted) {
        Navigator.of(context).pop(true); // Return deleted flag
      }
    }
  }

  void _showInfoSheet() {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Document Details', style: AppTypography.titleLarge),
              const SizedBox(height: 16),
              _infoRow('Title', _doc.title),
              _infoRow('Pages', '${_doc.pageCount}'),
              _infoRow('File Size', _doc.formattedSize),
              _infoRow('Created', dateFormat.format(_doc.createdAt)),
              _infoRow('Path', _doc.filePath),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppColors.textPrimaryLight)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktopOrWeb = Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_doc.title, style: AppTypography.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (_isReady)
              Text(
                'Page ${_currentPage + 1} of $_totalPages',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _doc.isFavorite ? Icons.star : Icons.star_border,
              color: _doc.isFavorite ? Colors.amber : null,
            ),
            tooltip: _doc.isFavorite ? 'Remove Favorite' : 'Favorite',
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: _sharePdf,
          ),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'rename') _renameDocument();
              if (val == 'info') _showInfoSheet();
              if (val == 'delete') _deleteDocument();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'rename', child: Text('Rename')),
              const PopupMenuItem(value: 'info', child: Text('Document Info')),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ],
      ),
      body: isDesktopOrWeb
          ? _buildDesktopFallback()
          : PDFView(
              filePath: _doc.filePath,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              pageSnap: true,
              onRender: (pages) {
                setState(() {
                  _totalPages = pages ?? _doc.pageCount;
                  _isReady = true;
                });
              },
              onPageChanged: (page, total) {
                setState(() {
                  _currentPage = page ?? 0;
                });
              },
              onError: (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error rendering PDF: $error')),
                );
              },
            ),
    );
  }

  Widget _buildDesktopFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.picture_as_pdf, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(_doc.title, style: AppTypography.titleLarge),
            const SizedBox(height: 8),
            Text(
              '${_doc.pageCount} ${_doc.pageCount == 1 ? "page" : "pages"} • ${_doc.formattedSize}',
              style: const TextStyle(color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _sharePdf,
              icon: const Icon(Icons.share),
              label: const Text('Share / Export Document'),
            ),
          ],
        ),
      ),
    );
  }
}

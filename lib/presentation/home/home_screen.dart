import 'package:flutter/material.dart';
import '../../core/storage/file_storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/document_model.dart';
import '../../domain/models/document_search_result.dart';
import '../../domain/repositories/document_repository.dart';
import '../../services/pdf_service.dart';
import '../../services/pdf_toolkit_service.dart';
import '../../services/scanner_service.dart';
import '../common/empty_state_view.dart';
import '../scanner/scan_review_screen.dart';
import '../toolkit/tools_hub_screen.dart';
import '../viewer/pdf_viewer_screen.dart';
import 'widgets/document_card.dart';
import 'widgets/quick_action_bar.dart';

class HomeScreen extends StatefulWidget {
  final FileStorageService fileStorageService;
  final DocumentRepository documentRepository;
  final PdfService pdfService;
  final ScannerService scannerService;
  final PdfToolkitService? pdfToolkitService;

  const HomeScreen({
    super.key,
    required this.fileStorageService,
    required this.documentRepository,
    required this.pdfService,
    required this.scannerService,
    this.pdfToolkitService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<DocumentModel> _documents = [];
  List<DocumentSearchResult> _searchResults = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _showFavoritesOnly = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    if (mounted && !_isLoading) {
      setState(() => _isLoading = true);
    }
    try {
      if (_searchQuery.trim().isNotEmpty) {
        final results = await widget.documentRepository.search(
          _searchQuery,
          favoritesOnly: _showFavoritesOnly,
        );
        if (mounted) {
          setState(() {
            _searchResults = results;
            _documents = results.map((r) => r.document).toList();
            _isLoading = false;
          });
        }
      } else {
        final docs = await widget.documentRepository.getAllDocuments(
          favoritesOnly: _showFavoritesOnly,
        );
        if (mounted) {
          setState(() {
            _searchResults = [];
            _documents = docs;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load documents: $e')),
        );
      }
    }
  }

  Future<void> _handleScan() async {
    try {
      final pictures = await widget.scannerService.scanWithDocumentScanner();
      if (pictures != null && pictures.isNotEmpty && mounted) {
        final resultDoc = await Navigator.of(context).push<DocumentModel>(
          MaterialPageRoute(
            builder: (ctx) => ScanReviewScreen(
              initialImagePaths: pictures,
              fileStorageService: widget.fileStorageService,
              documentRepository: widget.documentRepository,
              pdfService: widget.pdfService,
              scannerService: widget.scannerService,
            ),
          ),
        );

        if (resultDoc != null && mounted) {
          _loadDocuments();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved "${resultDoc.title}" successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanner error: $e')),
        );
      }
    }
  }

  Future<void> _handleImport() async {
    try {
      final pictures = await widget.scannerService.pickImagesFromGallery();
      if (pictures != null && pictures.isNotEmpty && mounted) {
        final resultDoc = await Navigator.of(context).push<DocumentModel>(
          MaterialPageRoute(
            builder: (ctx) => ScanReviewScreen(
              initialImagePaths: pictures,
              fileStorageService: widget.fileStorageService,
              documentRepository: widget.documentRepository,
              pdfService: widget.pdfService,
              scannerService: widget.scannerService,
            ),
          ),
        );

        if (resultDoc != null && mounted) {
          _loadDocuments();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Created "${resultDoc.title}" successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import error: $e')),
        );
      }
    }
  }

  Future<void> _toggleFavorite(DocumentModel doc) async {
    await widget.documentRepository.toggleFavorite(doc.id);
    _loadDocuments();
  }

  void _openToolsHub() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ToolsHubScreen(
          documentRepository: widget.documentRepository,
          fileStorageService: widget.fileStorageService,
          pdfToolkitService: widget.pdfToolkitService ?? PdfToolkitService(),
        ),
      ),
    );
  }

  Future<void> _openDocument(DocumentModel doc) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (ctx) => PdfViewerScreen(
          document: doc,
          documentRepository: widget.documentRepository,
          pdfToolkitService: widget.pdfToolkitService ?? PdfToolkitService(),
          fileStorageService: widget.fileStorageService,
        ),
      ),
    );

    if (deleted == true && mounted) {
      _loadDocuments();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document deleted')),
      );
    } else {
      _loadDocuments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.document_scanner, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Doxivo',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.build_outlined),
            tooltip: 'PDF Toolkit',
            onPressed: _openToolsHub,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Library',
            onPressed: _loadDocuments,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDocuments,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Quick Action Bar (Primary CTAs)
            QuickActionBar(
              onScanPressed: _handleScan,
              onImportPressed: _handleImport,
              onToolsPressed: _openToolsHub,
            ),
            const SizedBox(height: 24),

            // Search and Filter Header
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search documents...',
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondaryLight),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                _loadDocuments();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                      _loadDocuments();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                FilterChip(
                  label: const Text('Favorites'),
                  selected: _showFavoritesOnly,
                  avatar: Icon(
                    _showFavoritesOnly ? Icons.star : Icons.star_border,
                    size: 18,
                    color: _showFavoritesOnly ? Colors.amber.shade800 : AppColors.textSecondaryLight,
                  ),
                  onSelected: (val) {
                    setState(() => _showFavoritesOnly = val);
                    _loadDocuments();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Section Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _showFavoritesOnly ? 'Favorite Documents' : 'Recent Documents',
                  style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimaryLight),
                ),
                Text(
                  '${_documents.length} ${_documents.length == 1 ? "file" : "files"}',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMutedLight),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Document List or Empty State
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_documents.isEmpty)
              EmptyStateView(
                title: _searchQuery.isNotEmpty ? 'No Matching Documents' : 'No Documents Yet',
                description: _searchQuery.isNotEmpty
                    ? 'Try searching with a different keyword.'
                    : 'Tap "Scan Documents" to capture your first document or import photos from your device.',
                actionLabel: _searchQuery.isNotEmpty ? null : 'Scan First Document',
                onAction: _searchQuery.isNotEmpty ? null : _handleScan,
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _documents.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final doc = _documents[index];
                  String? snippet;
                  if (_searchResults.isNotEmpty && index < _searchResults.length) {
                    final searchRes = _searchResults[index];
                    if (searchRes.hasOcrMatches) {
                      final match = searchRes.ocrMatches.first;
                      snippet = 'Page ${match.pageIndex + 1}: "${match.snippetContext}"';
                    }
                  }
                  return DocumentCard(
                    document: doc,
                    onTap: () => _openDocument(doc),
                    onToggleFavorite: () => _toggleFavorite(doc),
                    ocrSnippet: snippet,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

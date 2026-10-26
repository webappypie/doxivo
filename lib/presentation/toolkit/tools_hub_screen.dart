import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/storage/file_storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/document_model.dart';
import '../../domain/repositories/document_repository.dart';
import '../../services/pdf_toolkit_service.dart';
import '../viewer/pdf_viewer_screen.dart';
import 'compress_screen.dart';
import 'export_images_screen.dart';
import 'merge_screen.dart';
import 'organize_pages_screen.dart';
import 'protect_screen.dart';
import 'signature_screen.dart';
import 'split_screen.dart';
import 'watermark_screen.dart';

class ToolsHubScreen extends StatelessWidget {
  final DocumentRepository documentRepository;
  final FileStorageService fileStorageService;
  final PdfToolkitService pdfToolkitService;

  const ToolsHubScreen({
    super.key,
    required this.documentRepository,
    required this.fileStorageService,
    required this.pdfToolkitService,
  });

  Future<void> _selectDocumentAndNavigate(
    BuildContext context,
    String toolTitle,
    Widget Function(DocumentModel doc) screenBuilder,
  ) async {
    final docs = await documentRepository.getAllDocuments();
    if (!context.mounted) return;

    if (docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No documents in your library yet. Import or scan a document first.'),
          action: SnackBarAction(
            label: 'Import',
            onPressed: () => _importExternalPdf(context),
          ),
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<DocumentModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (ctx, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  height: 4,
                  width: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Select Document for $toolTitle', style: AppTypography.titleMedium),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: docs.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final doc = docs[idx];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.picture_as_pdf, color: AppColors.primary),
                        ),
                        title: Text(doc.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${doc.pageCount} pages • ${doc.formattedSize}'),
                        onTap: () => Navigator.of(ctx).pop(doc),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected != null && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (ctx) => screenBuilder(selected)),
      );
    }
  }

  Future<void> _importExternalPdf(BuildContext context) async {
    try {
      final paths = await pdfToolkitService.pickExternalPdfs(allowMultiple: false);
      if (paths != null && paths.isNotEmpty) {
        final path = paths.first;
        final file = File(path);
        final bytes = await file.readAsBytes();
        final rawTitle = path.split(Platform.pathSeparator).last.replaceAll('.pdf', '');

        final saved = await fileStorageService.saveManagedPdf(rawTitle, bytes);
        final count = await pdfToolkitService.getPageCount(saved.path);

        final now = DateTime.now();
        final newDoc = DocumentModel(
          id: 'doc_${now.millisecondsSinceEpoch}',
          title: rawTitle,
          filePath: saved.path,
          pageCount: count,
          byteSize: bytes.length,
          createdAt: now,
          updatedAt: now,
        );

        await documentRepository.insertDocument(newDoc);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported "${newDoc.title}" successfully!')),
          );

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => PdfViewerScreen(
                document: newDoc,
                documentRepository: documentRepository,
                pdfToolkitService: pdfToolkitService,
                fileStorageService: fileStorageService,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Toolkit'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Import Callout
            Card(
              elevation: 0,
              color: AppColors.primary.withAlpha(15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.primary.withAlpha(40)),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.file_upload_outlined, color: Colors.white, size: 20),
                ),
                title: const Text('Import External PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Import PDF files from your device storage or downloads'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _importExternalPdf(context),
              ),
            ),
            const SizedBox(height: 20),

            Text('Document Operations', style: AppTypography.titleMedium),
            const SizedBox(height: 12),

            _ToolTile(
              icon: Icons.call_merge,
              iconColor: const Color(0xFF3B82F6),
              title: 'Merge PDFs',
              subtitle: 'Combine 2 or more PDF documents into a single file',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => MergeScreen(
                      pdfToolkitService: pdfToolkitService,
                      fileStorageService: fileStorageService,
                      documentRepository: documentRepository,
                    ),
                  ),
                );
              },
            ),

            _ToolTile(
              icon: Icons.splitscreen,
              iconColor: const Color(0xFF0D9488),
              title: 'Split PDF',
              subtitle: 'Extract specific pages or split into individual documents',
              onTap: () {
                _selectDocumentAndNavigate(
                  context,
                  'Split',
                  (doc) => SplitScreen(
                    document: doc,
                    pdfToolkitService: pdfToolkitService,
                    fileStorageService: fileStorageService,
                    documentRepository: documentRepository,
                  ),
                );
              },
            ),

            _ToolTile(
              icon: Icons.rotate_right,
              iconColor: const Color(0xFF8B5CF6),
              title: 'Organize & Rotate Pages',
              subtitle: 'Reorder, rotate, or delete individual pages',
              onTap: () {
                _selectDocumentAndNavigate(
                  context,
                  'Organize',
                  (doc) => OrganizePagesScreen(
                    document: doc,
                    pdfToolkitService: pdfToolkitService,
                    fileStorageService: fileStorageService,
                    documentRepository: documentRepository,
                  ),
                );
              },
            ),

            _ToolTile(
              icon: Icons.compress,
              iconColor: const Color(0xFFEA580C),
              title: 'Compress PDF',
              subtitle: 'Reduce file size with optimized presets and size reporting',
              onTap: () {
                _selectDocumentAndNavigate(
                  context,
                  'Compress',
                  (doc) => CompressScreen(
                    document: doc,
                    pdfToolkitService: pdfToolkitService,
                    fileStorageService: fileStorageService,
                    documentRepository: documentRepository,
                  ),
                );
              },
            ),

            _ToolTile(
              icon: Icons.lock,
              iconColor: const Color(0xFFDC2626),
              title: 'Protect PDF (Password)',
              subtitle: 'Encrypt with industry-standard AES-256 security',
              onTap: () {
                _selectDocumentAndNavigate(
                  context,
                  'Protect',
                  (doc) => ProtectScreen(
                    document: doc,
                    pdfToolkitService: pdfToolkitService,
                    fileStorageService: fileStorageService,
                    documentRepository: documentRepository,
                  ),
                );
              },
            ),

            _ToolTile(
              icon: Icons.draw,
              iconColor: const Color(0xFF2563EB),
              title: 'Sign PDF',
              subtitle: 'Draw signature and position it on any page',
              onTap: () {
                _selectDocumentAndNavigate(
                  context,
                  'Sign',
                  (doc) => SignatureScreen(
                    document: doc,
                    pdfToolkitService: pdfToolkitService,
                    fileStorageService: fileStorageService,
                    documentRepository: documentRepository,
                  ),
                );
              },
            ),

            _ToolTile(
              icon: Icons.branding_watermark_outlined,
              iconColor: const Color(0xFF059669),
              title: 'Add Watermark',
              subtitle: 'Add customizable text watermark with opacity and rotation',
              onTap: () {
                _selectDocumentAndNavigate(
                  context,
                  'Watermark',
                  (doc) => WatermarkScreen(
                    document: doc,
                    pdfToolkitService: pdfToolkitService,
                    fileStorageService: fileStorageService,
                    documentRepository: documentRepository,
                  ),
                );
              },
            ),

            _ToolTile(
              icon: Icons.image_outlined,
              iconColor: const Color(0xFF6B7280),
              title: 'Export as Images',
              subtitle: 'Convert PDF pages into high-resolution JPEG or PNG images',
              onTap: () {
                _selectDocumentAndNavigate(
                  context,
                  'Export Images',
                  (doc) => ExportImagesScreen(
                    document: doc,
                    pdfToolkitService: pdfToolkitService,
                    fileStorageService: fileStorageService,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ToolTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: AppTypography.bodySmall),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }
}

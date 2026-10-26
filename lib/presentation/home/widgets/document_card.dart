import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/document_model.dart';

class DocumentCard extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final String? ocrSnippet;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
    required this.onToggleFavorite,
    this.ocrSnippet,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final formattedDate = dateFormat.format(document.createdAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            // Thumbnail / Icon
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 54,
                height: 68,
                color: AppColors.surfaceMutedLight,
                child: document.thumbnailPath != null && File(document.thumbnailPath!).existsSync()
                    ? Image.file(
                        File(document.thumbnailPath!),
                        fit: BoxFit.cover,
                      )
                    : const Center(
                        child: Icon(
                          Icons.picture_as_pdf,
                          size: 32,
                          color: AppColors.primary,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // Metadata
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    style: AppTypography.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${document.pageCount} ${document.pageCount == 1 ? "page" : "pages"}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Text(' • ', style: TextStyle(color: AppColors.textMutedLight)),
                      Text(
                        document.formattedSize,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMutedLight,
                      fontSize: 11,
                    ),
                  ),
                  if (ocrSnippet != null && ocrSnippet!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accentTeal.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.find_in_page_outlined, size: 12, color: AppColors.accentTeal),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ocrSnippet!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.accentTeal,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Favorite Button
            IconButton(
              icon: Icon(
                document.isFavorite ? Icons.star : Icons.star_border,
                color: document.isFavorite ? Colors.amber : AppColors.textMutedLight,
                size: 24,
              ),
              onPressed: onToggleFavorite,
            ),
          ],
        ),
      ),
    );
  }
}

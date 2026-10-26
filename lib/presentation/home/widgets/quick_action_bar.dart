import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class QuickActionBar extends StatelessWidget {
  final VoidCallback onScanPressed;
  final VoidCallback onImportPressed;

  const QuickActionBar({
    super.key,
    required this.onScanPressed,
    required this.onImportPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Primary Scan Banner
        InkWell(
          onTap: onScanPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.document_scanner, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan Documents',
                        style: AppTypography.titleLarge.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Auto-edge detection & instant PDF',
                        style: AppTypography.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Secondary Gallery Import Action
        OutlinedButton.icon(
          onPressed: onImportPressed,
          icon: const Icon(Icons.photo_library_outlined, size: 20),
          label: const Text('Import Images to PDF'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimaryLight,
            side: const BorderSide(color: AppColors.borderLight, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }
}

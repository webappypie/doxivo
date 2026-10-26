import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum DoxivoButtonVariant {
  primary,
  secondary,
  destructive,
  ghost,
}

class DoxivoButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final DoxivoButtonVariant variant;
  final bool isLoading;

  const DoxivoButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = DoxivoButtonVariant.primary,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case DoxivoButtonVariant.primary:
        bgColor = AppColors.primary;
        fgColor = Colors.white;
        break;
      case DoxivoButtonVariant.secondary:
        bgColor = AppColors.surfaceMutedLight;
        fgColor = AppColors.primary;
        borderSide = const BorderSide(color: AppColors.borderLight, width: 1.5);
        break;
      case DoxivoButtonVariant.destructive:
        bgColor = AppColors.error;
        fgColor = Colors.white;
        break;
      case DoxivoButtonVariant.ghost:
        bgColor = Colors.transparent;
        fgColor = AppColors.primary;
        break;
    }

    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: 0,
          side: borderSide,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: fgColor),
                    const SizedBox(width: 8),
                  ],
                  Text(label, style: AppTypography.labelLarge.copyWith(color: fgColor)),
                ],
              ),
      ),
    );
  }
}

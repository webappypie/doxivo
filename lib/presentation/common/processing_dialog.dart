import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class ProcessingDialog extends StatelessWidget {
  final String message;

  const ProcessingDialog({
    super.key,
    this.message = 'Processing document...',
  });

  static void show(BuildContext context, {String message = 'Processing document...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ProcessingDialog(message: message),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
              const SizedBox(width: 20),
              Flexible(
                child: Text(
                  message,
                  style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimaryLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

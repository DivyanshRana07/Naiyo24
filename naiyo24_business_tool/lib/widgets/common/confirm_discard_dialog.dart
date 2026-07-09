import 'package:flutter/material.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';

/// Reusable dialog for confirming discard of unsaved changes
class ConfirmDiscardDialog {
  static Future<bool> show(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Discard Changes?', style: AppTextStyles.h2),
        content: Text(
          'You have unsaved changes. Are you sure you want to discard them?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelLarge
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              'Discard',
              style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }
}

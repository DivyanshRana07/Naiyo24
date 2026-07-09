import 'package:flutter/material.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';

/// A reusable dialog shell for entity create/edit forms.
///
/// Eliminates the repeated Dialog > ConstrainedBox > Padding > Form > Column
/// scaffold that was duplicated across every form dialog (Customer, Item,
/// Vendor, Service). Each concrete form only needs to supply the form fields
/// and a save callback.
///
/// Example usage:
/// ```dart
/// AppFormDialog(
///   formKey: _formKey,
///   title: _isEditing ? 'Edit Customer' : 'Add New Client',
///   icon: Icons.person_add_rounded,
///   iconColor: Color(0xFF16A34A),
///   iconBgColor: Color(0xFFDCFCE7),
///   saveLabel: _isEditing ? 'Save Changes' : 'Save Customer',
///   onSave: _save,
///   children: [ /* form fields */ ],
/// )
/// ```
class AppFormDialog extends StatelessWidget {
  const AppFormDialog({
    super.key,
    required this.formKey,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.children,
    required this.onSave,
    required this.saveLabel,
    this.maxWidth = 560,
    this.saveColor,
  });

  /// The [GlobalKey<FormState>] owned by the calling widget.
  final GlobalKey<FormState> formKey;

  /// Dialog title shown in the header.
  final String title;

  /// Icon shown in the coloured icon badge next to the title.
  final IconData icon;

  /// Foreground colour of the icon.
  final Color iconColor;

  /// Background colour of the icon badge container.
  final Color iconBgColor;

  /// Form field widgets displayed between the header divider and action buttons.
  final List<Widget> children;

  /// Called when the primary "Save" button is tapped (after validation passes
  /// in the calling widget's [onSave]).
  final VoidCallback onSave;

  /// Label for the primary save button.
  final String saveLabel;

  /// Maximum width of the dialog. Defaults to 560.
  final double maxWidth;

  /// Optional override for the save button background colour.
  /// Defaults to [AppColors.primary].
  final Color? saveColor;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth.toDouble()),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header ──────────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.sm),
                        ),
                        child: Icon(icon, color: iconColor, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(title, style: AppTextStyles.h2),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                            foregroundColor: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Divider(color: AppColors.border),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Form Fields ──────────────────────────────────────────
                  ...children,

                  const SizedBox(height: AppSpacing.xl),

                  // ── Action Buttons ───────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: saveColor ?? AppColors.primary,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppBorderRadius.md),
                            ),
                          ),
                          onPressed: onSave,
                          child: Text(
                            saveLabel,
                            style: AppTextStyles.labelLarge
                                .copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

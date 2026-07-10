import 'package:flutter/material.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';

/// Reusable section title with icon for forms
class FormSectionTitle extends StatelessWidget {
  const FormSectionTitle({
    super.key,
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            title,
            style: AppTextStyles.h2,
          ),
        ),
      ],
    );
  }
}

/// **Canonical form-field label widget for this app.**
///
/// Use this instead of creating private `_label()` helper methods inside
/// individual form dialogs. Renders a small, bold, styled label above an
/// input field with an optional sub-label.
///
/// Example:
/// ```dart
/// const FormFieldLabel(text: 'Customer Name *'),
/// TextFormField(controller: _nameCtrl, ...),
/// ```
class FormFieldLabel extends StatelessWidget {
  const FormFieldLabel({
    super.key,
    required this.text,
    this.subtitle,
  });

  final String text;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Reusable form header with back button
class FormHeader extends StatelessWidget {
  const FormHeader({
    super.key,
    required this.title,
    required this.icon,
    this.onBack,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack ?? () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(title, style: AppTextStyles.h1),
        ),
      ],
    );
  }
}

/// Reusable date picker field
class DatePickerField extends StatelessWidget {
  const DatePickerField({
    super.key,
    required this.label,
    required this.date,
    required this.onDatePicked,
    this.width = 200,
  });

  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onDatePicked;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormFieldLabel(text: label),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) onDatePicked(picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${date.day.toString().padLeft(2, '0')}/'
                    '${date.month.toString().padLeft(2, '0')}/'
                    '${date.year}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable read-only field with icon
class ReadOnlyField extends StatelessWidget {
  const ReadOnlyField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.width = 200,
  });

  final String label;
  final String value;
  final IconData icon;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormFieldLabel(text: label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable summary row for totals
class SummaryRow extends StatelessWidget {
  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? AppTextStyles.h3.copyWith(color: AppColors.textPrimary)
                : AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
          ),
          Text(
            value,
            style: isTotal
                ? AppTextStyles.h2.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w400,
                  )
                : AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Reusable card container
class CardContainer extends StatelessWidget {
  const CardContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

/// Reusable section with a [FormSectionTitle] header and a multiline [TextField].
///
/// Used on the create-invoice and create-quotation screens for Terms, Notes, etc.
class TextInputSection extends StatelessWidget {
  const TextInputSection({
    super.key,
    required this.title,
    required this.icon,
    required this.controller,
    this.hintText = 'Enter text...',
    this.maxLines = 4,
    this.isRequired = false,
  });

  final String title;
  final IconData icon;
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormSectionTitle(
          title: isRequired ? '$title *' : '$title (Optional)',
          icon: icon,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle:
                AppTextStyles.caption.copyWith(color: AppColors.textHint),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              borderSide: BorderSide(color: AppColors.border),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
        ),
      ],
    );
  }
}

/// A simple two-column row layout for forms.
class FormPairRow extends StatelessWidget {
  const FormPairRow({
    super.key,
    required this.left,
    required this.right,
    this.spacing = AppSpacing.md,
  });

  final Widget left;
  final Widget right;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        SizedBox(width: spacing),
        Expanded(child: right),
      ],
    );
  }
}

/// A wrapper that associates a FormFieldLabel with a form input field.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel(text: label, subtitle: subtitle),
        child,
      ],
    );
  }
}

/// Action buttons for forms (Save, optional Save & Send, Cancel)
class FormActionButtons extends StatelessWidget {
  const FormActionButtons({
    super.key,
    required this.isSaving,
    this.isSavingAndSending = false,
    required this.onSave,
    required this.onCancel,
    this.onSaveAndSend,
    this.saveLabel = 'Save',
    this.sendLabel = 'Save & Send',
    this.cancelLabel = 'Cancel',
    this.saveColor,
    this.sendColor = const Color(0xFF0284C7),
    this.buttonHeight = 48.0,
    this.spacing = AppSpacing.sm,
  });

  final bool isSaving;
  final bool isSavingAndSending;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final VoidCallback? onSaveAndSend;
  final String saveLabel;
  final String sendLabel;
  final String cancelLabel;
  final Color? saveColor;
  final Color sendColor;
  final double buttonHeight;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final resolvedSaveColor = saveColor ?? AppColors.primary;
    final bool anySaving = isSaving || isSavingAndSending;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: anySaving ? null : onSave,
          style: FilledButton.styleFrom(
            backgroundColor: resolvedSaveColor,
            minimumSize: Size(0, buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
          ),
          icon: isSaving
              ? SizedBox(
                  width: buttonHeight * 0.35,
                  height: buttonHeight * 0.35,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: resolvedSaveColor == AppColors.primary ? AppColors.textOnPrimary : Colors.white,
                  ),
                )
              : Icon(Icons.save_rounded, size: 18, color: resolvedSaveColor == AppColors.primary ? AppColors.textOnPrimary : Colors.white),
          label: Text(
            isSaving ? 'Saving...' : saveLabel,
            style: AppTextStyles.labelLarge.copyWith(color: resolvedSaveColor == AppColors.primary ? AppColors.textOnPrimary : Colors.white),
          ),
        ),
        if (onSaveAndSend != null) ...[
          SizedBox(height: spacing),
          FilledButton.icon(
            onPressed: anySaving ? null : onSaveAndSend,
            style: FilledButton.styleFrom(
              backgroundColor: sendColor,
              minimumSize: Size(0, buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
            ),
            icon: isSavingAndSending
                ? SizedBox(
                    width: buttonHeight * 0.35,
                    height: buttonHeight * 0.35,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 18, color: Colors.white),
            label: Text(
              isSavingAndSending ? 'Saving...' : sendLabel,
              style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
            ),
          ),
        ],
        SizedBox(height: spacing),
        OutlinedButton(
          onPressed: anySaving ? null : onCancel,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            side: BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
          ),
          child: Text(
            cancelLabel,
            style: AppTextStyles.labelLarge
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}


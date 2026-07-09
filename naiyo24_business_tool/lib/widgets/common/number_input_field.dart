import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';

/// Reusable number input field for numeric data entry
class NumberInputField extends StatelessWidget {
  const NumberInputField({
    super.key,
    required this.controller,
    required this.label,
    this.onChanged,
    this.width,
    this.allowDecimal = true,
    this.textAlign = TextAlign.center,
  });

  final TextEditingController controller;
  final String label;
  final void Function(String)? onChanged;
  final double? width;
  final bool allowDecimal;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    Widget field = TextFormField(
      controller: controller,
      onChanged: onChanged,
      textAlign: textAlign,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          allowDecimal ? RegExp(r'^\d*\.?\d*') : RegExp(r'^\d*'),
        ),
      ],
      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w400),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textHint),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.surface,
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: field);
    }
    return field;
  }
}

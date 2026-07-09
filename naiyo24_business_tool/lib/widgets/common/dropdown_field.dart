import 'package:flutter/material.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';

/// Reusable dropdown field widget
class DropdownField<T> extends StatelessWidget {
  const DropdownField({
    super.key,
    required this.items,
    this.value,
    this.hint,
    this.label,
    this.onChanged,
    this.validator,
    this.isExpanded = true,
    this.prefixIcon,
  });

  final List<DropdownMenuItem<T>> items;
  final T? value;
  final String? hint;
  final String? label;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final bool isExpanded;
  final Widget? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: isExpanded,
      hint: hint != null ? Text(hint!) : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }

  /// Helper to create simple string dropdown items
  static List<DropdownMenuItem<String>> stringItems(List<String> values) {
    return values
        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
        .toList();
  }

  /// Helper to create categorized dropdown with headers
  static List<DropdownMenuItem<String>> categorizedItems(
    Map<String, List<String>> categories,
  ) {
    final items = <DropdownMenuItem<String>>[];
    
    categories.forEach((category, values) {
      // Add category header
      items.add(
        DropdownMenuItem<String>(
          enabled: false,
          child: Text(
            category,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
        ),
      );
      
      // Add category items with indentation
      for (final value in values) {
        items.add(
          DropdownMenuItem<String>(
            value: value,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(value, style: const TextStyle(fontSize: 13)),
            ),
          ),
        );
      }
    });
    
    return items;
  }
}

import 'package:flutter/material.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';

/// Reusable styled button for adding new resources (Client, Item, etc.)
class AddResourceButton extends StatelessWidget {
  const AddResourceButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.backgroundColor,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData icon;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.primary,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
      ),
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontSize: 13,
        ),
      ),
    );
  }

  /// Preset for adding new client
  factory AddResourceButton.newClient(VoidCallback onPressed) {
    return AddResourceButton(
      label: 'Add New Client',
      onPressed: onPressed,
      icon: Icons.person_add_rounded,
    );
  }

  /// Preset for adding new item
  factory AddResourceButton.newItem(VoidCallback onPressed) {
    return AddResourceButton(
      label: 'Add New Item',
      onPressed: onPressed,
      icon: Icons.add_box_rounded,
    );
  }

  /// Preset for adding new vendor
  factory AddResourceButton.newVendor(VoidCallback onPressed) {
    return AddResourceButton(
      label: 'Add New Vendor',
      onPressed: onPressed,
      icon: Icons.person_add_alt_rounded,
      backgroundColor: AppColors.primary,
    );
  }
}

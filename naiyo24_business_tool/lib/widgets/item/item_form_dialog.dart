import 'package:flutter/material.dart';
import 'package:naiyo24_business_tool/models/item_model.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/widgets/item/item_form.dart';

class ItemFormDialog extends StatelessWidget {
  const ItemFormDialog({super.key, this.existing, this.onSaved});

  final ItemModel? existing;
  final void Function(ItemModel)? onSaved;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                      ),
                      child: Icon(Icons.inventory_2_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        existing != null ? 'Edit Item' : 'Add New Item',
                        style: AppTextStyles.h2,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                          foregroundColor: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Divider(color: AppColors.border),
                const SizedBox(height: AppSpacing.lg),
                ItemForm(
                  existing: existing,
                  onSaved: onSaved,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

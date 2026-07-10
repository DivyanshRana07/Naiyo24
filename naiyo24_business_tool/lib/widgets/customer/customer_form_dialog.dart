import 'package:flutter/material.dart';
import 'package:naiyo24_business_tool/models/customer_model.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/widgets/customer/customer_form.dart';

class CustomerFormDialog extends StatelessWidget {
  const CustomerFormDialog({super.key, this.existing, this.onSaved});

  final CustomerModel? existing;
  final void Function(CustomerModel)? onSaved;

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
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                      ),
                      child: const Icon(Icons.person_add_rounded,
                          color: Color(0xFF16A34A), size: 20),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        existing != null ? 'Edit Client' : 'Add New Client',
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
                CustomerForm(
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

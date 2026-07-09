import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:naiyo24_business_tool/routes/app_routes.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';

/// Reusable dialog to choose between creating a physical item or a service
class AddItemServiceDialog {
  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.add_circle_outline_rounded,
                      color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Text('Add New', style: AppTextStyles.h2),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Select whether you want to create a physical item or a service.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(dialogContext);
                        context.push(AppRoutes.newItem);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.primary.withValues(alpha: 0.05),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.inventory_2_rounded,
                                size: 36, color: AppColors.primary),
                            const SizedBox(height: 12),
                            Text(
                              'New Item',
                              style: AppTextStyles.labelLarge
                                  .copyWith(fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Physical product',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(dialogContext);
                        context.push(AppRoutes.newService);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF0284C7)
                                .withValues(alpha: 0.2),
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFF0284C7)
                                .withValues(alpha: 0.05),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.miscellaneous_services_rounded,
                                size: 36, color: Color(0xFF0284C7)),
                            const SizedBox(height: 12),
                            Text(
                              'New Service',
                              style: AppTextStyles.labelLarge
                                  .copyWith(fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Non-physical service',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

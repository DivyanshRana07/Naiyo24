import 'package:flutter/material.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';

class EmptyStatePlaceholder extends StatelessWidget {
  const EmptyStatePlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: r.spacing(200)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r.borderRadius(AppBorderRadius.lg)),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: r.padding(
            vertical: AppSpacing.xxl,
            horizontal: AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: r.padding(all: AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: r.iconSize(48),
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: r.spacing(AppSpacing.lg)),
              Text(
                title,
                style: AppTextStyles.h2.copyWith(fontSize: r.fontSize(20)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: r.spacing(AppSpacing.sm)),
              Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: r.fontSize(14),
                ),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                SizedBox(height: r.spacing(AppSpacing.xl)),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: Icon(Icons.add_rounded, size: r.iconSize(20)),
                  label: Text(actionLabel!, style: TextStyle(fontSize: r.fontSize(14))),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

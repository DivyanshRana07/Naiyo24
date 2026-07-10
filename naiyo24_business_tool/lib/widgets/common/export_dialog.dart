import 'package:flutter/material.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/utils/export_helper.dart';

class ExportOptionsDialog extends StatelessWidget {
  const ExportOptionsDialog({
    super.key,
    required this.title,
    required this.csvContent,
    required this.whatsappText,
    required this.pdfContent,
    required this.filenamePrefix,
    this.onExportPdf,
  });

  final String title;
  final String csvContent;
  final String whatsappText;
  final String pdfContent;
  final String filenamePrefix;
  final Future<void> Function()? onExportPdf;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
      ),
      elevation: 8,
      backgroundColor: AppColors.background,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Export Options', style: AppTextStyles.h2),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Select your preferred format to export the $title list.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildOptionCard(
              context: context,
              icon: Icons.table_view_rounded,
              color: AppColors.success,
              title: 'Export as CSV',
              subtitle: 'Download spreadsheet compatible file (.csv)',
              onTap: () {
                downloadFile(
                  filename: '${filenamePrefix}_export.csv',
                  content: csvContent,
                  mimeType: 'text/csv',
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('CSV exported successfully!'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _buildOptionCard(
              context: context,
              icon: Icons.picture_as_pdf_rounded,
              color: AppColors.error,
              title: 'Export as PDF',
              subtitle: 'Download professionally formatted PDF report',
              onTap: () async {
                if (onExportPdf != null) {
                  Navigator.pop(context);
                  try {
                    await onExportPdf!();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('PDF exported successfully!'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to export PDF: $e'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                } else {
                  downloadFile(
                    filename: '${filenamePrefix}_report.txt',
                    content: pdfContent,
                    mimeType: 'text/plain',
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Text report exported successfully!'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _buildOptionCard(
              context: context,
              icon: Icons.description_rounded,
              color: AppColors.info,
              title: 'Export as Text Report',
              subtitle: 'Download printable text report document (.txt)',
              onTap: () {
                downloadFile(
                  filename: '${filenamePrefix}_report.txt',
                  content: pdfContent,
                  mimeType: 'text/plain',
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Text report exported successfully!'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _buildOptionCard(
              context: context,
              icon: Icons.share_rounded,
              color: Colors.teal,
              title: 'Share on WhatsApp',
              subtitle: 'Open WhatsApp with data summary text',
              onTap: () {
                shareToWhatsApp(text: whatsappText);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

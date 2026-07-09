import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/utils/export_helper.dart';
import 'package:naiyo24_business_tool/notifiers/invoice_notifier.dart';
import 'package:naiyo24_business_tool/models/invoice_model.dart';
import 'package:naiyo24_business_tool/models/quotation_model.dart';

class SendOptionsDialog extends ConsumerWidget {
  const SendOptionsDialog({
    super.key,
    required this.title,
    required this.whatsappText,
    required this.pdfContent,
    required this.filenamePrefix,
    required this.onClose,
    this.invoiceId,
    this.invoiceNo,
    this.onSave,
    this.whatsappTextBuilder,
    this.pdfContentBuilder,
  });

  final String title;
  final String whatsappText;
  final String pdfContent;
  final String filenamePrefix;
  final VoidCallback onClose;
  final String? invoiceId;
  final String? invoiceNo;
  final Future<dynamic> Function()? onSave;
  final String Function(dynamic)? whatsappTextBuilder;
  final String Function(dynamic)? pdfContentBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  onPressed: () {
                    Navigator.pop(context);
                    if (onSave == null) {
                      onClose();
                    }
                  },
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
              icon: Icons.chat_outlined,
              color: Colors.green,
              title: 'Send to WhatsApp...',
              subtitle: 'Open WhatsApp with data summary text',
              onTap: () async {
                String finalWhatsAppText = whatsappText;
                if (onSave != null) {
                  final saved = await onSave!();
                  if (saved == null) return;
                  if (!context.mounted) return;
                  if (whatsappTextBuilder != null) {
                    finalWhatsAppText = whatsappTextBuilder!(saved);
                  }
                }
                shareToWhatsApp(text: finalWhatsAppText);
                if (context.mounted) {
                  Navigator.pop(context);
                  onClose();
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _buildOptionCard(
              context: context,
              icon: Icons.picture_as_pdf_rounded,
              color: AppColors.error,
              title: 'Download / Print as PDF',
              subtitle: 'Download printable document (.pdf)',
              onTap: () async {
                dynamic savedInstance;
                if (onSave != null) {
                  savedInstance = await onSave!();
                  if (savedInstance == null) return;
                  if (!context.mounted) return;
                }

                final finalId = savedInstance?.id ?? invoiceId;
                String? docNo;
                if (savedInstance != null) {
                  if (savedInstance is InvoiceModel) {
                    docNo = savedInstance.invoiceNo;
                  } else if (savedInstance is QuotationModel) {
                    docNo = savedInstance.quotationNo;
                  }
                }
                final finalNo = docNo ?? invoiceNo;
                final isLocal = finalId?.startsWith('inv-local-') ?? true;

                String finalPdfContent = pdfContent;
                if (savedInstance != null && pdfContentBuilder != null) {
                  finalPdfContent = pdfContentBuilder!(savedInstance);
                }

                if (finalId != null && finalNo != null && !isLocal) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Downloading GST invoice from backend...'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 1),
                    ),
                  );
                  await ref
                      .read(invoiceNotifierProvider.notifier)
                      .downloadInvoicePdf(finalId!, finalNo);
                } else {
                  final numberSuffix = finalNo ?? '';
                  final filename = numberSuffix.isNotEmpty
                      ? '${filenamePrefix}_$numberSuffix.pdf'
                      : '${filenamePrefix}_report.pdf';
                  downloadFile(
                    filename: filename,
                    content: finalPdfContent,
                    mimeType: 'application/pdf',
                  );
                }
                if (context.mounted) {
                  Navigator.pop(context);
                  onClose();
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _buildOptionCard(
              context: context,
              icon: Icons.share_rounded,
              color: Colors.teal,
              title: 'Share via other apps',
              subtitle: 'Share standard format text...',
              onTap: () async {
                String finalWhatsAppText = whatsappText;
                dynamic savedInstance;
                if (onSave != null) {
                  savedInstance = await onSave!();
                  if (savedInstance == null) return;
                  if (!context.mounted) return;
                  if (whatsappTextBuilder != null) {
                    finalWhatsAppText = whatsappTextBuilder!(savedInstance);
                  }
                }

                String? docNo;
                if (savedInstance != null) {
                  if (savedInstance is InvoiceModel) {
                    docNo = savedInstance.invoiceNo;
                  } else if (savedInstance is QuotationModel) {
                    docNo = savedInstance.quotationNo;
                  }
                }
                final finalNo = docNo ?? invoiceNo ?? '';
                final filename = finalNo.isNotEmpty
                    ? '${filenamePrefix}_${finalNo}_share.txt'
                    : '${filenamePrefix}_share.txt';

                downloadFile(
                  filename: filename,
                  content: finalWhatsAppText,
                  mimeType: 'text/plain',
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  onClose();
                }
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (onSave == null) {
                    onClose();
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                ),
                child: Text('Cancel',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.textSecondary)),
              ),
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

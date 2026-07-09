import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:naiyo24_business_tool/models/invoice_model.dart';
import 'package:naiyo24_business_tool/notifiers/auth_notifier.dart';
import 'package:naiyo24_business_tool/notifiers/invoice_notifier.dart';
import 'package:naiyo24_business_tool/routes/app_routes.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/widgets/common/dashboard_app_bar.dart';
import 'package:naiyo24_business_tool/widgets/common/screen_shell.dart';
import 'package:naiyo24_business_tool/widgets/invoice/invoice_detail_widgets.dart';
import 'package:naiyo24_business_tool/widgets/invoice/record_payment_dialog.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  final String invoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final invoice =
        ref.watch(invoiceNotifierProvider.notifier).findById(invoiceId);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (invoice == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar:
            DashboardAppBar(email: authState.userEmail, showBackButton: true),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 64, color: AppColors.textHint),
              const SizedBox(height: AppSpacing.md),
              Text('Invoice not found.',
                  style: AppTextStyles.h2
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => context.go(AppRoutes.invoices),
                child: const Text('Back to Invoices'),
              ),
            ],
          ),
        ),
      );
    }

    final actionButtons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (invoice.status != InvoiceStatus.paid) ...[
          FilledButton.icon(
            onPressed: () => _showRecordPayment(context, ref, invoice),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md)),
            ),
            icon: const Icon(Icons.payments_rounded,
                size: 18, color: Colors.white),
            label: Text('Record Payment',
                style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        OutlinedButton.icon(
          onPressed: () =>
              context.push(AppRoutes.returnItemsPath(invoice.id)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.warning),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.md)),
          ),
          icon: Icon(Icons.assignment_return_rounded,
              size: 18, color: AppColors.warning),
          label: Text('Return',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.warning)),
        ),
        const SizedBox(width: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => _confirmDelete(context, ref, invoice),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.error),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.md)),
          ),
          icon: Icon(Icons.delete_rounded,
              size: 18, color: AppColors.error),
          label: Text('Delete',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.error)),
        ),
      ],
    );

    return ScreenShell(
      currentRoute: AppRoutes.invoices,
      title: invoice.invoiceNo,
      icon: Icons.receipt_long_rounded,
      onBack: () => context.go(AppRoutes.invoices),
      actions: actionButtons,
      body: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: Column(
                    children: [
                      InvoiceMeta(invoice: invoice),
                      const SizedBox(height: AppSpacing.lg),
                      CustomerCard(invoice: invoice),
                      const SizedBox(height: AppSpacing.lg),
                      LineItemsTable(invoice: invoice),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                SizedBox(
                  width: 300,
                  child: Column(
                    children: [
                      FinancialSummary(invoice: invoice),
                      const SizedBox(height: AppSpacing.lg),
                      PaymentPanel(invoice: invoice),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                InvoiceMeta(invoice: invoice),
                const SizedBox(height: AppSpacing.lg),
                CustomerCard(invoice: invoice),
                const SizedBox(height: AppSpacing.lg),
                LineItemsTable(invoice: invoice),
                const SizedBox(height: AppSpacing.lg),
                FinancialSummary(invoice: invoice),
                const SizedBox(height: AppSpacing.lg),
                PaymentPanel(invoice: invoice),
              ],
            ),
    );
  }

  void _showRecordPayment(BuildContext context, WidgetRef ref, InvoiceModel invoice) {
    showDialog(
      context: context,
      builder: (_) => RecordPaymentDialog(invoice: invoice),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, InvoiceModel invoice) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: Text(
            'Delete ${invoice.invoiceNo} for ${invoice.customerName}? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref
                  .read(invoiceNotifierProvider.notifier)
                  .deleteInvoice(invoice.id);
              Navigator.pop(ctx);
              context.go(AppRoutes.invoices);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

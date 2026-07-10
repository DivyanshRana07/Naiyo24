import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:naiyo24_business_tool/models/purchase_order_model.dart';
import 'package:naiyo24_business_tool/notifiers/auth_notifier.dart';
import 'package:naiyo24_business_tool/notifiers/purchase_order_notifier.dart';
import 'package:naiyo24_business_tool/routes/app_routes.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/widgets/common/dashboard_app_bar.dart';
import 'package:naiyo24_business_tool/widgets/common/screen_shell.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  const ExpenseDetailScreen({super.key, required this.expenseId});

  final String expenseId;

  void _confirmDelete(BuildContext context, WidgetRef ref, PurchaseOrderModel po) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete this expense ref: ${po.poNumber}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnPrimary,
            ),
            onPressed: () {
              ref.read(purchaseOrderNotifierProvider.notifier).deletePurchaseOrder(po.id);
              Navigator.pop(ctx);
              context.go(AppRoutes.purchaseOrders);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showZoomedReceipt(BuildContext context, String base64Image) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                child: Image.memory(
                  base64Decode(base64Image.contains(',') ? base64Image.split(',').last : base64Image),
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final asyncPos = ref.watch(purchaseOrderNotifierProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return asyncPos.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: DashboardAppBar(email: authState.userEmail, showBackButton: true),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: DashboardAppBar(email: authState.userEmail, showBackButton: true),
        body: Center(child: Text('Error loading expense: $err')),
      ),
      data: (pos) {
        final po = pos.cast<PurchaseOrderModel?>().firstWhere((p) => p?.id == expenseId, orElse: () => null);
        if (po == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: DashboardAppBar(email: authState.userEmail, showBackButton: true),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 64, color: AppColors.textHint),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Expense not found.',
                    style: AppTextStyles.h2.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: () => context.go(AppRoutes.purchaseOrders),
                    child: const Text('Back to Expenses'),
                  ),
                ],
              ),
            ),
          );
        }

        final isPaid = po.status == POStatus.payed;
        final subtotal = po.items.fold(0.0, (sum, item) => sum + item.lineTotal);

        final actionButtons = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: () => ref.read(purchaseOrderNotifierProvider.notifier).toggleStatus(po.id),
              style: FilledButton.styleFrom(
                backgroundColor: isPaid ? AppColors.warning : AppColors.success,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md)),
              ),
              icon: Icon(
                isPaid ? Icons.warning_rounded : Icons.check_circle_rounded,
                size: 18,
                color: Colors.white,
              ),
              label: Text(
                isPaid ? 'Mark Unpaid' : 'Mark Paid',
                style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => _confirmDelete(context, ref, po),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md)),
              ),
              icon: Icon(Icons.delete_rounded, size: 18, color: AppColors.error),
              label: Text(
                'Delete',
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.error),
              ),
            ),
          ],
        );

        final leftColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Meta Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Expense Info',
                        style: AppTextStyles.sectionTitle.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isPaid ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: isPaid ? AppColors.success : AppColors.error),
                        ),
                        child: Text(
                          isPaid ? 'PAID' : 'UNPAID',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: isPaid ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildDetailRow('Reference Number:', po.poNumber),
                  _buildDetailRow('Expense Date:', DateFormat('MMMM dd, yyyy').format(po.date)),
                  _buildDetailRow('Title:', po.title),
                  if (po.description.isNotEmpty) _buildDetailRow('Description:', po.description),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Vendor details
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vendor Details',
                    style: AppTextStyles.sectionTitle.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(po.vendorName, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('ID: ${po.vendorId}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Line Items Table
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Itemized Details',
                    style: AppTextStyles.sectionTitle.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (po.items.isEmpty)
                    Text('No specific line items listed.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary))
                  else
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(5),
                        1: FlexColumnWidth(2),
                        2: FlexColumnWidth(3),
                        3: FlexColumnWidth(3),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppColors.border, width: 1.5)),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text('DESCRIPTION', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text('QTY', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text('UNIT PRICE', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text('TOTAL', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.textSecondary), textAlign: TextAlign.right),
                            ),
                          ],
                        ),
                        ...po.items.map((item) => TableRow(
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                                  child: Text(item.name, style: AppTextStyles.bodyMedium),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                                  child: Text(item.quantity.toStringAsFixed(0), style: AppTextStyles.bodyMedium),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                                  child: Text('₹${item.price.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                                  child: Text('₹${item.lineTotal.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.right),
                                ),
                              ],
                            )),
                      ],
                    ),
                ],
              ),
            ),
          ],
        );

        final rightColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial Summary',
                    style: AppTextStyles.sectionTitle.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSummaryRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSummaryRow('Associated GST', '₹${po.gstAmount.toStringAsFixed(2)}'),
                  Divider(color: AppColors.border, height: AppSpacing.lg),
                  _buildSummaryRow(
                    'Grand Total',
                    '₹${po.totalAmount.toStringAsFixed(2)}',
                    highlight: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Receipt Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Receipt Attachment',
                    style: AppTextStyles.sectionTitle.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (po.receiptImage != null && po.receiptImage!.trim().isNotEmpty)
                    GestureDetector(
                      onTap: () => _showZoomedReceipt(context, po.receiptImage!),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(AppBorderRadius.md),
                            border: Border.all(color: AppColors.border),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Image.memory(
                            base64Decode(po.receiptImage!.contains(',') ? po.receiptImage!.split(',').last : po.receiptImage!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Text(
                          'No receipt attached.',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );

        return ScreenShell(
          currentRoute: AppRoutes.purchaseOrders,
          title: po.poNumber,
          icon: Icons.account_balance_wallet_rounded,
          onBack: () => context.go(AppRoutes.purchaseOrders),
          actions: actionButtons,
          body: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: leftColumn,
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    SizedBox(
                      width: 300,
                      child: rightColumn,
                    ),
                  ],
                )
              : Column(
                  children: [
                    leftColumn,
                    const SizedBox(height: AppSpacing.lg),
                    rightColumn,
                  ],
                ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: highlight
              ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)
              : AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: highlight
              ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)
              : AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

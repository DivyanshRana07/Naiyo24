import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:naiyo24_business_tool/notifiers/purchase_order_notifier.dart';
import 'package:naiyo24_business_tool/models/purchase_order_model.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/routes/app_routes.dart';
import 'package:naiyo24_business_tool/widgets/common/empty_state_placeholder.dart';
import 'package:naiyo24_business_tool/widgets/common/export_dialog.dart';
import 'package:naiyo24_business_tool/widgets/common/loading_placeholder.dart';
import 'package:naiyo24_business_tool/widgets/common/screen_shell.dart';

class PurchaseOrdersScreen extends ConsumerStatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  ConsumerState<PurchaseOrdersScreen> createState() =>
      _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends ConsumerState<PurchaseOrdersScreen> {
  POStatus? _filterStatus;

  void _handleExport(BuildContext context, List<PurchaseOrderModel> pos) {
    final csvContent = [
      'PO Number,Date,Vendor,Title,Amount,Status',
      ...pos.map((p) =>
          '${p.poNumber},${p.date.toIso8601String().split('T')[0]},"${p.vendorName}","${p.title}",${p.totalAmount},${p.status.name}')
    ].join('\n');
    final waContent = [
      '*Naiyo24 Purchase Order Export*',
      'Total POs: ${pos.length}',
      ...pos.map((p) =>
          '- ${p.poNumber} | ${p.vendorName} | ₹${p.totalAmount} (${p.status.name.toUpperCase()})')
    ].join('\n');
    final pdfContent = [
      'Naiyo24 Business Tool - Purchase Orders Report',
      '==============================================',
      'PO Number\tDate\tVendor\tTotal\tStatus',
      ...pos.map((p) =>
          '${p.poNumber}\t${p.date.toIso8601String().split('T')[0]}\t${p.vendorName}\t₹${p.totalAmount}\t${p.status.name}')
    ].join('\n');
    showDialog(
      context: context,
      builder: (_) => ExportOptionsDialog(
        title: 'Purchase Orders',
        csvContent: csvContent,
        whatsappText: waContent,
        pdfContent: pdfContent,
        filenamePrefix: 'purchase_orders',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncPos = ref.watch(purchaseOrderNotifierProvider);

    return ScreenShell(
      currentRoute: AppRoutes.purchaseOrders,
      title: 'Purchase Orders',
      icon: Icons.shopping_bag_rounded,
      actions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton.icon(
            onPressed: () {
              final asyncPosData = ref.read(purchaseOrderNotifierProvider);
              asyncPosData.whenData((pos) {
                final filtered = _filterStatus == null
                    ? pos
                    : pos.where((p) => p.status == _filterStatus).toList();
                _handleExport(context, filtered);
              });
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.border),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md)),
            ),
            icon: Icon(Icons.download_rounded,
                size: 18, color: AppColors.textPrimary),
            label: Text('Export',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.textPrimary)),
          ),
          const SizedBox(width: AppSpacing.md),
          FilledButton.icon(
            onPressed: () => context.push(AppRoutes.newPurchaseOrder),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Purchase Order'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl, vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md)),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter chips
          Row(
            children: [
              Text('Filter by Status: ', style: AppTextStyles.bodyMedium),
              const SizedBox(width: AppSpacing.sm),
              _filterChip('All', _filterStatus == null,
                  () => setState(() => _filterStatus = null)),
              const SizedBox(width: AppSpacing.sm),
              _filterChip('Unpaid', _filterStatus == POStatus.unpayed,
                  () => setState(() => _filterStatus = POStatus.unpayed)),
              const SizedBox(width: AppSpacing.sm),
              _filterChip('Paid', _filterStatus == POStatus.payed,
                  () => setState(() => _filterStatus = POStatus.payed)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          asyncPos.when(
            loading: () => const LoadingPlaceholder(
                message: 'Loading purchase orders...'),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (pos) {
              final filteredPos = _filterStatus == null
                  ? pos
                  : pos.where((p) => p.status == _filterStatus).toList();
              final totalUnpayed = pos
                  .where((p) => p.status == POStatus.unpayed)
                  .fold(0.0, (sum, p) => sum + p.totalAmount);

              if (pos.isEmpty) {
                return EmptyStatePlaceholder(
                  icon: Icons.shopping_bag_outlined,
                  title: 'No purchase orders found',
                  message: 'Create a new purchase order to track expenses.',
                  actionLabel: 'Create PO',
                  onAction: () => context.push(AppRoutes.newPurchaseOrder),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppBorderRadius.xl),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                                minWidth: constraints.maxWidth),
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                  AppColors.surfaceVariant),
                              headingTextStyle:
                                  AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                              dividerThickness: 1,
                              dataRowMaxHeight: 64,
                              dataRowMinHeight: 64,
                              columns: const [
                                DataColumn(label: Text('PO NUMBER')),
                                DataColumn(label: Text('DATE')),
                                DataColumn(label: Text('VENDOR')),
                                DataColumn(label: Text('TOTAL AMOUNT')),
                                DataColumn(label: Text('STATUS')),
                              ],
                              rows: filteredPos.map((po) {
                                final isPayed =
                                    po.status == POStatus.payed;
                                return DataRow(cells: [
                                  DataCell(Text(po.poNumber,
                                      style: AppTextStyles.bodyMedium
                                          .copyWith(
                                              fontWeight:
                                                  FontWeight.w400))),
                                  DataCell(Text(
                                      DateFormat('MMM dd, yyyy')
                                          .format(po.date),
                                      style: AppTextStyles.bodyMedium)),
                                  DataCell(Text(po.vendorName,
                                      style: AppTextStyles.bodyMedium)),
                                  DataCell(Text(
                                      '₹${po.totalAmount.toStringAsFixed(2)}',
                                      style: AppTextStyles.bodyMedium
                                          .copyWith(
                                              fontWeight:
                                                  FontWeight.w400))),
                                  DataCell(
                                    Tooltip(
                                      message: 'Tap to toggle status',
                                      child: InkWell(
                                        onTap: () => ref
                                            .read(
                                                purchaseOrderNotifierProvider
                                                    .notifier)
                                            .toggleStatus(po.id),
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isPayed
                                                ? AppColors.success
                                                    .withValues(alpha: 0.1)
                                                : AppColors.error
                                                    .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(100),
                                            border: Border.all(
                                              color: isPayed
                                                  ? AppColors.success
                                                  : AppColors.error,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isPayed
                                                    ? Icons
                                                        .check_circle_rounded
                                                    : Icons.warning_rounded,
                                                size: 14,
                                                color: isPayed
                                                    ? AppColors.success
                                                    : AppColors.error,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                isPayed ? 'Paid' : 'Unpaid',
                                                style: AppTextStyles
                                                    .labelLarge
                                                    .copyWith(
                                                  color: isPayed
                                                      ? AppColors.success
                                                      : AppColors.error,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ]);
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  // Unpaid balance banner
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      gradient: AppGradients.primaryButton,
                      borderRadius:
                          BorderRadius.circular(AppBorderRadius.xl),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color:
                                Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 32),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Unpaid Balance',
                                style: AppTextStyles.labelLarge.copyWith(
                                    color: Colors.white
                                        .withValues(alpha: 0.8))),
                            const SizedBox(height: 4),
                            Text(
                              '₹${totalUnpayed.toStringAsFixed(2)}',
                              style: AppTextStyles.h1.copyWith(
                                  color: Colors.white, fontSize: 32),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.1),
      labelStyle: AppTextStyles.labelLarge.copyWith(
        color: selected ? AppColors.primary : AppColors.textSecondary,
        fontSize: 13,
      ),
      side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border),
      backgroundColor: AppColors.surface,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 6),
    );
  }
}

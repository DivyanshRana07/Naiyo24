import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:naiyo24_business_tool/routes/app_routes.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/models/quotation_model.dart';
import 'package:naiyo24_business_tool/notifiers/quotation_notifier.dart';
import 'package:naiyo24_business_tool/widgets/common/empty_state_placeholder.dart';
import 'package:naiyo24_business_tool/widgets/common/export_dialog.dart';
import 'package:naiyo24_business_tool/widgets/common/loading_placeholder.dart';
import 'package:naiyo24_business_tool/widgets/common/screen_shell.dart';
import 'package:naiyo24_business_tool/widgets/invoice/send_options_dialog.dart';
import 'package:naiyo24_business_tool/api_services/services/quotation_services.dart';
import 'package:naiyo24_business_tool/utils/export_helper.dart';

class QuotationsScreen extends ConsumerStatefulWidget {
  const QuotationsScreen({super.key});

  @override
  ConsumerState<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends ConsumerState<QuotationsScreen> {
  String _searchQuery = '';

  Color _getStatusColor(QuotationStatus status) => switch (status) {
        QuotationStatus.accepted => const Color(0xFF10B981),
        QuotationStatus.rejected => const Color(0xFFEF4444),
        QuotationStatus.sent => const Color(0xFF06B6D4),
        QuotationStatus.viewed => const Color(0xFF8B5CF6),
        QuotationStatus.expired => const Color(0xFFF59E0B),
        QuotationStatus.draft => AppColors.textSecondary,
      };

  String _getStatusLabel(QuotationStatus status) => switch (status) {
        QuotationStatus.accepted => 'Accepted',
        QuotationStatus.rejected => 'Rejected',
        QuotationStatus.sent => 'Sent',
        QuotationStatus.viewed => 'Viewed',
        QuotationStatus.expired => 'Expired',
        QuotationStatus.draft => 'Draft',
      };

  void _showSendOptionsDialog(BuildContext context, QuotationModel q) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final fmtDate = DateFormat('dd MMM yyyy');
    showDialog(
      context: context,
      builder: (_) => SendOptionsDialog(
        title: 'Quotation',
        invoiceId: q.id.toString(),  // Pass the quotation ID
        invoiceNo: q.quotationNo,     // Pass the quotation number
        whatsappText: [
          '*Naiyo24 Quotation*',
          'Quotation No: ${q.quotationNo}',
          'Client: ${q.customerName}',
          'Amount: ${fmt.format(q.grandTotal)}',
        ].join('\n'),
        pdfContent: [
          'Naiyo24 Business Tool - Quotation',
          '========================================',
          'Quotation No: ${q.quotationNo}',
          'Client: ${q.customerName}',
          'Date: ${fmtDate.format(q.quotationDate)}',
          'Amount: ${fmt.format(q.grandTotal)}',
        ].join('\n'),
        filenamePrefix: 'quotation_${q.quotationNo}',
        onClose: () {},
      ),
    );
  }

  void _showStatusUpdateDialog(BuildContext context, QuotationModel quotation) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Update Status', style: AppTextStyles.h2),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.lg)),
        backgroundColor: AppColors.surface,
        children: QuotationStatus.values.map((status) {
          final isSelected = quotation.status == status;
          return SimpleDialogOption(
            onPressed: () {
              ref
                  .read(quotationNotifierProvider.notifier)
                  .updateQuotation(quotation.copyWith(status: status));
              Navigator.of(ctx).pop();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    _getStatusLabel(status),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w400 : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _handleExport(
      BuildContext context, List<QuotationModel> quotations) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final fmtDate = DateFormat('dd MMM yyyy');
    showDialog(
      context: context,
      builder: (_) => ExportOptionsDialog(
        title: 'Quotations',
        csvContent: [
          'Quotation No,Client,Date,Amount,Status',
          ...quotations.map((q) =>
              '${q.quotationNo},"${q.customerName}",${fmtDate.format(q.quotationDate)},"${fmt.format(q.grandTotal)}",${_getStatusLabel(q.status)}')
        ].join('\n'),
        whatsappText: [
          '*Naiyo24 Quotation Export*',
          'Total Quotations: ${quotations.length}',
          ...quotations.map((q) =>
              '- ${q.quotationNo} | ${q.customerName} | ${fmt.format(q.grandTotal)} (${_getStatusLabel(q.status)})')
        ].join('\n'),
        pdfContent: [
          'Naiyo24 Business Tool - Quotations Report',
          '========================================',
          'Quotation No\tClient\tDate\tAmount\tStatus',
          ...quotations.map((q) =>
              '${q.quotationNo}\t${q.customerName}\t${fmtDate.format(q.quotationDate)}\t${fmt.format(q.grandTotal)}\t${_getStatusLabel(q.status)}')
        ].join('\n'),
        filenamePrefix: 'quotations',
        onExportPdf: () async {
          final pdfBytes = await QuotationService.exportQuotationListPdf();
          downloadBytes(
            filename: 'Quotation-List-Export.pdf',
            bytes: pdfBytes,
            mimeType: 'application/pdf',
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncQuotations = ref.watch(quotationNotifierProvider);

    return ScreenShell(
      currentRoute: AppRoutes.quotations,
      title: 'Quotations',
      icon: Icons.description_rounded,
      actions: LayoutBuilder(
        builder: (context, constraints) {
          final isBounded = constraints.hasBoundedWidth;
          final exportBtn = OutlinedButton.icon(
            onPressed: () {
              final asyncQuotations = ref.read(quotationNotifierProvider);
              asyncQuotations.whenData((quotations) {
                final q = _searchQuery.toLowerCase();
                final filtered = quotations
                    .where((c) =>
                        c.customerName.toLowerCase().contains(q) ||
                        c.quotationNo.toLowerCase().contains(q))
                    .toList();
                _handleExport(context, filtered);
              });
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md)),
            ),
            icon: Icon(Icons.download_rounded,
                size: 18, color: AppColors.textPrimary),
            label: Text('Export',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.textPrimary)),
          );
          final newBtn = FilledButton.icon(
            onPressed: () => context.push(AppRoutes.newQuotation),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md)),
            ),
            icon: Icon(Icons.add_rounded,
                size: 18, color: AppColors.textOnPrimary),
            label: Text('New Quotation',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.textOnPrimary)),
          );
          if (isBounded) {
            return Row(children: [
              Expanded(child: exportBtn),
              const SizedBox(width: 8),
              Expanded(child: newBtn),
            ]);
          }
          return Row(mainAxisSize: MainAxisSize.min, children: [
            exportBtn,
            const SizedBox(width: AppSpacing.md),
            newBtn,
          ]);
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilterBar(),
          const SizedBox(height: AppSpacing.lg),
          asyncQuotations.when(
            loading: () => const LoadingPlaceholder(
                message: 'Loading quotations...'),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (data) {
              final filtered = data.where((q) {
                final query = _searchQuery.toLowerCase();
                return q.customerName.toLowerCase().contains(query) ||
                    q.quotationNo.toLowerCase().contains(query);
              }).toList();
              return _buildQuotationsTable(context, filtered);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border:
            Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText:
                    'Search by client name or quotation number...',
                hintStyle: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textHint),
                prefixIcon: Icon(Icons.search_rounded,
                    size: 22, color: AppColors.textSecondary),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 16, horizontal: 16),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          Container(
            height: 32,
            width: 1,
            color: AppColors.border,
            margin:
                const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Advanced filtering coming soon')),
              ),
              icon: const Icon(Icons.filter_list_rounded, size: 20),
              label: Text('Filter', style: AppTextStyles.labelLarge),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppBorderRadius.sm),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotationsTable(
      BuildContext context, List<QuotationModel> quotations) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final fmtDate = DateFormat('dd MMM yyyy');

    if (quotations.isEmpty) {
      return EmptyStatePlaceholder(
        icon: Icons.description_outlined,
        title: 'No quotations found',
        message: _searchQuery.isNotEmpty
            ? 'No quotations matched your search.'
            : 'No quotations yet.\nTap "Create Quotation" to get started.',
        actionLabel: 'Create Quotation',
        onAction: () => context.push(AppRoutes.newQuotation),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(AppColors.surfaceVariant),
                headingTextStyle: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
                dataRowMinHeight: 60,
                dataRowMaxHeight: 60,
                columnSpacing: 40,
                columns: const [
                  DataColumn(label: Text('QUOTATION ID')),
                  DataColumn(label: Text('CLIENT')),
                  DataColumn(label: Text('DATE')),
                  DataColumn(label: Text('AMOUNT')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: quotations.map((q) {
                  final statusLabel = _getStatusLabel(q.status);
                  final statusColor = _getStatusColor(q.status);
                  return DataRow(cells: [
                    DataCell(Text(q.quotationNo,
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w400))),
                    DataCell(Text(q.customerName,
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w400))),
                    DataCell(Text(fmtDate.format(q.quotationDate),
                        style: AppTextStyles.caption)),
                    DataCell(Text(fmt.format(q.grandTotal),
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w400))),
                    DataCell(_buildStatusBadge(statusLabel, statusColor)),
                    DataCell(Row(children: [
                      Tooltip(
                        message: 'View',
                        child: InkWell(
                          onTap: () =>
                              context.push(AppRoutes.quotationDetailPath(q.id)),
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.sm),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.visibility_rounded,
                                size: 18, color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Tooltip(
                        message: 'Change Status',
                        child: InkWell(
                          onTap: () =>
                              _showStatusUpdateDialog(context, q),
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.sm),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.edit_outlined,
                                size: 18, color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Tooltip(
                        message: 'Send Quotation',
                        child: InkWell(
                          onTap: () =>
                              _showSendOptionsDialog(context, q),
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.sm),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.send_rounded,
                                size: 18, color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Tooltip(
                        message: 'Delete',
                        child: InkWell(
                          onTap: () => ref
                              .read(quotationNotifierProvider.notifier)
                              .deleteQuotation(q.id),
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.sm),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.delete_outline_rounded,
                                size: 18, color: AppColors.error),
                          ),
                        ),
                      ),
                    ])),
                  ]);
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium
            .copyWith(color: color, fontWeight: FontWeight.w400),
      ),
    );
  }
}

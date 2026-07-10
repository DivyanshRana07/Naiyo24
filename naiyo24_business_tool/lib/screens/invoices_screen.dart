import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:naiyo24_business_tool/models/invoice_model.dart';
import 'package:naiyo24_business_tool/notifiers/invoice_notifier.dart';
import 'package:naiyo24_business_tool/routes/app_routes.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/widgets/common/empty_state_placeholder.dart';
import 'package:naiyo24_business_tool/widgets/common/export_dialog.dart';
import 'package:naiyo24_business_tool/widgets/common/loading_placeholder.dart';
import 'package:naiyo24_business_tool/widgets/common/screen_shell.dart';
import 'package:naiyo24_business_tool/widgets/invoice/invoice_status_badge.dart';
import 'package:naiyo24_business_tool/widgets/invoice/send_options_dialog.dart';

final asyncInvoicesProvider = FutureProvider.autoDispose((ref) async {
  final data = ref.watch(invoiceNotifierProvider);
  return data;
});

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  final _searchCtrl = TextEditingController();
  InvoiceStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _handleExport(BuildContext context, List<InvoiceModel> invoices) {
    final csvContent = [
      'Invoice No,Date,Client,Subtotal,Tax,Total,Status',
      ...invoices.map((inv) =>
          '${inv.invoiceNo},${inv.invoiceDate},"${inv.customerName}",${inv.subTotal},${inv.totalGst},${inv.grandTotal},${inv.status.name}')
    ].join('\n');
    final waContent = [
      '*Naiyo24 Invoice Export*',
      'Total Invoices: ${invoices.length}',
      ...invoices.map((inv) =>
          '- ${inv.invoiceNo} | ${inv.customerName} | ₹${inv.grandTotal} (${inv.status.name.toUpperCase()})')
    ].join('\n');
    final pdfContent = [
      'Naiyo24 Business Tool - Invoices Report',
      '======================================',
      'Invoice No\tDate\tClient\tTotal\tStatus',
      ...invoices.map((inv) =>
          '${inv.invoiceNo}\t${inv.invoiceDate}\t${inv.customerName}\t₹${inv.grandTotal}\t${inv.status.name}')
    ].join('\n');
    showDialog(
      context: context,
      builder: (_) => ExportOptionsDialog(
        title: 'Invoices',
        csvContent: csvContent,
        whatsappText: waContent,
        pdfContent: pdfContent,
        filenamePrefix: 'invoices',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncInvoices = ref.watch(asyncInvoicesProvider);

    return ScreenShell(
      currentRoute: AppRoutes.invoices,
      title: 'Invoices',
      icon: Icons.receipt_long_rounded,
      actions: LayoutBuilder(
        builder: (context, constraints) {
          final isBounded = constraints.hasBoundedWidth;
          final exportBtn = OutlinedButton.icon(
            onPressed: () => _handleExport(
                context, ref.read(invoiceNotifierProvider)),
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
            onPressed: () => context.push(AppRoutes.newInvoice),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md)),
            ),
            icon: Icon(Icons.add_rounded,
                size: 18, color: AppColors.textOnPrimary),
            label: Text('New Invoice',
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
      body: asyncInvoices.when(
        loading: () =>
            const LoadingPlaceholder(message: 'Loading invoices...'),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (allInvoices) {
          final filtered = allInvoices.where((inv) {
            final q = _searchCtrl.text.toLowerCase();
            final matchesSearch = q.isEmpty ||
                inv.invoiceNo.toLowerCase().contains(q) ||
                inv.customerName.toLowerCase().contains(q);
            final matchesStatus =
                _filterStatus == null || inv.status == _filterStatus;
            return matchesSearch && matchesStatus;
          }).toList()
            ..sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryChips(invoices: allInvoices),
              const SizedBox(height: AppSpacing.lg),
              _filterBar(),
              const SizedBox(height: AppSpacing.lg),
              if (filtered.isEmpty)
                EmptyStatePlaceholder(
                  icon: Icons.receipt_long_outlined,
                  title: 'No invoices found',
                  message: (_searchCtrl.text.isNotEmpty ||
                          _filterStatus != null)
                      ? 'No invoices matched your search.'
                      : 'No invoices yet.\nTap "Create Invoice" to get started.',
                  actionLabel: 'Create Invoice',
                  onAction: () => context.push(AppRoutes.newInvoice),
                )
              else
                _InvoiceDataTable(
                    invoices: filtered, onDelete: _confirmDelete),
              if (filtered.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    'Total Invoices: ${filtered.length}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by client name or invoice number...',
              prefixIcon: Icon(Icons.search_rounded,
                  color: AppColors.textSecondary),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        DropdownButtonHideUnderline(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButton<InvoiceStatus?>(
              value: _filterStatus,
              hint: const Text('All Status'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(
                    value: InvoiceStatus.paid,
                    child: Text('Paid',
                        style: TextStyle(color: AppColors.success))),
                DropdownMenuItem(
                    value: InvoiceStatus.partial,
                    child: Text('Partial',
                        style: TextStyle(color: AppColors.warning))),
                DropdownMenuItem(
                    value: InvoiceStatus.due,
                    child: Text('Due',
                        style: TextStyle(color: AppColors.error))),
              ],
              onChanged: (v) => setState(() => _filterStatus = v),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(InvoiceModel inv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: Text(
            'Delete ${inv.invoiceNo} for ${inv.customerName}? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnPrimary,
            ),
            onPressed: () {
              ref.read(invoiceNotifierProvider.notifier).deleteInvoice(inv.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SummaryChips extends StatelessWidget {
  const _SummaryChips({required this.invoices});
  final List<InvoiceModel> invoices;

  @override
  Widget build(BuildContext context) {
    final total = invoices.fold(0.0, (s, i) => s + i.grandTotal);
    final paid = invoices.where((i) => i.status == InvoiceStatus.paid).length;
    final due = invoices
        .where((i) => i.status == InvoiceStatus.due)
        .fold(0.0, (s, i) => s + i.dueAmount);

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        _chip('Total Invoiced', '₹${total.toStringAsFixed(0)}',
            AppColors.primary, Icons.receipt_rounded),
        _chip('Paid Invoices', '$paid', AppColors.success,
            Icons.check_circle_rounded),
        _chip('Total Due', '₹${due.toStringAsFixed(0)}', AppColors.error,
            Icons.warning_rounded),
      ],
    );
  }

  Widget _chip(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text('$label: ',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
          Text(value,
              style: AppTextStyles.caption
                  .copyWith(color: color, fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }
}

class _InvoiceDataTable extends StatelessWidget {
  const _InvoiceDataTable({required this.invoices, required this.onDelete});
  final List<InvoiceModel> invoices;
  final void Function(InvoiceModel) onDelete;

  @override
  Widget build(BuildContext context) {
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
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(AppColors.surfaceVariant),
                dataRowMinHeight: 60,
                dataRowMaxHeight: 60,
                columnSpacing: 20,
                headingTextStyle: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
                columns: const [
                  DataColumn(label: Text('INVOICE NO.')),
                  DataColumn(label: Text('DATE')),
                  DataColumn(label: Text('CUSTOMER')),
                  DataColumn(label: Text('TOTAL'), numeric: true),
                  DataColumn(label: Text('PAID'), numeric: true),
                  DataColumn(label: Text('DUE'), numeric: true),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('ACTION')),
                ],
                rows: invoices.map((inv) {
                  return DataRow(cells: [
                    DataCell(Text(inv.invoiceNo,
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w400))),
                    DataCell(Text(
                      '${inv.invoiceDate.day.toString().padLeft(2, '0')}/'
                      '${inv.invoiceDate.month.toString().padLeft(2, '0')}/'
                      '${inv.invoiceDate.year}',
                      style: AppTextStyles.caption,
                    )),
                    DataCell(Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(inv.customerName,
                            style: AppTextStyles.bodyMedium
                                .copyWith(fontWeight: FontWeight.w400)),
                        Text(inv.customerMobile,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    )),
                    DataCell(Text('₹${inv.grandTotal.toStringAsFixed(2)}',
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w400))),
                    DataCell(Text('₹${inv.paidAmount.toStringAsFixed(2)}',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.success))),
                    DataCell(Text('₹${inv.dueAmount.toStringAsFixed(2)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: inv.dueAmount > 0
                                ? AppColors.error
                                : AppColors.textSecondary))),
                    DataCell(InvoiceStatusBadge(status: inv.status)),
                    DataCell(Row(children: [
                      Tooltip(
                        message: 'View',
                        child: InkWell(
                          onTap: () =>
                              context.push(AppRoutes.invoiceDetailPath(inv.id)),
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
                        message: 'Send Invoice',
                        child: InkWell(
                          onTap: () => _showSendOptionsDialog(context, inv),
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
                          onTap: () => onDelete(inv),
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.sm),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.delete_rounded,
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

  void _showSendOptionsDialog(BuildContext context, InvoiceModel invoice) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    showDialog(
      context: context,
      builder: (_) => SendOptionsDialog(
        title: 'Invoice',
        whatsappText: [
          '*Naiyo24 Invoice*',
          'Invoice No: ${invoice.invoiceNo}',
          'Client: ${invoice.customerName}',
          'Amount: ${fmt.format(invoice.grandTotal)}',
        ].join('\n'),
        pdfContent: [
          'Naiyo24 Business Tool - Invoice',
          '========================================',
          'Invoice No: ${invoice.invoiceNo}',
          'Client: ${invoice.customerName}',
          'Amount: ${fmt.format(invoice.grandTotal)}',
        ].join('\n'),
        filenamePrefix: 'invoice_${invoice.invoiceNo}',
        onClose: () {},
        invoiceId: invoice.id,
        invoiceNo: invoice.invoiceNo,
      ),
    );
  }
}

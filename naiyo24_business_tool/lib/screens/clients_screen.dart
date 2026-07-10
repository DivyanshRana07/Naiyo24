import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import 'package:naiyo24_business_tool/notifiers/customer_notifier.dart';
import 'package:naiyo24_business_tool/models/customer_model.dart';
import 'package:naiyo24_business_tool/routes/app_routes.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/widgets/common/badges.dart';
import 'package:naiyo24_business_tool/widgets/common/empty_state_placeholder.dart';
import 'package:naiyo24_business_tool/widgets/common/export_dialog.dart';
import 'package:naiyo24_business_tool/widgets/common/loading_placeholder.dart';
import 'package:naiyo24_business_tool/widgets/common/screen_shell.dart';
import 'package:naiyo24_business_tool/api_services/api_routes.dart';
import 'package:naiyo24_business_tool/utils/export_helper.dart';

final asyncCustomersProvider = FutureProvider.autoDispose((ref) async {
  final data = ref.watch(customerNotifierProvider);
  return data;
});

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key, this.showAddDialog = false});
  final bool showAddDialog;

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    if (widget.showAddDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showCustomerDialog());
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _handleExport(BuildContext context, List<CustomerModel> customers) {
    final csvContent = [
      'Client Code,Name,Mobile,GST No,Credit Limit,Opening Balance,Status',
      ...customers.map((c) =>
          '${c.code},"${c.name}","${c.mobile}","${c.gstNumber ?? ""}",${c.creditLimit},${c.openingBalance},${c.status.name}')
    ].join('\n');
    final waContent = [
      '*Naiyo24 Clients Export*',
      'Total Clients: ${customers.length}',
      ...customers.map((c) => '- ${c.code} | ${c.name} | ${c.mobile}')
    ].join('\n');
    final pdfContent = [
      'Naiyo24 Business Tool - Clients Directory',
      '==========================================',
      'Code\tName\tMobile\tGST No\tCredit Limit',
      ...customers.map((c) =>
          '${c.code}\t${c.name}\t${c.mobile}\t${c.gstNumber ?? "-"}\t₹${c.creditLimit}')
    ].join('\n');
    showDialog(
      context: context,
      builder: (_) => ExportOptionsDialog(
        title: 'Clients',
        csvContent: csvContent,
        whatsappText: waContent,
        pdfContent: pdfContent,
        filenamePrefix: 'clients',
        onExportPdf: () async {
          final response = await http.get(
            Uri.parse('${ApiRoutes.baseUrl}${ApiRoutes.customerExportListPdf}'),
          );
          if (response.statusCode == 200) {
            downloadBytes(
              filename: 'Customer-List-Export.pdf',
              bytes: response.bodyBytes,
              mimeType: 'application/pdf',
            );
          } else {
            throw Exception('Failed to export customer list PDF');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncCustomers = ref.watch(asyncCustomersProvider);
    final query = _searchCtrl.text;

    return ScreenShell(
      currentRoute: AppRoutes.clients,
      title: 'Clients',
      icon: Icons.people_rounded,
      actions: LayoutBuilder(
        builder: (context, constraints) {
          final isBounded = constraints.hasBoundedWidth;
          final exportBtn = OutlinedButton.icon(
            onPressed: () => _handleExport(
                context, ref.read(customerNotifierProvider)),
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
            onPressed: () => context.push(AppRoutes.newClient),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md)),
            ),
            icon: Icon(Icons.add, size: 18, color: AppColors.textOnPrimary),
            label: Text('Add Client',
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
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by name, mobile or customer code...',
              prefixIcon:
                  Icon(Icons.search, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          asyncCustomers.when(
            loading: () =>
                const LoadingPlaceholder(message: 'Loading clients...'),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (allCustomers) {
              final customers = query.isEmpty
                  ? allCustomers
                  : ref
                      .read(customerNotifierProvider.notifier)
                      .search(query);
              if (customers.isEmpty) {
                return EmptyStatePlaceholder(
                  icon: Icons.people_outline,
                  title: 'No clients found',
                  message: query.isEmpty
                      ? 'No clients yet.\nTap "Add New Client" to add your first customer.'
                      : 'No clients matched "$query".',
                  actionLabel: 'Add New Client',
                  onAction: () => context.push(AppRoutes.newClient),
                );
              }
              return Column(
                children: [
                  _CustomerDataTable(
                    customers: customers,
                    onEdit: (c) => _showCustomerDialog(existing: c),
                    onDelete: _confirmDelete,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      'Total Customers: ${customers.length}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
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

  void _showCustomerDialog({CustomerModel? existing}) {
    context.push(AppRoutes.newClient, extra: existing);
  }

  void _confirmDelete(CustomerModel c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
            'Delete "${c.name}"? All associated invoice data will remain but the client will be removed.'),
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
              ref.read(customerNotifierProvider.notifier).deleteCustomer(c.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CustomerDataTable extends StatelessWidget {
  const _CustomerDataTable({
    required this.customers,
    required this.onEdit,
    required this.onDelete,
  });

  final List<CustomerModel> customers;
  final void Function(CustomerModel) onEdit;
  final void Function(CustomerModel) onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                dataRowMinHeight: 56,
                dataRowMaxHeight: 56,
                columnSpacing: 40,
                headingTextStyle: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
                columns: const [
                  DataColumn(label: Text('CODE')),
                  DataColumn(label: Text('CUSTOMER NAME')),
                  DataColumn(label: Text('MOBILE')),
                  DataColumn(label: Text('GST NO.')),
                  DataColumn(label: Text('CREDIT LIMIT'), numeric: true),
                  DataColumn(label: Text('OPENING BAL.'), numeric: true),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('ACTION')),
                ],
                rows: customers.map((c) {
                  return DataRow(cells: [
                    DataCell(Text(c.code,
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w400))),
                    DataCell(Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name,
                            style: AppTextStyles.bodyMedium
                                .copyWith(fontWeight: FontWeight.w400)),
                        if (c.address != null)
                          Text(c.address!,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1),
                      ],
                    )),
                    DataCell(Text(c.mobile, style: AppTextStyles.bodyMedium)),
                    DataCell(Text(c.gstNumber ?? '—',
                        style: AppTextStyles.caption)),
                    DataCell(Text('₹${c.creditLimit.toStringAsFixed(0)}',
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w400))),
                    DataCell(Text('₹${c.openingBalance.toStringAsFixed(0)}',
                        style: AppTextStyles.bodyMedium)),
                    DataCell(BadgeWidget.active(
                        isActive: c.status == CustomerStatus.active)),
                    DataCell(Row(children: [
                      ActionIcon(
                          icon: Icons.edit_rounded,
                          color: AppColors.primary,
                          tooltip: 'Edit',
                          onTap: () => onEdit(c)),
                      const SizedBox(width: 8),
                      ActionIcon(
                          icon: Icons.delete_rounded,
                          color: AppColors.error,
                          tooltip: 'Delete',
                          onTap: () => onDelete(c)),
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
}

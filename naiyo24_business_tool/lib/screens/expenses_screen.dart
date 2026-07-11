import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import 'package:naiyo24_business_tool/notifiers/expense_notifier.dart';
import 'package:naiyo24_business_tool/models/expense_model.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/routes/app_routes.dart';
import 'package:naiyo24_business_tool/widgets/common/empty_state_placeholder.dart';
import 'package:naiyo24_business_tool/widgets/common/export_dialog.dart';
import 'package:naiyo24_business_tool/widgets/common/loading_placeholder.dart';
import 'package:naiyo24_business_tool/widgets/common/screen_shell.dart';
import 'package:naiyo24_business_tool/api_services/api_routes.dart';
import 'package:naiyo24_business_tool/utils/export_helper.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() =>
      _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  ExpenseStatus? _filterStatus;

  void _handleExport(BuildContext context, List<ExpenseModel> expenses) {
    final csvContent = [
      'Ref Number,Date,Vendor,Title,Amount,Status',
      ...expenses.map((e) =>
          '${e.expenseNumber},${e.date.toIso8601String().split('T')[0]},"${e.vendorName}","${e.title}",${e.totalAmount},${e.status.name}')
    ].join('\n');
    final waContent = [
      '*Naiyo24 Expense Export*',
      'Total Expenses: ${expenses.length}',
      ...expenses.map((e) =>
          '- ${e.expenseNumber} | ${e.vendorName} | ₹${e.totalAmount} (${e.status.name.toUpperCase()})')
    ].join('\n');
    final pdfContent = [
      'Naiyo24 Business Tool - Expenses Report',
      '==============================================',
      'Ref Number\tDate\tVendor\tTotal\tStatus',
      ...expenses.map((e) =>
          '${e.expenseNumber}\t${e.date.toIso8601String().split('T')[0]}\t${e.vendorName}\t₹${e.totalAmount}\t${e.status.name}')
    ].join('\n');
    showDialog(
      context: context,
      builder: (_) => ExportOptionsDialog(
        title: 'Expenses',
        csvContent: csvContent,
        whatsappText: waContent,
        pdfContent: pdfContent,
        filenamePrefix: 'expenses',
        onExportPdf: () async {
          final response = await http.get(
            Uri.parse('${ApiRoutes.baseUrl}${ApiRoutes.expenseExportListPdf}'),
          );
          if (response.statusCode == 200) {
            downloadBytes(
              filename: 'Expense-Report-Export.pdf',
              bytes: response.bodyBytes,
              mimeType: 'application/pdf',
            );
          } else {
            throw Exception('Failed to export expense report PDF');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncExpenses = ref.watch(expenseNotifierProvider);

    return ScreenShell(
      currentRoute: AppRoutes.expenses,
      title: 'Expenses',
      icon: Icons.account_balance_wallet_rounded,
      actions: LayoutBuilder(
        builder: (context, constraints) {
          final isBounded = constraints.hasBoundedWidth;
          final exportBtn = OutlinedButton.icon(
            onPressed: () {
              final asyncExpensesData = ref.read(expenseNotifierProvider);
              asyncExpensesData.whenData((expenses) {
                final filtered = _filterStatus == null
                    ? expenses
                    : expenses.where((e) => e.status == _filterStatus).toList();
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
            onPressed: () => context.push(AppRoutes.newExpense),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Record Expense'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md)),
            ),
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
          // Filter chips
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Filter by Status: ', style: AppTextStyles.bodyMedium),
              _filterChip('All', _filterStatus == null,
                  () => setState(() => _filterStatus = null)),
              _filterChip('Unpaid', _filterStatus == ExpenseStatus.unpaid,
                  () => setState(() => _filterStatus = ExpenseStatus.unpaid)),
              _filterChip('Paid', _filterStatus == ExpenseStatus.paid,
                  () => setState(() => _filterStatus = ExpenseStatus.paid)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          asyncExpenses.when(
            loading: () => const LoadingPlaceholder(
                message: 'Loading expenses...'),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (expenses) {
              final filteredExpenses = _filterStatus == null
                  ? expenses
                  : expenses.where((e) => e.status == _filterStatus).toList();
              final totalUnpaid = expenses
                  .where((e) => e.status == ExpenseStatus.unpaid)
                  .fold(0.0, (sum, e) => sum + e.totalAmount);

              if (expenses.isEmpty) {
                return EmptyStatePlaceholder(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'No expenses found',
                  message: 'Record a new expense to track your outgoing money.',
                  actionLabel: 'Record Expense',
                  onAction: () => context.push(AppRoutes.newExpense),
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
                                DataColumn(label: Text('REFERENCE NUMBER')),
                                DataColumn(label: Text('DATE')),
                                DataColumn(label: Text('VENDOR')),
                                DataColumn(label: Text('TOTAL AMOUNT')),
                                DataColumn(label: Text('STATUS')),
                              ],
                              rows: filteredExpenses.map((expense) {
                                final isPaid =
                                    expense.status == ExpenseStatus.paid;
                                return DataRow(cells: [
                                  DataCell(
                                    InkWell(
                                      onTap: () => context.push(
                                          AppRoutes.expenseDetailPath(expense.id)),
                                      borderRadius: BorderRadius.circular(
                                          AppBorderRadius.sm),
                                      child: Text(
                                        expense.expenseNumber,
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(
                                      DateFormat('MMM dd, yyyy')
                                          .format(expense.date),
                                      style: AppTextStyles.bodyMedium)),
                                  DataCell(Text(expense.vendorName,
                                      style: AppTextStyles.bodyMedium)),
                                  DataCell(Text(
                                      '₹${expense.totalAmount.toStringAsFixed(2)}',
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
                                                expenseNotifierProvider
                                                    .notifier)
                                            .toggleStatus(expense.id),
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isPaid
                                                ? AppColors.success
                                                    .withValues(alpha: 0.1)
                                                : AppColors.error
                                                    .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(100),
                                            border: Border.all(
                                              color: isPaid
                                                  ? AppColors.success
                                                  : AppColors.error,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isPaid
                                                    ? Icons
                                                        .check_circle_rounded
                                                    : Icons.warning_rounded,
                                                size: 14,
                                                color: isPaid
                                                    ? AppColors.success
                                                    : AppColors.error,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                isPaid ? 'Paid' : 'Unpaid',
                                                style: AppTextStyles
                                                    .labelLarge
                                                    .copyWith(
                                                  color: isPaid
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
                              '₹${totalUnpaid.toStringAsFixed(2)}',
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

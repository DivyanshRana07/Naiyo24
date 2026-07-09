import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:naiyo24_business_tool/notifiers/vendor_notifier.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/routes/app_routes.dart';
import 'package:naiyo24_business_tool/widgets/common/badges.dart';
import 'package:naiyo24_business_tool/widgets/common/empty_state_placeholder.dart';
import 'package:naiyo24_business_tool/widgets/common/export_dialog.dart';
import 'package:naiyo24_business_tool/widgets/common/screen_shell.dart';
import 'package:naiyo24_business_tool/widgets/common/skeleton_list_loader.dart';

class VendorsScreen extends ConsumerWidget {
  const VendorsScreen({super.key});

  void _handleExport(BuildContext context, List<dynamic> vendors) {
    final csvContent = [
      'Vendor ID,Name,Email,Phone,Address',
      ...vendors.map((v) =>
          '${v.id},"${v.name}","${v.email}","${v.phone}","${v.address ?? ""}"')
    ].join('\n');
    final waContent = [
      '*Naiyo24 Vendors Export*',
      'Total Vendors: ${vendors.length}',
      ...vendors.map((v) => '- ${v.id} | ${v.name} | ${v.phone}')
    ].join('\n');
    final pdfContent = [
      'Naiyo24 Business Tool - Vendors Directory',
      '==========================================',
      'ID\tName\tEmail\tPhone',
      ...vendors.map((v) => '${v.id}\t${v.name}\t${v.email}\t${v.phone}')
    ].join('\n');
    showDialog(
      context: context,
      builder: (_) => ExportOptionsDialog(
        title: 'Vendors',
        csvContent: csvContent,
        whatsappText: waContent,
        pdfContent: pdfContent,
        filenamePrefix: 'vendors',
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncVendors = ref.watch(vendorNotifierProvider);

    return ScreenShell(
      currentRoute: AppRoutes.vendors,
      title: 'Manage Vendors',
      icon: Icons.store_rounded,
      actions: asyncVendors.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (vendors) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: () => _handleExport(context, vendors),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.border),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
              ),
              icon: Icon(Icons.download_rounded,
                  size: 18, color: AppColors.textPrimary),
              label: Text('Export',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.textPrimary)),
            ),
            const SizedBox(width: AppSpacing.md),
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.newVendor),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add New Vendor'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl, vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
            ),
          ),
        ],
        ),
      ),
      body: ref.watch(vendorNotifierProvider).when(
        loading: () => const SkeletonListLoader(),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (vendorsList) {
          if (vendorsList.isEmpty) {
            return EmptyStatePlaceholder(
              icon: Icons.store_outlined,
              title: 'No vendors added yet',
              message:
                  'Add your first vendor to start creating purchase orders.',
              actionLabel: 'Add New Vendor',
              onAction: () => context.push(AppRoutes.newVendor),
            );
          }
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppBorderRadius.xl),
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
                      dividerThickness: 1,
                      dataRowMaxHeight: 64,
                      dataRowMinHeight: 64,
                      columns: const [
                        DataColumn(label: Text('VENDOR NAME')),
                        DataColumn(label: Text('CONTACT PERSON')),
                        DataColumn(label: Text('EMAIL')),
                        DataColumn(label: Text('PHONE')),
                        DataColumn(label: Text('ACTIONS')),
                      ],
                      rows: vendorsList.map((vendor) {
                        return DataRow(cells: [
                          DataCell(Row(children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              child: Text(
                                vendor.name.isNotEmpty
                                    ? vendor.name[0].toUpperCase()
                                    : 'V',
                                style: AppTextStyles.labelLarge
                                    .copyWith(color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(vendor.name,
                                style: AppTextStyles.bodyMedium
                                    .copyWith(fontWeight: FontWeight.w400)),
                          ])),
                          DataCell(Text(
                              vendor.contactPerson.isEmpty
                                  ? '-'
                                  : vendor.contactPerson,
                              style: AppTextStyles.bodyMedium)),
                          DataCell(Text(
                              vendor.email.isEmpty ? '-' : vendor.email,
                              style: AppTextStyles.bodyMedium)),
                          DataCell(Text(
                              vendor.phone.isEmpty ? '-' : vendor.phone,
                              style: AppTextStyles.bodyMedium)),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ActionIcon(
                                icon: Icons.edit_outlined,
                                color: AppColors.textSecondary,
                                tooltip: 'Edit',
                                onTap: () => context.push(
                                  AppRoutes.newVendor,
                                  extra: vendor,
                                ),
                              ),
                              ActionIcon(
                                icon: Icons.delete_outline_rounded,
                                color: AppColors.error,
                                tooltip: 'Delete',
                                onTap: () => ref
                                    .read(vendorNotifierProvider.notifier)
                                    .deleteVendor(vendor.id),
                              ),
                            ],
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

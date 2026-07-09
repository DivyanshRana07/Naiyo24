import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:naiyo24_business_tool/models/item_model.dart';
import 'package:naiyo24_business_tool/models/service_model.dart';
import 'package:naiyo24_business_tool/notifiers/item_notifier.dart';
import 'package:naiyo24_business_tool/notifiers/service_notifier.dart';
import 'package:naiyo24_business_tool/routes/app_routes.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/widgets/common/badges.dart';
import 'package:naiyo24_business_tool/widgets/common/empty_state_placeholder.dart';
import 'package:naiyo24_business_tool/widgets/common/loading_placeholder.dart';

final asyncItemsProvider = FutureProvider.autoDispose((ref) async {
  final data = ref.watch(itemNotifierProvider);
  return data;
});

final asyncServicesProvider = FutureProvider.autoDispose((ref) async {
  final data = ref.watch(serviceNotifierProvider);
  return data;
});

class ItemTabContent extends ConsumerStatefulWidget {
  const ItemTabContent({
    super.key,
    required this.searchController,
    required this.onEdit,
  });

  final TextEditingController searchController;
  final void Function({ItemModel? existing}) onEdit;

  @override
  ConsumerState<ItemTabContent> createState() => _ItemTabContentState();
}

class _ItemTabContentState extends ConsumerState<ItemTabContent> {
  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final asyncItems = ref.watch(asyncItemsProvider);
    final query = widget.searchController.text;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          TextField(
            controller: widget.searchController,
            decoration: InputDecoration(
              hintText: 'Search by item name or code...',
              prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: asyncItems.when(
              loading: () =>
                  const LoadingPlaceholder(message: 'Loading items...'),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (all) {
                final items = query.isEmpty
                    ? all
                    : ref.read(itemNotifierProvider.notifier).search(query);

                if (items.isEmpty) {
                  return EmptyStatePlaceholder(
                    icon: Icons.inventory_2_outlined,
                    title: 'No items found',
                    message: query.isEmpty
                        ? 'No items yet.\nTap "Add New Item" to get started.'
                        : 'No items matched "$query".',
                    actionLabel: 'Add New Item',
                    onAction: () => context.push(AppRoutes.newItem),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: ItemDataTable(
                        items: items,
                        onEdit: (p) => widget.onEdit(existing: p),
                        onDelete: (p) => confirmDeleteDialog(
                          context,
                          name: p.name,
                          onConfirm: () => ref
                              .read(itemNotifierProvider.notifier)
                              .deleteItem(p.id),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Total Items: ${items.length}',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ItemDataTable extends StatelessWidget {
  const ItemDataTable({
    super.key,
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ItemModel> items;
  final void Function(ItemModel) onEdit;
  final void Function(ItemModel) onDelete;

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
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 52,
                  columnSpacing: 40,
                  headingTextStyle: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                  columns: const [
                    DataColumn(label: Text('CODE')),
                    DataColumn(label: Text('ITEM NAME')),
                    DataColumn(label: Text('UNIT')),
                    DataColumn(label: Text('SALE PRICE'), numeric: true),
                    DataColumn(label: Text('PURCHASE PRICE'), numeric: true),
                    DataColumn(label: Text('STOCK'), numeric: true),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('ACTION')),
                  ],
                  rows: items
                      .map(
                        (p) => DataRow(cells: [
                          DataCell(Text(p.code,
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w400))),
                          DataCell(Text(p.name,
                              style: AppTextStyles.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w400))),
                          DataCell(Text(p.unit, style: AppTextStyles.caption)),
                          DataCell(Text('₹${p.sellingPrice.toStringAsFixed(2)}',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w400))),
                          DataCell(Text('₹${p.purchasePrice.toStringAsFixed(2)}',
                              style: AppTextStyles.bodyMedium)),
                          DataCell(StockBadge(stock: p.stockQty)),
                          DataCell(BadgeWidget.active(isActive: p.status == ItemStatus.active)),
                          DataCell(Row(children: [
                            ActionIcon(
                                icon: Icons.edit_rounded,
                                color: AppColors.primary,
                                tooltip: 'Edit',
                                onTap: () => onEdit(p)),
                            const SizedBox(width: 8),
                            ActionIcon(
                                icon: Icons.delete_rounded,
                                color: AppColors.error,
                                tooltip: 'Delete',
                                onTap: () => onDelete(p)),
                          ])),
                        ]),
                      )
                      .toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ServiceTabContent extends ConsumerStatefulWidget {
  const ServiceTabContent({
    super.key,
    required this.searchController,
    required this.onEdit,
  });

  final TextEditingController searchController;
  final void Function({ServiceModel? existing}) onEdit;

  @override
  ConsumerState<ServiceTabContent> createState() => _ServiceTabContentState();
}

class _ServiceTabContentState extends ConsumerState<ServiceTabContent> {
  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final asyncServices = ref.watch(asyncServicesProvider);
    final query = widget.searchController.text;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          TextField(
            controller: widget.searchController,
            decoration: InputDecoration(
              hintText: 'Search by service name or code...',
              prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: asyncServices.when(
              loading: () =>
                  const LoadingPlaceholder(message: 'Loading services...'),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (all) {
                final services = query.isEmpty
                    ? all
                    : ref.read(serviceNotifierProvider.notifier).search(query);

                if (services.isEmpty) {
                  return EmptyStatePlaceholder(
                    icon: Icons.miscellaneous_services_outlined,
                    title: 'No services found',
                    message: query.isEmpty
                        ? 'No services yet.\nTap "Add New Service" to get started.'
                        : 'No services matched "$query".',
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: ServiceDataTable(
                        services: services,
                        onEdit: (s) => widget.onEdit(existing: s),
                        onDelete: (s) => confirmDeleteDialog(
                          context,
                          name: s.name,
                          onConfirm: () => ref
                              .read(serviceNotifierProvider.notifier)
                              .deleteService(s.id),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Total Services: ${services.length}',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceDataTable extends StatelessWidget {
  const ServiceDataTable({
    super.key,
    required this.services,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ServiceModel> services;
  final void Function(ServiceModel) onEdit;
  final void Function(ServiceModel) onDelete;

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
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 52,
                  columnSpacing: 40,
                  headingTextStyle: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                  columns: const [
                    DataColumn(label: Text('CODE')),
                    DataColumn(label: Text('SERVICE NAME')),
                    DataColumn(label: Text('CATEGORY')),
                    DataColumn(label: Text('PRICE'), numeric: true),
                    DataColumn(label: Text('GST %'), numeric: true),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('ACTION')),
                  ],
                  rows: services
                      .map(
                        (s) => DataRow(cells: [
                          DataCell(Text(s.code,
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w400))),
                          DataCell(Text(s.name,
                              style: AppTextStyles.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w400))),
                          DataCell(Text(s.category, style: AppTextStyles.caption)),
                          DataCell(Text('₹${s.sellingPrice.toStringAsFixed(2)}',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w400))),
                          DataCell(Text('${s.gstPercent.toStringAsFixed(0)}%',
                              style: AppTextStyles.caption)),
                          DataCell(BadgeWidget.active(isActive: s.status == ServiceStatus.active)),
                          DataCell(Row(children: [
                            ActionIcon(
                                icon: Icons.edit_rounded,
                                color: AppColors.primary,
                                tooltip: 'Edit',
                                onTap: () => onEdit(s)),
                            const SizedBox(width: 8),
                            ActionIcon(
                                icon: Icons.delete_rounded,
                                color: AppColors.error,
                                tooltip: 'Delete',
                                onTap: () => onDelete(s)),
                          ])),
                        ]),
                      )
                      .toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

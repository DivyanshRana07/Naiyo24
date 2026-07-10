import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import 'package:naiyo24_business_tool/notifiers/auth_notifier.dart';
import 'package:naiyo24_business_tool/notifiers/item_notifier.dart';
import 'package:naiyo24_business_tool/notifiers/service_notifier.dart';
import 'package:naiyo24_business_tool/models/item_model.dart';
import 'package:naiyo24_business_tool/models/service_model.dart';
import 'package:naiyo24_business_tool/routes/app_routes.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/widgets/common/side_navigation.dart';
import 'package:naiyo24_business_tool/widgets/common/dashboard_app_bar.dart';
import 'package:naiyo24_business_tool/widgets/common/export_dialog.dart';
import 'package:naiyo24_business_tool/widgets/item/item_list_widgets.dart';
import 'package:naiyo24_business_tool/api_services/api_routes.dart';
import 'package:naiyo24_business_tool/utils/export_helper.dart';

class ItemsScreen extends ConsumerStatefulWidget {
  const ItemsScreen({super.key});

  @override
  ConsumerState<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends ConsumerState<ItemsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _itemSearch = TextEditingController();
  final _serviceSearch = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _itemSearch.dispose();
    _serviceSearch.dispose();
    super.dispose();
  }

  void _handleExportItems(
      BuildContext context, List<ItemModel> items) {
    final csvContent = [
      'Item Code,Name,Unit,Sale Price,Purchase Price,Opening Stock,Status',
      ...items.map((p) =>
          '${p.code},"${p.name}","${p.unit}",${p.sellingPrice},${p.purchasePrice},${p.stockQty},${p.status.name}')
    ].join('\n');

    final waContent = [
      '*Naiyo24 Items Export*',
      'Total Items: ${items.length}',
      ...items.map((p) =>
          '- ${p.code} | ${p.name} | Sale: ₹${p.sellingPrice} | Stock: ${p.stockQty}')
    ].join('\n');

    final pdfContent = [
      'Naiyo24 Business Tool - Items Directory',
      '==========================================',
      'Code\tName\tUnit\tSale Price\tStock',
      ...items.map((p) =>
          '${p.code}\t${p.name}\t${p.unit}\t₹${p.sellingPrice}\t${p.stockQty}')
    ].join('\n');

    showDialog(
      context: context,
      builder: (_) => ExportOptionsDialog(
        title: 'Items',
        csvContent: csvContent,
        whatsappText: waContent,
        pdfContent: pdfContent,
        filenamePrefix: 'items',
        onExportPdf: () async {
          final response = await http.get(
            Uri.parse('${ApiRoutes.baseUrl}${ApiRoutes.itemExportListPdf}'),
          );
          if (response.statusCode == 200) {
            downloadBytes(
              filename: 'Item-List-Export.pdf',
              bytes: response.bodyBytes,
              mimeType: 'application/pdf',
            );
          } else {
            throw Exception('Failed to export item list PDF');
          }
        },
      ),
    );
  }

  void _handleExportServices(
      BuildContext context, List<ServiceModel> services) {
    final csvContent = [
      'Service Code,Name,Category,Price,GST %,Status',
      ...services.map((s) =>
          '${s.code},"${s.name}","${s.category}",${s.sellingPrice},${s.gstPercent},${s.status.name}')
    ].join('\n');

    final waContent = [
      '*Naiyo24 Services Export*',
      'Total Services: ${services.length}',
      ...services.map((s) =>
          '- ${s.code} | ${s.name} | Price: ₹${s.sellingPrice} | GST: ${s.gstPercent}%')
    ].join('\n');

    final pdfContent = [
      'Naiyo24 Business Tool - Services Directory',
      '==========================================',
      'Code\tName\tCategory\tPrice\tGST',
      ...services.map((s) =>
          '${s.code}\t${s.name}\t${s.category}\t₹${s.sellingPrice}\t${s.gstPercent}%')
    ].join('\n');

    showDialog(
      context: context,
      builder: (_) => ExportOptionsDialog(
        title: 'Services',
        csvContent: csvContent,
        whatsappText: waContent,
        pdfContent: pdfContent,
        filenamePrefix: 'services',
        onExportPdf: () async {
          final response = await http.get(
            Uri.parse('${ApiRoutes.baseUrl}${ApiRoutes.serviceExportListPdf}'),
          );
          if (response.statusCode == 200) {
            downloadBytes(
              filename: 'Service-List-Export.pdf',
              bytes: response.bodyBytes,
              mimeType: 'application/pdf',
            );
          } else {
            throw Exception('Failed to export service list PDF');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isMedium = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DashboardAppBar(email: authState.userEmail),
      drawer: !isMedium
          ? Drawer(
              child: SideNavigation(
                email: authState.userEmail,
                onLogout: () =>
                    ref.read(authNotifierProvider.notifier).logout(),
                currentRoute: AppRoutes.items,
              ),
            )
          : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMedium)
            SideNavigation(
              email: authState.userEmail,
              onLogout: () => ref.read(authNotifierProvider.notifier).logout(),
              currentRoute: AppRoutes.items,
            ),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1400),
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: [
                  Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 600;

                        final titleRow = Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_rounded,
                                color: AppColors.primary, size: 28),
                            const SizedBox(width: AppSpacing.sm),
                            Flexible(
                              child: Text(
                                'Inventory & Catalog',
                                style: AppTextStyles.h1,
                              ),
                            ),
                          ],
                        );

                        final exportBtn = IconButton(
                          icon: const Icon(Icons.download_rounded),
                          tooltip: 'Export',
                          onPressed: () {
                            if (_tabController.index == 0) {
                              final items = ref.read(itemNotifierProvider);
                              _handleExportItems(context, items);
                            } else {
                              final services =
                                  ref.read(serviceNotifierProvider);
                              _handleExportServices(context, services);
                            }
                          },
                        );

                        final addBtn = FilledButton.icon(
                          onPressed: () {
                            if (_tabController.index == 0) {
                              _showItemDialog();
                            } else {
                              _showServiceDialog();
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppBorderRadius.md),
                            ),
                          ),
                          icon: Icon(Icons.add,
                              size: 18, color: AppColors.textOnPrimary),
                          label: Text(
                            _tabController.index == 0
                                ? 'Add Item'
                                : 'Add Service',
                            style: AppTextStyles.labelLarge
                                .copyWith(color: AppColors.textOnPrimary),
                          ),
                        );

                        if (isWide) {
                          // Web: title left, buttons right — same as ScreenShell
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(child: titleRow),
                              const SizedBox(width: AppSpacing.md),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  exportBtn,
                                  const SizedBox(width: AppSpacing.sm),
                                  addBtn,
                                ],
                              ),
                            ],
                          );
                        }

                        // Phone: title on top, full-width equal buttons below
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            titleRow,
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                exportBtn,
                                const SizedBox(width: 8),
                                Expanded(child: addBtn),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Container(
                    color: AppColors.surface,
                    alignment: Alignment.centerLeft,
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelStyle: AppTextStyles.labelLarge
                          .copyWith(fontWeight: FontWeight.w400),
                      unselectedLabelStyle: AppTextStyles.labelLarge
                          .copyWith(fontWeight: FontWeight.w400),
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      dividerColor: AppColors.border,
                      tabs: const [
                        Tab(text: 'Items'),
                        Tab(text: 'Services'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        ItemTabContent(
                          searchController: _itemSearch,
                          onEdit: _showItemDialog,
                        ),
                        ServiceTabContent(
                          searchController: _serviceSearch,
                          onEdit: _showServiceDialog,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showItemDialog({ItemModel? existing}) {
    context.push(AppRoutes.newItem, extra: existing);
  }

  void _showServiceDialog({ServiceModel? existing}) {
    context.push(AppRoutes.newService, extra: existing);
  }
}

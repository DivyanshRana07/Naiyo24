import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/routes/app_routes.dart';
import 'package:naiyo24_business_tool/widgets/common/side_navigation_tiles.dart';
import 'package:naiyo24_business_tool/providers/sidebar_provider.dart';

class SideNavigation extends ConsumerStatefulWidget {
  const SideNavigation({
    super.key,
    this.email,
    required this.onLogout,
    required this.currentRoute,
  });

  final String? email;
  final VoidCallback onLogout;
  final String currentRoute;

  @override
  ConsumerState<SideNavigation> createState() => _SideNavigationState();
}

class _SideNavigationState extends ConsumerState<SideNavigation> {
  static const List<NavItem> _topItems = [
    NavItem(
        icon: Icons.dashboard_rounded,
        label: 'Dashboard',
        route: AppRoutes.dashboard),
    NavItem(
        icon: Icons.receipt_long_rounded,
        label: 'Invoices',
        route: AppRoutes.invoices),
    NavItem(
        icon: Icons.description_rounded,
        label: 'Quotations',
        route: AppRoutes.quotations),
    NavItem(
        icon: Icons.people_outline_rounded,
        label: 'Leads',
        route: AppRoutes.leads),
  ];

  static const List<NavItem> _inventoryChildren = [
    NavItem(
        icon: Icons.people_rounded, label: 'Clients', route: AppRoutes.clients),
    NavItem(
        icon: Icons.inventory_2_rounded,
        label: 'Items',
        route: AppRoutes.items),
  ];

  static const List<NavItem> _purchasesChildren = [
    NavItem(
        icon: Icons.store_rounded,
        label: 'Manage Vendors',
        route: AppRoutes.vendors),
    NavItem(
        icon: Icons.shopping_bag_rounded,
        label: 'Expenses',
        route: AppRoutes.expenses),
  ];

  static const List<NavItem> _bottomItems = [
    NavItem(
        icon: Icons.history_rounded,
        label: 'History',
        route: AppRoutes.reports),
    NavItem(
        icon: Icons.settings_rounded,
        label: 'Settings',
        route: AppRoutes.settings),
  ];

  bool _inventoryExpanded = false;
  bool _purchasesExpanded = false;

  bool get _isInventoryActive => _inventoryChildren.any(
        (item) => widget.currentRoute == item.route,
      );

  bool get _isPurchasesActive => _purchasesChildren.any(
        (item) => widget.currentRoute == item.route,
      );

  @override
  void initState() {
    super.initState();

    _inventoryExpanded = _isInventoryActive;
    _purchasesExpanded = _isPurchasesActive;
  }

  @override
  Widget build(BuildContext context) {
    final isExpanded = ref.watch(sidebarExpandedProvider);

    if (!isExpanded && (_inventoryExpanded || _purchasesExpanded)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _inventoryExpanded = false;
            _purchasesExpanded = false;
          });
        }
      });
    }

    return MouseRegion(
      onEnter: (_) =>
          ref.read(sidebarExpandedProvider.notifier).setExpanded(true),
      onExit: (_) =>
          ref.read(sidebarExpandedProvider.notifier).setExpanded(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: isExpanded ? 260 : 70,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(right: BorderSide(color: AppColors.border, width: 1)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                children: [
                  AnimatedPadding(
                    duration: const Duration(milliseconds: 250),
                    padding: EdgeInsets.symmetric(
                      horizontal: isExpanded ? AppSpacing.md : 4.0,
                      vertical: AppSpacing.sm,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: EdgeInsets.all(isExpanded ? AppSpacing.md : 8.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      ),
                      child: Row(
                        mainAxisAlignment: isExpanded
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              (widget.email?.isNotEmpty == true)
                                  ? widget.email![0].toUpperCase()
                                  : 'D',
                              style: TextStyle(
                                color: AppColors.textOnPrimary,
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (isExpanded) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Demo User',
                                    style: AppTextStyles.labelLarge
                                        .copyWith(color: AppColors.textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    widget.email ?? '',
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ..._topItems.map((item) {
                    final selected = widget.currentRoute == item.route;
                    return NavTile(
                      item: item,
                      selected: selected,
                      isExpanded: isExpanded,
                      onTap: () {
                        if (!selected) context.go(item.route);
                      },
                    );
                  }),
                  DropdownGroupTile(
                    isExpanded: isExpanded,
                    isActive: _isInventoryActive,
                    isOpen: _inventoryExpanded,
                    label: 'Inventory',
                    icon: Icons.warehouse_rounded,
                    onTap: () {
                      if (!isExpanded) {
                        ref
                            .read(sidebarExpandedProvider.notifier)
                            .setExpanded(true);
                        setState(() {
                          _inventoryExpanded = true;
                          _purchasesExpanded = false;
                        });
                      } else {
                        setState(
                            () => _inventoryExpanded = !_inventoryExpanded);
                      }
                    },
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: (_inventoryExpanded && isExpanded)
                        ? Column(
                            children: _inventoryChildren.map((item) {
                              final selected =
                                  widget.currentRoute == item.route;
                              return DropdownChildTile(
                                item: item,
                                selected: selected,
                                onTap: () {
                                  if (!selected) context.go(item.route);
                                },
                              );
                            }).toList(),
                          )
                        : const SizedBox.shrink(),
                  ),
                  DropdownGroupTile(
                    isExpanded: isExpanded,
                    isActive: _isPurchasesActive,
                    isOpen: _purchasesExpanded,
                    label: 'Purchases & Expenses',
                    icon: Icons.account_balance_wallet_rounded,
                    onTap: () {
                      if (!isExpanded) {
                        ref
                            .read(sidebarExpandedProvider.notifier)
                            .setExpanded(true);
                        setState(() {
                          _purchasesExpanded = true;
                          _inventoryExpanded = false;
                        });
                      } else {
                        setState(
                            () => _purchasesExpanded = !_purchasesExpanded);
                      }
                    },
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: (_purchasesExpanded && isExpanded)
                        ? Column(
                            children: _purchasesChildren.map((item) {
                              final selected =
                                  widget.currentRoute == item.route;
                              return DropdownChildTile(
                                item: item,
                                selected: selected,
                                onTap: () {
                                  if (!selected) context.go(item.route);
                                },
                              );
                            }).toList(),
                          )
                        : const SizedBox.shrink(),
                  ),
                  ..._bottomItems.map((item) {
                    final selected = widget.currentRoute == item.route;
                    return NavTile(
                      item: item,
                      selected: selected,
                      isExpanded: isExpanded,
                      onTap: () {
                        if (!selected) context.go(item.route);
                      },
                    );
                  }),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.border),
            NavTile(
              item: const NavItem(
                  icon: Icons.logout_rounded, label: 'Logout', route: ''),
              selected: false,
              isExpanded: isExpanded,
              isErrorColor: true,
              onTap: widget.onLogout,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

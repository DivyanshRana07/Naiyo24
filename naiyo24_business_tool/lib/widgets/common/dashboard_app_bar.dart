import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/routes/app_routes.dart';
import 'package:naiyo24_business_tool/notifiers/auth_notifier.dart';
import 'package:naiyo24_business_tool/providers/sidebar_provider.dart';
import 'package:naiyo24_business_tool/widgets/common/logo_widget.dart';

class DashboardAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const DashboardAppBar({
    super.key,
    this.email,
    this.showBackButton = false,
    this.backRoute,
  });

  final String? email;

  final bool showBackButton;

  final String? backRoute;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.transparent,
      titleSpacing: 0,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Back',
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.maybePop(context);
                } else {
                  context.go(backRoute ?? AppRoutes.dashboard);
                }
              },
            )
          : Builder(
              builder: (innerContext) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () {
                  if (MediaQuery.of(innerContext).size.width < 900) {
                    Scaffold.of(innerContext).openDrawer();
                  } else {
                    ref.read(sidebarExpandedProvider.notifier).toggle();
                  }
                },
              ),
            ),
      title: const Padding(
        padding: EdgeInsets.only(left: AppSpacing.xs),
        child: LogoWidget(
          fontSize: 20,
          textColor: Colors.white,
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          offset: const Offset(0, 48),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          ),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surfaceVariant,
                child: Text(
                  (email?.isNotEmpty == true) ? email![0].toUpperCase() : 'D',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
          onSelected: (value) {
            if (value == 'logout') {
              ref.read(authNotifierProvider.notifier).logout();
              context.go(AppRoutes.login);
            } else if (value == 'settings') {
              context.go(AppRoutes.settings);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings_outlined,
                      size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text('Settings', style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            const PopupMenuDivider(height: 1),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout_rounded,
                      size: 20, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text(
                    'Logout',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

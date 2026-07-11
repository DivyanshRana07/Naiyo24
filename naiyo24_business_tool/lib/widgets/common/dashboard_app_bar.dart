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
    final r = context.responsive;
    
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.transparent,
      titleSpacing: 0,
      leading: showBackButton
          ? IconButton(
              icon: Icon(Icons.arrow_back_rounded, size: r.iconSize(24)),
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
                icon: Icon(Icons.menu_rounded, size: r.iconSize(24)),
                onPressed: () {
                  if (MediaQuery.of(innerContext).size.width < 900) {
                    Scaffold.of(innerContext).openDrawer();
                  } else {
                    ref.read(sidebarExpandedProvider.notifier).toggle();
                  }
                },
              ),
            ),
      title: Padding(
        padding: EdgeInsets.only(left: r.spacing(AppSpacing.xs)),
        child: LogoWidget(
          fontSize: r.fontSize(20),
          textColor: Colors.white,
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          offset: Offset(0, r.spacing(48)),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(r.borderRadius(AppBorderRadius.lg)),
          ),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Padding(
              padding: r.padding(right: AppSpacing.md),
              child: CircleAvatar(
                radius: r.spacing(18),
                backgroundColor: AppColors.surfaceVariant,
                child: Text(
                  (email?.isNotEmpty == true) ? email![0].toUpperCase() : 'D',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w400,
                    fontSize: r.fontSize(15),
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
                      size: r.iconSize(20), color: AppColors.textSecondary),
                  SizedBox(width: r.spacing(8)),
                  Text('Settings', style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: r.fontSize(14),
                  )),
                ],
              ),
            ),
            const PopupMenuDivider(height: 1),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout_rounded,
                      size: r.iconSize(20), color: AppColors.error),
                  SizedBox(width: r.spacing(8)),
                  Text(
                    'Logout',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w400,
                      fontSize: r.fontSize(14),
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

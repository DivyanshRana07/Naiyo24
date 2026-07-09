import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:naiyo24_business_tool/notifiers/auth_notifier.dart';
import 'package:naiyo24_business_tool/routes/app_routes.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/widgets/common/dashboard_app_bar.dart';
import 'package:naiyo24_business_tool/widgets/common/side_navigation.dart';

/// **Shared screen scaffold for all main dashboard screens.**
///
/// Owns the `Scaffold` → `DashboardAppBar` → responsive `SideNavigation`
/// → `Expanded(Container(maxWidth 1400))` shell that every list/detail
/// screen repeats. Callers only provide the page title, icon, actions and body.
///
/// ```dart
/// ScreenShell(
///   currentRoute: AppRoutes.clients,
///   title: 'Clients',
///   icon: Icons.people_rounded,
///   actions: FilledButton.icon(onPressed: ..., label: Text('Add')),
///   body: ClientsTable(...),
/// )
/// ```
class ScreenShell extends ConsumerWidget {
  const ScreenShell({
    super.key,
    required this.currentRoute,
    required this.title,
    required this.icon,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.scrollable = true,
    this.maxContentWidth = 1400,
    this.onBack,
    this.showBackButton = true,
  });

  /// The route this screen is active on (used to highlight the nav item).
  final String currentRoute;

  /// Page heading text (e.g. 'Clients', 'Invoices').
  final String title;

  /// Icon shown next to the heading.
  final IconData icon;

  /// Primary content below the title row.
  final Widget body;

  /// Optional action widgets (export button, add button, etc.) placed to the
  /// right of the title on wide screens or below on narrow screens.
  final Widget? actions;

  /// Optional FAB passed through to [Scaffold].
  final Widget? floatingActionButton;

  /// When false the body fills the viewport without wrapping in a
  /// [SingleChildScrollView] — useful for screens with their own scroll.
  final bool scrollable;

  /// Maximum width of the content column (default 1400).
  final double maxContentWidth;

  /// Optional callback for custom back button functionality.
  final VoidCallback? onBack;

  /// Whether to show the back button chevron.
  final bool showBackButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    void logout() {
      ref.read(authNotifierProvider.notifier).logout();
      context.go(AppRoutes.login);
    }

    final nav = SideNavigation(
      email: authState.userEmail,
      onLogout: logout,
      currentRoute: currentRoute,
    );

    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        final titleRow = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showBackButton) ...[
              // Back to dashboard chevron
              InkWell(
                onTap: onBack ??
                    () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.dashboard);
                      }
                    },
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(title, style: AppTextStyles.h1),
            ),
          ],
        );

        if (actions == null) return titleRow;

        if (isWide) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: titleRow),
              const SizedBox(width: AppSpacing.md),
              actions!,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleRow,
            const SizedBox(height: AppSpacing.md),
            actions!,
          ],
        );
      },
    );

    Widget pageContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        content,
        const SizedBox(height: AppSpacing.lg),
        body,
      ],
    );

    if (scrollable) {
      pageContent = SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: pageContent,
      );
    } else {
      pageContent = Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: pageContent,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DashboardAppBar(email: authState.userEmail),
      drawer: !isDesktop
          ? Drawer(child: nav)
          : null,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: GridBackgroundPainter(
                lineColor: AppColors.isDarkMode
                    ? const Color(0xFF2D3033)
                    : const Color(0xFFE5E7EB).withValues(alpha: 0.3),
                gridSpacing: 45,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDesktop) nav,
              Expanded(
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: pageContent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

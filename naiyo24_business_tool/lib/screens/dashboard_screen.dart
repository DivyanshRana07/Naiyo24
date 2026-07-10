import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:naiyo24_business_tool/notifiers/auth_notifier.dart';
import 'package:naiyo24_business_tool/notifiers/dashboard_notifier.dart';
import 'package:naiyo24_business_tool/models/dashboard_stats_model.dart';
import 'package:naiyo24_business_tool/routes/app_routes.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/widgets/common/chat_support_popup.dart';
import 'package:naiyo24_business_tool/widgets/common/screen_shell.dart';
import 'package:naiyo24_business_tool/widgets/dashboard/dashboard_widgets.dart';
import 'package:naiyo24_business_tool/widgets/onboarding/feature_block_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(authNotifierProvider).userEmail;
    final dashboardState = ref.watch(dashboardNotifierProvider);

    return ScreenShell(
      currentRoute: AppRoutes.dashboard,
      title: 'Dashboard',
      icon: Icons.dashboard_rounded,
      showBackButton: false,
      scrollable: false,
      actions: OutlinedButton.icon(
        onPressed: () => ref.read(dashboardNotifierProvider.notifier).refresh(),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
        ),
        icon: Icon(Icons.refresh_rounded, size: 18, color: AppColors.textPrimary),
        label: Text(
          'Refresh',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showChatSupportPopup(context),
        backgroundColor: AppColors.primary,
        icon: Icon(Icons.chat_bubble_outline_rounded,
            color: AppColors.textOnPrimary),
        label: Text('Chat Support',
            style: TextStyle(
                color: AppColors.textOnPrimary, fontWeight: FontWeight.w400)),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardNotifierProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileHeader(email: email),
              const SizedBox(height: AppSpacing.xxl),
              if (dashboardState.error != null)
                _ErrorBanner(error: dashboardState.error!),
              _StatsGrid(
                stats: dashboardState.stats,
                isLoading: dashboardState.isLoading,
              ),
              const SizedBox(height: AppSpacing.xxl),
              const _GettingStartedGrid(),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({this.email});
  final String? email;

  @override
  Widget build(BuildContext context) {
    String displayName = 'Demo User';
    if (email != null && email!.contains('@')) {
      final raw = email!.split('@').first;
      displayName = raw
          .split(RegExp(r'[._\-]'))
          .map((w) =>
              w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
    }
    const companyName = 'Naiyo24';
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'D';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 500;

        final avatarAndText = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primary,
              child: Text(
                initial,
                style: TextStyle(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w400,
                    fontSize: 26),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hello $displayName',
                    style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                        fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Welcome to $companyName!',
                    style: AppTextStyles.h2.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w400,
                        fontSize: 20),
                  ),
                ],
              ),
            ),
          ],
        );

        final button = FilledButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Demo booking coming soon'))),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: 0),
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppBorderRadius.md)),
          ),
          icon: const Icon(Icons.desktop_mac_outlined, size: 16),
          label: const Text('Book A Demo',
              style: TextStyle(
                  fontWeight: FontWeight.w400, fontSize: 13)),
        );

        if (isSmall) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                avatarAndText,
                const SizedBox(height: AppSpacing.lg),
                button,
              ]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(child: avatarAndText),
          const SizedBox(width: AppSpacing.lg),
          button,
        ]);
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Failed to load stats. Using cached data.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.stats,
    required this.isLoading,
  });

  final DashboardStatsModel stats;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    
    final statsData = [
      {
        'title': 'Total Revenue',
        'value': formatCurrency.format(stats.invoiceAmount),
        'change': '${stats.totalInvoices} invoices',
        'isPositive': true,
        'icon': Icons.currency_rupee_rounded,
        'color': AppColors.primary,
      },
      {
        'title': 'Pending Invoices',
        'value': '${stats.pendingInvoices}',
        'change': stats.pendingInvoices > 0 ? 'Needs attention' : 'All clear',
        'isPositive': stats.pendingInvoices == 0,
        'icon': Icons.receipt_rounded,
        'color': const Color(0xFFF59E0B),
      },
      {
        'title': 'Active Clients',
        'value': '${stats.activeCustomers}',
        'change': stats.newLeads > 0 ? '+${stats.newLeads} new leads' : 'No new leads',
        'isPositive': true,
        'icon': Icons.people_rounded,
        'color': const Color(0xFF22C55E),
      },
      {
        'title': 'Overdue',
        'value': formatCurrency.format(stats.overdueAmount),
        'change': '${stats.overdueCount} invoices',
        'isPositive': false,
        'icon': Icons.warning_amber_rounded,
        'color': const Color(0xFFEF4444),
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        double cardWidth;
        if (width > 1200) {
          cardWidth = (width - (AppSpacing.lg * 3)) / 4;
        } else if (width > 600) {
          cardWidth = (width - AppSpacing.lg) / 2;
        } else {
          cardWidth = width;
        }
        
        if (isLoading) {
          return Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            children: List.generate(4, (index) {
              return Container(
                width: cardWidth,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }),
          );
        }
        
        return Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.lg,
          children: statsData.map((data) {
            return Container(
              width: cardWidth,
              constraints: const BoxConstraints(minHeight: 120),
              child: StatCard(
                title: data['title'] as String,
                value: data['value'] as String,
                change: data['change'] as String,
                isPositive: data['isPositive'] as bool,
                icon: data['icon'] as IconData,
                color: data['color'] as Color,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _GettingStartedGrid extends StatelessWidget {
  const _GettingStartedGrid();

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.primary;
    final secondaryColor = AppColors.isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF374151);
    final tertiaryColor = AppColors.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563);
    final quaternaryColor = AppColors.isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF6B7280);

    final blocks = [
      _BlockData(
        icon: Icons.receipt_long_rounded,
        iconColor: primaryColor,
        title: 'Invoices',
        description:
            'Create professional GST invoices, track payment status, send reminders to clients, and download PDFs instantly.',
        actionLabel: 'Create New Invoice',
        route: AppRoutes.newInvoice,
        listRoute: AppRoutes.invoices,
      ),
      _BlockData(
        icon: Icons.description_rounded,
        iconColor: secondaryColor,
        title: 'Quotations',
        description:
            'Send accurate estimates to clients and convert approved quotations into invoices with a single click.',
        actionLabel: 'Create New Quotation',
        route: AppRoutes.newQuotation,
        listRoute: AppRoutes.quotations,
      ),
      _BlockData(
        icon: Icons.account_balance_wallet_rounded,
        iconColor: tertiaryColor,
        title: 'Expenses',
        description:
            'Record day-to-day expenses, vendor bills, and outgoing payments to keep your books accurate.',
        actionLabel: 'Record New Expense',
        route: AppRoutes.newPurchaseOrder,
        listRoute: AppRoutes.purchaseOrders,
      ),
      _BlockData(
        icon: Icons.people_rounded,
        iconColor: quaternaryColor,
        title: 'Client Management',
        description:
            'Maintain a full client directory with contact details, billing history, and outstanding balance tracking.',
        actionLabel: 'Add New Client',
        route: AppRoutes.newClient,
        listRoute: AppRoutes.clients,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Getting Started', style: AppTextStyles.h2),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            double cardWidth;
            if (width > 1200) {
              cardWidth = (width - (AppSpacing.lg * 3)) / 4;
            } else if (width > 800) {
              cardWidth = (width - (AppSpacing.lg * 2)) / 3;
            } else if (width > 500) {
              cardWidth = (width - AppSpacing.lg) / 2;
            } else {
              cardWidth = width;
            }
            return Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.lg,
              children: blocks.map((b) {
                return SizedBox(
                  width: cardWidth,
                  child: FeatureBlockCard(
                    icon: b.icon,
                    iconColor: b.iconColor,
                    title: b.title,
                    description: b.description,
                    actionLabel: b.actionLabel,
                    onAction: () => context.push(b.route),
                    onCardTap: () => context.push(b.listRoute),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _BlockData {
  const _BlockData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.route,
    required this.listRoute,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String actionLabel;
  final String route;
  final String listRoute;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import 'package:naiyo24_business_tool/notifiers/activity_notifier.dart';
import 'package:naiyo24_business_tool/notifiers/auth_notifier.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/widgets/dashboard/dashboard_widgets.dart';
import 'package:naiyo24_business_tool/widgets/common/dashboard_app_bar.dart';
import 'package:naiyo24_business_tool/widgets/common/side_navigation.dart';
import 'package:naiyo24_business_tool/widgets/common/export_dialog.dart';
import 'package:naiyo24_business_tool/routes/app_routes.dart';
import 'package:naiyo24_business_tool/api_services/api_routes.dart';
import 'package:naiyo24_business_tool/utils/export_helper.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  void _logout(WidgetRef ref, BuildContext context) {
    ref.read(authNotifierProvider.notifier).logout();
    context.go(AppRoutes.login);
  }

  void _handleExport(BuildContext context, List<dynamic> activities) {
    final csvContent = [
      'Activity,Details,Time',
      ...activities.map((a) => '"${a.title}","${a.subtitle}","${a.time}"')
    ].join('\n');

    final waContent = [
      '*Naiyo24 Recent Activity Export*',
      'Total Activities: ${activities.length}',
      ...activities.map((a) => '- ${a.title} | ${a.subtitle} | ${a.time}')
    ].join('\n');

    final pdfContent = [
      'Naiyo24 Business Tool - Recent Activity Log',
      '==========================================',
      'Activity\tDetails\tTime',
      ...activities.map((a) => '${a.title}\t${a.subtitle}\t${a.time}')
    ].join('\n');

    showDialog(
      context: context,
      builder: (_) => ExportOptionsDialog(
        title: 'Recent Activity',
        csvContent: csvContent,
        whatsappText: waContent,
        pdfContent: pdfContent,
        filenamePrefix: 'activity_log',
        onExportPdf: () async {
          final response = await http.get(
            Uri.parse('${ApiRoutes.baseUrl}${ApiRoutes.activityExportListPdf}?user_id=1'),
          );
          if (response.statusCode == 200) {
            downloadBytes(
              filename: 'Activity-Log-Export.pdf',
              bytes: response.bodyBytes,
              mimeType: 'application/pdf',
            );
          } else {
            throw Exception('Failed to export activity log PDF');
          }
        },
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, int activityId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: const Text('Are you sure you want to delete this activity log? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(activityNotifierProvider.notifier).deleteActivity(activityId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activity deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete activity: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final asyncActivities = ref.watch(activityNotifierProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DashboardAppBar(email: authState.userEmail),
      drawer: !isDesktop
          ? Drawer(
              child: SideNavigation(
                email: authState.userEmail,
                onLogout: () => _logout(ref, context),
                currentRoute: AppRoutes.reports,
              ),
            )
          : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            SideNavigation(
              email: authState.userEmail,
              onLogout: () => _logout(ref, context),
              currentRoute: AppRoutes.reports,
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => context.go(AppRoutes.dashboard),
                        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.sm),
                          ),
                          child: Icon(Icons.arrow_back_rounded,
                              size: 20, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Icon(Icons.history_rounded,
                          color: AppColors.primary, size: 28),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'History',
                              style: AppTextStyles.h1,
                            ),
                            Text(
                              'All activities completed on the platform.',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.sm,
                    children: [
                      Text(
                        'Recent Activity',
                        style: AppTextStyles.h2,
                      ),
                      asyncActivities.when(
                        data: (activities) => OutlinedButton.icon(
                          onPressed: () => _handleExport(context, activities),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppBorderRadius.md),
                            ),
                          ),
                          icon: Icon(Icons.download_rounded,
                              size: 16, color: AppColors.textPrimary),
                          label: Text('Export',
                              style: AppTextStyles.labelMedium
                                  .copyWith(color: AppColors.textPrimary)),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  asyncActivities.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xxl),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.error_outline,
                                size: 48, color: AppColors.error),
                            const SizedBox(height: AppSpacing.md),
                            Text('Error loading activities: $err',
                                style: AppTextStyles.bodyMedium),
                          ],
                        ),
                      ),
                    ),
                    data: (activities) {
                      if (activities.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.lg),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Center(
                            child: Text('No recent activity found.'),
                          ),
                        );
                      }

                      return RepaintBoundary(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.lg),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: activities.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: AppColors.border),
                            itemBuilder: (_, i) {
                              final item = activities[i];
                              return RepaintBoundary(
                                child: ActivityCard(
                                  title: item.title,
                                  subtitle: item.subtitle,
                                  time: item.time,
                                  icon: item.icon,
                                  color: item.color,
                                  activityId: item.id,
                                  onDelete: item.id != null
                                      ? () => _handleDelete(context, ref, item.id!)
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

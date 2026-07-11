import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import 'package:naiyo24_business_tool/notifiers/activity_notifier.dart';
import 'package:naiyo24_business_tool/notifiers/auth_notifier.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/theme/responsive.dart';
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
              padding: EdgeInsets.all(context.responsive.spacing(AppSpacing.xl)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => context.go(AppRoutes.dashboard),
                        borderRadius: BorderRadius.circular(context.responsive.borderRadius(AppBorderRadius.sm)),
                        child: Container(
                          padding: EdgeInsets.all(context.responsive.spacing(8)),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius:
                                BorderRadius.circular(context.responsive.borderRadius(AppBorderRadius.sm)),
                          ),
                          child: Icon(Icons.arrow_back_rounded,
                              size: context.responsive.iconSize(20), color: AppColors.textSecondary),
                        ),
                      ),
                      SizedBox(width: context.responsive.spacing(AppSpacing.md)),
                      Icon(Icons.history_rounded,
                          color: AppColors.primary, size: context.responsive.iconSize(28)),
                      SizedBox(width: context.responsive.spacing(AppSpacing.sm)),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'History',
                              style: AppTextStyles.h1.copyWith(fontSize: context.responsive.fontSize(24)),
                            ),
                            Text(
                              'All activities completed on the platform.',
                              style: AppTextStyles.bodyMedium.copyWith(fontSize: context.responsive.fontSize(14)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.responsive.spacing(AppSpacing.xxl)),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: context.responsive.spacing(AppSpacing.md),
                    runSpacing: context.responsive.spacing(AppSpacing.sm),
                    children: [
                      Text(
                        'Recent Activity',
                        style: AppTextStyles.h2.copyWith(fontSize: context.responsive.fontSize(20)),
                      ),
                      asyncActivities.when(
                        data: (activities) => OutlinedButton.icon(
                          onPressed: () => _handleExport(context, activities),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.border),
                            padding: EdgeInsets.symmetric(
                                horizontal: context.responsive.spacing(16), 
                                vertical: context.responsive.spacing(8)),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(context.responsive.borderRadius(AppBorderRadius.md)),
                            ),
                          ),
                          icon: Icon(Icons.download_rounded,
                              size: context.responsive.iconSize(16), color: AppColors.textPrimary),
                          label: Text('Export',
                              style: AppTextStyles.labelMedium
                                  .copyWith(
                                    color: AppColors.textPrimary,
                                    fontSize: context.responsive.fontSize(14),
                                  )),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  SizedBox(height: context.responsive.spacing(AppSpacing.md)),
                  asyncActivities.when(
                    loading: () => Center(
                      child: Padding(
                        padding: EdgeInsets.all(context.responsive.spacing(AppSpacing.xxl)),
                        child: const CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(context.responsive.spacing(AppSpacing.xl)),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(context.responsive.borderRadius(AppBorderRadius.lg)),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.error_outline,
                                size: context.responsive.iconSize(48), color: AppColors.error),
                            SizedBox(height: context.responsive.spacing(AppSpacing.md)),
                            Text('Error loading activities: $err',
                                style: AppTextStyles.bodyMedium.copyWith(fontSize: context.responsive.fontSize(14))),
                          ],
                        ),
                      ),
                    ),
                    data: (activities) {
                      if (activities.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(context.responsive.spacing(AppSpacing.xl)),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(context.responsive.borderRadius(AppBorderRadius.lg)),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Center(
                            child: Text('No recent activity found.', style: TextStyle(fontSize: context.responsive.fontSize(14))),
                          ),
                        );
                      }

                      return RepaintBoundary(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(context.responsive.borderRadius(AppBorderRadius.lg)),
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

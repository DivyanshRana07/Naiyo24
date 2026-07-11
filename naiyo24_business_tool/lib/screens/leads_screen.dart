import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:naiyo24_business_tool/models/lead_model.dart';
import 'package:naiyo24_business_tool/notifiers/lead_notifier.dart';
import 'package:naiyo24_business_tool/routes/app_routes.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/theme/responsive.dart';
import 'package:naiyo24_business_tool/widgets/common/screen_shell.dart';

class LeadsScreen extends ConsumerWidget {
  const LeadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leads = ref.watch(leadNotifierProvider);
    final notifier = ref.read(leadNotifierProvider.notifier);

    return ScreenShell(
      currentRoute: AppRoutes.leads,
      title: 'Lead Management',
      icon: Icons.people_outline_rounded,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.newLead),
        backgroundColor: AppColors.primary,
        icon: Icon(Icons.add, color: AppColors.textOnPrimary),
        label: Text('New Lead',
            style: TextStyle(color: AppColors.textOnPrimary, fontWeight: FontWeight.w400)),
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.loadLeads(),
        child: leads.isEmpty
            ? _buildEmptyState(context)
            : _buildPipelineView(context, leads, ref),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded,
              size: context.responsive.iconSize(80), color: AppColors.textSecondary.withValues(alpha: 0.5)),
          SizedBox(height: context.responsive.spacing(AppSpacing.lg)),
          Text('No leads yet', style: AppTextStyles.h2.copyWith(fontSize: context.responsive.fontSize(20))),
          SizedBox(height: context.responsive.spacing(AppSpacing.sm)),
          Text('Start adding leads to track your sales pipeline',
              style: AppTextStyles.bodyMedium
                  .copyWith(
                    color: AppColors.textSecondary,
                    fontSize: context.responsive.fontSize(14),
                  )),
          SizedBox(height: context.responsive.spacing(AppSpacing.xl)),
          FilledButton.icon(
            onPressed: () => context.push(AppRoutes.newLead),
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: context.responsive.spacing(16),
                vertical: context.responsive.spacing(12),
              ),
            ),
            icon: Icon(Icons.add, size: context.responsive.iconSize(18)),
            label: Text('Add Your First Lead', style: TextStyle(fontSize: context.responsive.fontSize(14))),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineView(
      BuildContext context, List<LeadModel> leads, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (isDesktop) {
      return _buildDesktopPipeline(context, leads, ref);
    } else {
      return _buildMobilePipeline(context, leads, ref);
    }
  }

  Widget _buildDesktopPipeline(
      BuildContext context, List<LeadModel> leads, WidgetRef ref) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.responsive.spacing(AppSpacing.xl)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPipelineHeader(context, leads, ref),
          SizedBox(height: context.responsive.spacing(AppSpacing.xl)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _buildPipelineColumn(
                      context, LeadStatus.newLead, leads, ref)),
              SizedBox(width: context.responsive.spacing(AppSpacing.md)),
              Expanded(
                  child: _buildPipelineColumn(
                      context, LeadStatus.contacted, leads, ref)),
              SizedBox(width: context.responsive.spacing(AppSpacing.md)),
              Expanded(
                  child: _buildPipelineColumn(
                      context, LeadStatus.qualified, leads, ref)),
              SizedBox(width: context.responsive.spacing(AppSpacing.md)),
              Expanded(
                  child: _buildPipelineColumn(
                      context, LeadStatus.converted, leads, ref)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobilePipeline(
      BuildContext context, List<LeadModel> leads, WidgetRef ref) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.responsive.spacing(AppSpacing.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPipelineHeader(context, leads, ref),
          SizedBox(height: context.responsive.spacing(AppSpacing.xl)),
          _buildPipelineColumn(context, LeadStatus.newLead, leads, ref),
          SizedBox(height: context.responsive.spacing(AppSpacing.lg)),
          _buildPipelineColumn(context, LeadStatus.contacted, leads, ref),
          SizedBox(height: context.responsive.spacing(AppSpacing.lg)),
          _buildPipelineColumn(context, LeadStatus.qualified, leads, ref),
          SizedBox(height: context.responsive.spacing(AppSpacing.lg)),
          _buildPipelineColumn(context, LeadStatus.converted, leads, ref),
        ],
      ),
    );
  }

  Widget _buildPipelineHeader(
      BuildContext context, List<LeadModel> leads, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sales Pipeline', style: AppTextStyles.h1.copyWith(fontSize: context.responsive.fontSize(24))),
              SizedBox(height: context.responsive.spacing(AppSpacing.xs)),
              Text('${leads.length} total leads',
                  style: AppTextStyles.bodyMedium
                      .copyWith(
                        color: AppColors.textSecondary,
                        fontSize: context.responsive.fontSize(14),
                      )),
            ],
          ),
        ),
        IconButton(
          onPressed: () => ref.read(leadNotifierProvider.notifier).loadLeads(),
          icon: Icon(Icons.refresh_rounded, size: context.responsive.iconSize(24)),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildPipelineColumn(BuildContext context, LeadStatus status,
      List<LeadModel> allLeads, WidgetRef ref) {
    final columnLeads = allLeads.where((l) => l.status == status).toList();

    Color getStatusColor() {
      switch (status) {
        case LeadStatus.newLead:
          return Colors.blue;
        case LeadStatus.contacted:
          return Colors.orange;
        case LeadStatus.qualified:
          return Colors.purple;
        case LeadStatus.converted:
          return Colors.green;
        case LeadStatus.lost:
          return Colors.red;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(context.responsive.borderRadius(AppBorderRadius.md)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(context.responsive.spacing(AppSpacing.md)),
            decoration: BoxDecoration(
              color: getStatusColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(context.responsive.borderRadius(AppBorderRadius.md)),
                topRight: Radius.circular(context.responsive.borderRadius(AppBorderRadius.md)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: context.responsive.spacing(8),
                  height: context.responsive.spacing(8),
                  decoration: BoxDecoration(
                    color: getStatusColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: context.responsive.spacing(AppSpacing.sm)),
                Expanded(
                  child: Text(
                    status.label,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: getStatusColor(),
                      fontWeight: FontWeight.w400,
                      fontSize: context.responsive.fontSize(14),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: context.responsive.spacing(8), 
                      vertical: context.responsive.spacing(2)),
                  decoration: BoxDecoration(
                    color: getStatusColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(context.responsive.borderRadius(12)),
                  ),
                  child: Text(
                    '${columnLeads.length}',
                    style: AppTextStyles.caption.copyWith(
                      color: getStatusColor(),
                      fontWeight: FontWeight.w400,
                      fontSize: context.responsive.fontSize(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (columnLeads.isEmpty)
            Padding(
              padding: EdgeInsets.all(context.responsive.spacing(AppSpacing.xl)),
              child: Center(
                child: Text(
                  'No leads',
                  style: AppTextStyles.bodySmall
                      .copyWith(
                        color: AppColors.textSecondary,
                        fontSize: context.responsive.fontSize(12),
                      ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.all(context.responsive.spacing(AppSpacing.sm)),
              itemCount: columnLeads.length,
              separatorBuilder: (_, __) => SizedBox(height: context.responsive.spacing(AppSpacing.sm)),
              itemBuilder: (context, index) {
                final lead = columnLeads[index];
                return _buildLeadCard(context, lead, ref);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLeadCard(BuildContext context, LeadModel lead, WidgetRef ref) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showLeadDetails(context, lead, ref),
        borderRadius: BorderRadius.circular(context.responsive.borderRadius(AppBorderRadius.sm)),
        child: Padding(
          padding: EdgeInsets.all(context.responsive.spacing(AppSpacing.md)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lead.name,
                      style: AppTextStyles.labelLarge.copyWith(fontSize: context.responsive.fontSize(14)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: context.responsive.iconSize(18)),
                    onSelected: (value) async {
                      switch (value) {
                        case 'edit':
                          _showLeadDetails(context, lead, ref);
                          break;
                        case 'convert':
                          _convertLead(context, lead, ref);
                          break;
                        case 'delete':
                          _deleteLead(context, lead, ref);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: context.responsive.iconSize(18)),
                            SizedBox(width: context.responsive.spacing(8)),
                            const Text('Edit'),
                          ],
                        ),
                      ),
                      if (lead.status != LeadStatus.converted)
                        PopupMenuItem(
                          value: 'convert',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, size: context.responsive.iconSize(18)),
                              SizedBox(width: context.responsive.spacing(8)),
                              const Text('Convert to Customer'),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: context.responsive.iconSize(18)),
                            SizedBox(width: context.responsive.spacing(8)),
                            const Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (lead.company != null) ...[
                SizedBox(height: context.responsive.spacing(4)),
                Text(
                  lead.company!,
                  style: AppTextStyles.caption
                      .copyWith(
                        color: AppColors.textSecondary,
                        fontSize: context.responsive.fontSize(12),
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (lead.phone != null) ...[
                SizedBox(height: context.responsive.spacing(4)),
                Row(
                  children: [
                    Icon(Icons.phone, size: context.responsive.iconSize(12), color: AppColors.textSecondary),
                    SizedBox(width: context.responsive.spacing(4)),
                    Expanded(
                      child: Text(
                        lead.phone!,
                        style: AppTextStyles.caption
                            .copyWith(
                              color: AppColors.textSecondary,
                              fontSize: context.responsive.fontSize(12),
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showLeadDetails(BuildContext context, LeadModel lead, WidgetRef ref) {
    // Navigate to edit screen (to be implemented)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit lead feature coming soon')),
    );
  }

  Future<void> _convertLead(
      BuildContext context, LeadModel lead, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convert to Customer'),
        content: Text('Convert "${lead.name}" to a customer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Convert'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(leadNotifierProvider.notifier)
            .convertToCustomer(lead.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${lead.name} converted to customer successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to convert lead: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteLead(
      BuildContext context, LeadModel lead, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lead'),
        content: Text('Delete "${lead.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(leadNotifierProvider.notifier).deleteLead(lead.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Lead deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete lead: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

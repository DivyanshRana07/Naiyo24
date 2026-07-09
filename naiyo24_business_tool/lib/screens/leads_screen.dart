import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:naiyo24_business_tool/models/lead_model.dart';
import 'package:naiyo24_business_tool/notifiers/lead_notifier.dart';
import 'package:naiyo24_business_tool/routes/app_routes.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
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
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Lead',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400)),
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
              size: 80, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: AppSpacing.lg),
          Text('No leads yet', style: AppTextStyles.h2),
          const SizedBox(height: AppSpacing.sm),
          Text('Start adding leads to track your sales pipeline',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: () => context.push(AppRoutes.newLead),
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Lead'),
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
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPipelineHeader(context, leads, ref),
          const SizedBox(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _buildPipelineColumn(
                      context, LeadStatus.newLead, leads, ref)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                  child: _buildPipelineColumn(
                      context, LeadStatus.contacted, leads, ref)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                  child: _buildPipelineColumn(
                      context, LeadStatus.qualified, leads, ref)),
              const SizedBox(width: AppSpacing.md),
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPipelineHeader(context, leads, ref),
          const SizedBox(height: AppSpacing.xl),
          _buildPipelineColumn(context, LeadStatus.newLead, leads, ref),
          const SizedBox(height: AppSpacing.lg),
          _buildPipelineColumn(context, LeadStatus.contacted, leads, ref),
          const SizedBox(height: AppSpacing.lg),
          _buildPipelineColumn(context, LeadStatus.qualified, leads, ref),
          const SizedBox(height: AppSpacing.lg),
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
              Text('Sales Pipeline', style: AppTextStyles.h1),
              const SizedBox(height: AppSpacing.xs),
              Text('${leads.length} total leads',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
        IconButton(
          onPressed: () => ref.read(leadNotifierProvider.notifier).loadLeads(),
          icon: const Icon(Icons.refresh_rounded),
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
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: getStatusColor().withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppBorderRadius.md),
                topRight: Radius.circular(AppBorderRadius.md),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: getStatusColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    status.label,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: getStatusColor(),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: getStatusColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${columnLeads.length}',
                    style: AppTextStyles.caption.copyWith(
                      color: getStatusColor(),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (columnLeads.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: Text(
                  'No leads',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.sm),
              itemCount: columnLeads.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
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
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lead.name,
                      style: AppTextStyles.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18),
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
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      if (lead.status != LeadStatus.converted)
                        const PopupMenuItem(
                          value: 'convert',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, size: 18),
                              SizedBox(width: 8),
                              Text('Convert to Customer'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (lead.company != null) ...[
                const SizedBox(height: 4),
                Text(
                  lead.company!,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (lead.phone != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        lead.phone!,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
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

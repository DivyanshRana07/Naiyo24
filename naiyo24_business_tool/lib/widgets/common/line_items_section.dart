import 'package:flutter/material.dart';
import 'package:naiyo24_business_tool/models/line_item_model.dart';
import 'package:naiyo24_business_tool/widgets/common/form_widgets.dart';
import 'package:naiyo24_business_tool/widgets/common/add_resource_button.dart';
import 'package:naiyo24_business_tool/widgets/common/add_item_service_dialog.dart';
import 'package:naiyo24_business_tool/widgets/invoice/invoice_autocomplete_fields.dart';
import 'package:naiyo24_business_tool/widgets/invoice/invoice_line_item_row.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';

/// Reusable line items management section for invoices, quotations, and POs
class LineItemsSection extends StatelessWidget {
  const LineItemsSection({
    super.key,
    required this.lineItems,
    required this.onItemAdded,
    required this.onItemChanged,
    required this.onItemDeleted,
    required this.onClearAll,
    this.title = '2. Add Items / Services',
  });

  final List<InvoiceLineItem> lineItems;
  final ValueChanged<InvoiceLineItem> onItemAdded;
  final ValueChanged<InvoiceLineItem> onItemChanged;
  final ValueChanged<InvoiceLineItem> onItemDeleted;
  final VoidCallback onClearAll;
  final String title;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 700;

    final dropdownsRow = Row(
      children: [
        Expanded(
          child: ItemDropdownSelector(onSelected: onItemAdded),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ServiceDropdownSelector(onSelected: onItemAdded),
        ),
      ],
    );

    final addNewButton = AddResourceButton(
      label: 'Add New',
      onPressed: () => AddItemServiceDialog.show(context, onItemCreated: onItemAdded),
      icon: Icons.add_box_rounded,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormSectionTitle(
          title: title,
          icon: Icons.add_shopping_cart_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        if (isCompact) ...[
          ItemDropdownSelector(onSelected: onItemAdded),
          const SizedBox(height: AppSpacing.sm),
          ServiceDropdownSelector(onSelected: onItemAdded),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: addNewButton,
          ),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: dropdownsRow),
              const SizedBox(width: AppSpacing.sm),
              addNewButton,
            ],
          ),
        const SizedBox(height: AppSpacing.md),
        if (lineItems.isEmpty)
          _emptyItemsPlaceholder()
        else
          _lineItemsTable(),
        if (lineItems.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onClearAll,
              icon: Icon(Icons.delete_sweep_rounded,
                  size: 16, color: AppColors.error),
              label: Text(
                'Clear All',
                style: AppTextStyles.caption.copyWith(color: AppColors.error),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _lineItemsTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double minTableWidth = 720;
          final double tableWidth = constraints.maxWidth > minTableWidth
              ? constraints.maxWidth
              : minTableWidth;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: tableWidth,
                maxWidth: tableWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LineItemsHeader(),
                  ...lineItems.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    return LineItemRow(
                      key: ValueKey(item.id),
                      item: item,
                      index: i,
                      onChanged: onItemChanged,
                      onDelete: () => onItemDeleted(item),
                      onCopy: () {
                        final copied = item.copyWith(
                          id: '${item.itemId}-${DateTime.now().millisecondsSinceEpoch}-copy',
                        );
                        onItemAdded(copied);
                      },
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyItemsPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(Icons.add_shopping_cart_outlined,
              size: 48, color: AppColors.textHint),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Select items or services above.',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:naiyo24_business_tool/models/customer_model.dart';
import 'package:naiyo24_business_tool/models/line_item_model.dart';
import 'package:naiyo24_business_tool/widgets/customer/customer_details_card.dart';
import 'package:naiyo24_business_tool/widgets/invoice/invoice_autocomplete_fields.dart';
import 'package:naiyo24_business_tool/widgets/invoice/invoice_line_item_row.dart';
import 'package:naiyo24_business_tool/widgets/common/form_widgets.dart';
import 'package:naiyo24_business_tool/routes/app_routes.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/widgets/common/add_item_service_dialog.dart';

// Backward compatibility exports
Widget formSectionTitle(String title, IconData icon) =>
    FormSectionTitle(title: title, icon: icon);

Widget formFieldLabel(String text) => FormFieldLabel(text: text);

Widget formHeader(BuildContext context, {required String title}) =>
    FormHeader(title: title, icon: Icons.receipt_long_rounded);

Widget invoiceMetaField({
  required String label,
  required String value,
  required IconData icon,
}) =>
    ReadOnlyField(label: label, value: value, icon: icon);

Widget invoiceMetaDateField(
  BuildContext context, {
  required String label,
  required DateTime date,
  required void Function(DateTime) onPicked,
}) =>
    DatePickerField(label: label, date: date, onDatePicked: onPicked);

// ── InvoiceMetaRow ─────────────────────────────────────────────────────────────
// Restyled to Refrens-style: vertical rows with bottom dividers instead of a card+Wrap.

class InvoiceMetaRow extends StatelessWidget {
  const InvoiceMetaRow({
    super.key,
    required this.invoiceDate,
    required this.dueDate,
    required this.onInvoiceDatePicked,
    required this.onDueDatePicked,
  });

  final DateTime invoiceDate;
  final DateTime dueDate;
  final ValueChanged<DateTime> onInvoiceDatePicked;
  final ValueChanged<DateTime> onDueDatePicked;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _fmt(DateTime d) =>
      '${_months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _metaRow('Invoice No*', 'A00001'),
          Divider(height: 1, thickness: 1, color: AppColors.border),
          _tapRow(context, 'Invoice Date*', _fmt(invoiceDate), invoiceDate,
              onInvoiceDatePicked),
          Divider(height: 1, thickness: 1, color: AppColors.border),
          _tapRow(context, 'Due Date', _fmt(dueDate), dueDate, onDueDatePicked),
          Divider(height: 1, thickness: 1, color: AppColors.border),
          _metaRow(
            'Currency*',
            'Indian Rupee (INR, ₹)',
          ),
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value, {Widget? trailing}) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _tapRow(BuildContext context, String label, String display,
      DateTime date, ValueChanged<DateTime> onPicked) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onPicked(picked);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 130,
              child: Text(label,
                  style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ),
            Expanded(child: Text(display, style: AppTextStyles.bodyMedium)),
            Icon(Icons.calendar_today_outlined,
                size: 16, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

// ── CustomerFormSection ────────────────────────────────────────────────────────
// Restyled to Refrens-style: Billed By (static) + Billed To (existing autocomplete).

class CustomerFormSection extends StatelessWidget {
  const CustomerFormSection({
    super.key,
    required this.selectedCustomer,
    required this.onSelected,
  });

  final CustomerModel? selectedCustomer;
  final ValueChanged<CustomerModel?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Billed By (Your Details) ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('Billed By',
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(width: AppSpacing.sm),
            Text('(Your Details)',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
        Divider(color: AppColors.border, height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: const Center(
                  child: Text('A',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Your Business',
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text('Your Business\nIndia',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textPrimary)),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // ── Billed To (Client's Details) ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('Billed To',
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(width: AppSpacing.sm),
            Text("(Client's Details)",
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
        Divider(color: AppColors.border, height: AppSpacing.lg),
        CustomerAutocomplete(
          selectedCustomer: selectedCustomer,
          onSelected: onSelected,
        ),
        if (selectedCustomer == null) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
            child: Column(
              children: [
                Text('Select Client/Business from the list',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.sm),
                Text('OR',
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: () => context.push(AppRoutes.newClient),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(200, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppBorderRadius.full),
                    ),
                  ),
                  icon: const Icon(Icons.add_circle_outline,
                      size: 16, color: Colors.white),
                  label: const Text('Add New Client',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.md),
          CustomerDetailsCard(customer: selectedCustomer!),
        ],
      ],
    );
  }
}

// ── LineItemsFormSection ───────────────────────────────────────────────────────
// Restyled to Refrens-style: primary-colored header bar, vertical item cards,
// "Add New Line" row at bottom. Existing selectors preserved below the card.

class LineItemsFormSection extends StatelessWidget {
  const LineItemsFormSection({
    super.key,
    required this.lineItems,
    required this.onItemAdded,
    required this.onItemChanged,
    required this.onItemDeleted,
    required this.onClearAll,
  });

  final List<InvoiceLineItem> lineItems;
  final ValueChanged<InvoiceLineItem> onItemAdded;
  final void Function(InvoiceLineItem) onItemChanged;
  final void Function(InvoiceLineItem) onItemDeleted;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Items card ──
        ClipRRect(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const LineItemsHeader(),
                if (lineItems.isEmpty)
                  emptyItemsPlaceholder(
                      hint: 'Use the selectors below to add items.')
                else
                  ...lineItems.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    return Column(
                      children: [
                        if (i > 0)
                          Divider(
                              height: 1,
                              thickness: 1,
                              color: AppColors.border),
                        LineItemRow(
                          key: ValueKey(item.id),
                          item: item,
                          index: i,
                          onChanged: onItemChanged,
                          onDelete: () => onItemDeleted(item),
                        ),
                      ],
                    );
                  }),
                Divider(height: 1, thickness: 1, color: AppColors.border),
                // Add New Line button
                InkWell(
                  onTap: () => AddItemServiceDialog.show(context),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_box_outlined,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Add New Line',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // ── Existing item / service selectors (preserved) ──
        if (isCompact) ...[
          ItemDropdownSelector(onSelected: onItemAdded),
          const SizedBox(height: AppSpacing.sm),
          ServiceDropdownSelector(onSelected: onItemAdded),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => AddItemServiceDialog.show(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(0, 48),
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.md)),
              ),
              icon: const Icon(Icons.add_box_rounded,
                  size: 16, color: Colors.white),
              label: const Text('Add New',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
          ),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: ItemDropdownSelector(onSelected: onItemAdded)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: ServiceDropdownSelector(onSelected: onItemAdded)),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.icon(
                onPressed: () => AddItemServiceDialog.show(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(0, 48),
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md)),
                ),
                icon: const Icon(Icons.add_box_rounded,
                    size: 16, color: Colors.white),
                label: const Text('Add New',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ],
          ),
        if (lineItems.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onClearAll,
              icon: Icon(Icons.delete_sweep_rounded,
                  size: 16, color: AppColors.error),
              label: Text('Clear All',
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.error)),
            ),
          ),
        ],
      ],
    );
  }

  // Kept for reference — no longer called by build() above.
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

  Widget emptyItemsPlaceholder({required String hint}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Icon(Icons.add_shopping_cart_outlined,
              size: 48, color: AppColors.textHint),
          const SizedBox(height: AppSpacing.md),
          Text(
            hint,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

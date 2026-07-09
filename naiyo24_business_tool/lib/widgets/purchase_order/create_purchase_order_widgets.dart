import 'package:flutter/material.dart';
import 'package:naiyo24_business_tool/models/vendor_model.dart';
import 'package:naiyo24_business_tool/widgets/common/form_widgets.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';

// Backward compatibility wrappers
Widget poCard({required Widget child}) => CardContainer(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: child,
    );

Widget poSectionLabel(String text) {
  return Text(
    text,
    style: AppTextStyles.labelLarge.copyWith(
      color: AppColors.textSecondary,
      fontSize: 11,
      letterSpacing: 0.8,
    ),
  );
}

Widget poItemField(TextEditingController controller, String hint,
    {bool isNumber = false, VoidCallback? onChanged}) {
  return TextField(
    controller: controller,
    keyboardType: isNumber
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
    onChanged: (_) {
      if (onChanged != null) onChanged();
    },
    style: AppTextStyles.bodyMedium,
    decoration: InputDecoration(
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium
          .copyWith(color: AppColors.textSecondary.withValues(alpha: 0.5)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      filled: true,
      fillColor: AppColors.background,
    ),
  );
}

Widget poTotalRow(String label, String value, {bool highlight = false}) =>
    SummaryRow(label: label, value: value, isTotal: highlight);

class POOrderByCard extends StatelessWidget {
  const POOrderByCard({super.key, required this.email});
  final String? email;

  @override
  Widget build(BuildContext context) {
    return poCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          poSectionLabel('Order By'),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary,
                child: Text(
                  email?.isNotEmpty == true ? email![0].toUpperCase() : 'N',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                      fontSize: 18),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Naiyo24 Business',
                        style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w400,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(email ?? 'admin@naiyo24.com',
                        style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 2),
                    Text('Sector 62, Noida, India',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class POOrderToCard extends StatelessWidget {
  const POOrderToCard({
    super.key,
    required this.vendors,
    required this.selectedVendor,
    required this.onChanged,
    required this.onAddNewVendor,
  });

  final List<VendorModel> vendors;
  final VendorModel? selectedVendor;
  final ValueChanged<VendorModel?> onChanged;
  final VoidCallback onAddNewVendor;

  @override
  Widget build(BuildContext context) {
    return poCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              poSectionLabel('Order To'),
              TextButton.icon(
                onPressed: onAddNewVendor,
                icon: const Icon(Icons.add_rounded, size: 15),
                label: const Text('New Vendor'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w400),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              border: Border.all(color: AppColors.border),
              color: AppColors.background,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<VendorModel>(
                isExpanded: true,
                value: selectedVendor,
                hint: Text('Select Vendor',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
                icon: Icon(Icons.arrow_drop_down_rounded,
                    color: AppColors.textSecondary),
                items: vendors.map((v) {
                  return DropdownMenuItem<VendorModel>(
                    value: v,
                    child: Text(v.name, style: AppTextStyles.bodyMedium),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Purchase Order title and description input section
class POBasicInfoSection extends StatelessWidget {
  const POBasicInfoSection({
    super.key,
    required this.titleController,
    required this.descriptionController,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;

  @override
  Widget build(BuildContext context) {
    return poCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          poSectionLabel('Title'),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: titleController,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 14),
              hintText: 'e.g., Raw materials Q3',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                borderSide:
                    BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
              fillColor: AppColors.background,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          poSectionLabel('Description (Optional)'),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: descriptionController,
            style: AppTextStyles.bodyMedium,
            maxLines: 3,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(AppSpacing.md),
              hintText: 'Provide details about this PO...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                borderSide:
                    BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
              fillColor: AppColors.background,
            ),
          ),
        ],
      ),
    );
  }
}

/// Purchase Order number and date section
class POMetadataSection extends StatelessWidget {
  const POMetadataSection({
    super.key,
    required this.poNumberController,
    required this.dateController,
  });

  final TextEditingController poNumberController;
  final TextEditingController dateController;

  @override
  Widget build(BuildContext context) {
    return poCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                poSectionLabel('PO Number'),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: poNumberController,
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      borderSide: BorderSide(
                          color: AppColors.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                poSectionLabel('Date'),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: dateController,
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      borderSide: BorderSide(
                          color: AppColors.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    suffixIcon: Icon(Icons.calendar_today_rounded,
                        size: 18, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Purchase Order line items management section
class POLineItemsSection extends StatelessWidget {
  const POLineItemsSection({
    super.key,
    required this.items,
    required this.onItemTotal,
    required this.totalAmount,
    required this.onAddItem,
    required this.onRemoveItem,
    required this.onItemChanged,
  });

  final List<Map<String, dynamic>> items;
  final double Function(Map<String, dynamic>) onItemTotal;
  final double totalAmount;
  final VoidCallback onAddItem;
  final void Function(int) onRemoveItem;
  final VoidCallback onItemChanged;

  @override
  Widget build(BuildContext context) {
    return poCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          poSectionLabel('Items'),
          const SizedBox(height: AppSpacing.md),
          _buildTableHeader(),
          const SizedBox(height: AppSpacing.sm),
          ...List.generate(items.length, (index) {
            final item = items[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: poItemField(
                      item['desc'] as TextEditingController,
                      'e.g., MacBook Pro 14"',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: poItemField(
                      item['qty'] as TextEditingController,
                      '1',
                      isNumber: true,
                      onChanged: onItemChanged,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: poItemField(
                      item['price'] as TextEditingController,
                      '0.00',
                      isNumber: true,
                      onChanged: onItemChanged,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '₹${onItemTotal(item).toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w400,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: items.length > 1
                            ? AppColors.error
                            : AppColors.border,
                      ),
                      onPressed: () => onRemoveItem(index),
                    ),
                  ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: onAddItem,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add Line Item'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Divider(height: AppSpacing.xl, color: AppColors.border),
          _buildTotalsSection(),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              'Description',
              style: AppTextStyles.labelLarge.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Qty',
              style: AppTextStyles.labelLarge.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Unit Price (₹)',
              style: AppTextStyles.labelLarge.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Total (₹)',
              style: AppTextStyles.labelLarge.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildTotalsSection() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          children: [
            poTotalRow('Subtotal', '₹${totalAmount.toStringAsFixed(2)}'),
            const SizedBox(height: AppSpacing.sm),
            poTotalRow('Tax (0%)', '₹0.00'),
            Divider(color: AppColors.border),
            poTotalRow(
              'Total Amount',
              '₹${totalAmount.toStringAsFixed(2)}',
              highlight: true,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:naiyo24_business_tool/models/customer_model.dart';
import 'package:naiyo24_business_tool/routes/app_routes.dart';
import 'package:naiyo24_business_tool/widgets/invoice/invoice_autocomplete_fields.dart';
import 'package:naiyo24_business_tool/widgets/common/form_widgets.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
// Backward compatibility wrappers
Widget qtCard({required Widget child}) => CardContainer(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: child,
    );

Widget qtSectionLabel(String text) {
  return Text(
    text,
    style: AppTextStyles.labelLarge.copyWith(
      color: AppColors.textSecondary,
      fontSize: 11,
      letterSpacing: 0.8,
    ),
  );
}

Widget qtSectionTitle(String title, IconData icon) =>
    FormSectionTitle(title: title, icon: icon);

Widget qtFieldLabel(String text) => FormFieldLabel(text: text);

class QuotationCustomerFormSection extends StatelessWidget {
  const QuotationCustomerFormSection({
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('Quotation From',
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

        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('Quotation For',
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
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textHint)),
                const SizedBox(height: AppSpacing.sm),
                ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.newClient),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(200, 44),
                  ),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Add New Client'),
                ),
              ],
            ),
          ),
        ] else ...[
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(selectedCustomer!.name,
                          style: AppTextStyles.bodyLarge
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      if (selectedCustomer!.address?.isNotEmpty ?? false)
                        Text(selectedCustomer!.address!,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {},
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('Edit',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class QuotationSummaryCard extends StatelessWidget {
  const QuotationSummaryCard({
    super.key,
    required this.subTotal,
    required this.totalDiscount,
    required this.taxableAmount,
    required this.totalGst,
    required this.grandTotal,
    required this.onAddTax,
  });

  final double subTotal;
  final double totalDiscount;
  final double taxableAmount;
  final double totalGst;
  final double grandTotal;
  final VoidCallback onAddTax;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _totalRow('Amount', '₹${subTotal.toStringAsFixed(2)}'),
        _totalRow('GST', '₹${totalGst.toStringAsFixed(2)}'),
        if (totalDiscount > 0)
          _totalRow('Discount', '-₹${totalDiscount.toStringAsFixed(2)}'),
        const SizedBox(height: AppSpacing.md),
        Divider(color: AppColors.border, height: AppSpacing.lg),
        Row(
          children: [
            Text('Total (INR)',
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('₹${grandTotal.toStringAsFixed(2)}',
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        Divider(color: AppColors.border, height: AppSpacing.lg),
      ],
    );
  }

  Widget _totalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyLarge),
          Text(value,
              style: AppTextStyles.bodyLarge
                  .copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class QuotationRightPaneControls extends StatelessWidget {
  const QuotationRightPaneControls({
    super.key,
    required this.paymentTerms,
    required this.currency,
    required this.validUntil,
    required this.onPaymentTermsChanged,
    required this.onCurrencyChanged,
  });

  final String paymentTerms;
  final String currency;
  final DateTime validUntil;
  final ValueChanged<String?> onPaymentTermsChanged;
  final ValueChanged<String?> onCurrencyChanged;

  @override
  Widget build(BuildContext context) {
    final daysLeft = validUntil.difference(DateTime.now()).inDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        qtFieldLabel('Payment Terms'),
        DropdownButtonFormField<String>(
          initialValue: paymentTerms,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              borderSide: BorderSide(color: AppColors.border),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
          items: const ['Net 15 Days', 'Net 30 Days', 'Due on Receipt']
              .map((e) => DropdownMenuItem(
                  value: e, child: Text(e, style: AppTextStyles.bodyMedium)))
              .toList(),
          onChanged: onPaymentTermsChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        qtFieldLabel('Currency'),
        DropdownButtonFormField<String>(
          initialValue: currency,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              borderSide: BorderSide(color: AppColors.border),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
          items: const ['INR - Indian Rupee (₹)', 'USD - US Dollar (\$)']
              .map((e) => DropdownMenuItem(
                  value: e, child: Text(e, style: AppTextStyles.bodyMedium)))
              .toList(),
          onChanged: onCurrencyChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            border: Border.all(color: const Color(0xFF86EFAC)),
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Valid Until',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    '${validUntil.day.toString().padLeft(2, '0')}/'
                    '${validUntil.month.toString().padLeft(2, '0')}/'
                    '${validUntil.year}',
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text('Days Left',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                  Text('${daysLeft < 0 ? 0 : daysLeft} Days',
                      style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFF16A34A),
                          fontWeight: FontWeight.w600)),
                ],
              ),
              Icon(Icons.calendar_month_rounded,
                  color: AppColors.primary, size: 20),
            ],
          ),
        ),
      ],
    );
  }
}

/// Quotation metadata row with date pickers and reference field
class QuotationMetaRow extends StatelessWidget {
  const QuotationMetaRow({
    super.key,
    required this.quotationDate,
    required this.validUntil,
    required this.referenceController,
    required this.onQuotationDatePicked,
    required this.onValidUntilPicked,
  });

  final DateTime quotationDate;
  final DateTime validUntil;
  final TextEditingController referenceController;
  final ValueChanged<DateTime> onQuotationDatePicked;
  final ValueChanged<DateTime> onValidUntilPicked;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: Column(
        children: [
          _metaRow('Quotation No*', 'Auto-generated on save'),
          Divider(height: 1, thickness: 1, color: AppColors.border),
          _tapRow(
            context,
            'Quotation Date*',
            '${quotationDate.day.toString().padLeft(2, '0')}/${quotationDate.month.toString().padLeft(2, '0')}/${quotationDate.year}',
            quotationDate,
            onQuotationDatePicked,
          ),
          Divider(height: 1, thickness: 1, color: AppColors.border),
          _tapRow(
            context,
            'Valid Until',
            '${validUntil.day.toString().padLeft(2, '0')}/${validUntil.month.toString().padLeft(2, '0')}/${validUntil.year}',
            validUntil,
            onValidUntilPicked,
          ),
          Divider(height: 1, thickness: 1, color: AppColors.border),
          _inputRow('Reference No. / PO No.', referenceController),
        ],
      ),
    );
  }

  Widget _metaRow(String label, String display) {
    return Padding(
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

  Widget _inputRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTextStyles.bodyMedium,
              decoration: const InputDecoration(
                hintText: 'Enter reference...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:naiyo24_business_tool/models/line_item_model.dart';
import 'package:naiyo24_business_tool/widgets/common/number_input_field.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';

// ── LineItemRow ───────────────────────────────────────────────────────────────
// Restyled from horizontal table row to Refrens-style vertical stacked card.
// All state, controllers, and _emit() logic are preserved exactly.

class LineItemRow extends StatefulWidget {
  const LineItemRow({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onDelete,
    required this.index,
  });

  final InvoiceLineItem item;
  final void Function(InvoiceLineItem updated) onChanged;
  final VoidCallback onDelete;
  final int index;

  @override
  State<LineItemRow> createState() => _LineItemRowState();
}

class _LineItemRowState extends State<LineItemRow> {
  late TextEditingController _qtyCtrl;
  late TextEditingController _rateCtrl;
  late TextEditingController _discCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(
        text:
            widget.item.qty.toStringAsFixed(widget.item.qty % 1 == 0 ? 0 : 2));
    _rateCtrl =
        TextEditingController(text: widget.item.rate.toStringAsFixed(2));
    _discCtrl = TextEditingController(
        text: widget.item.discountPercent.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _rateCtrl.dispose();
    _discCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    final qty = double.tryParse(_qtyCtrl.text) ?? widget.item.qty;
    final rate = double.tryParse(_rateCtrl.text) ?? widget.item.rate;
    final disc = double.tryParse(_discCtrl.text) ?? widget.item.discountPercent;
    widget.onChanged(widget.item.copyWith(
      qty: qty,
      rate: rate,
      discountPercent: disc,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.item.totalAmount;
    final cgst = widget.item.gstAmount / 2;
    final sgst = widget.item.gstAmount / 2;
    final amount = widget.item.rate * widget.item.qty;

    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Item number + copy + close ──
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Text(
                  '${widget.index + 1}.',
                  style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.copy_outlined,
                        size: 16, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: widget.onDelete,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close,
                        size: 16, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: AppColors.border),
          _labelRow(
            'Item',
            widget.item.name.isEmpty ? 'Item Name / SKU Id' : widget.item.name,
            dimValue: widget.item.name.isEmpty,
          ),
          Divider(height: 1, thickness: 1, color: AppColors.border),
          _labelRow(
            'HSN/SAC',
            widget.item.code.isEmpty ? '#' : widget.item.code,
            trailing:
                Icon(Icons.search, size: 16, color: AppColors.textHint),
            dimValue: widget.item.code.isEmpty,
          ),
          Divider(height: 1, thickness: 1, color: AppColors.border),
          _staticRow(
              'GST Rate', '${widget.item.gstPercent.toStringAsFixed(0)}%'),
          Divider(height: 1, thickness: 1, color: AppColors.border),
          _inputRow('Quantity', _qtyCtrl),
          Divider(height: 1, thickness: 1, color: AppColors.border),
          _inputRow('Rate', _rateCtrl, prefix: '₹ '),
          Divider(height: 1, thickness: 1, color: AppColors.border),
          _staticRow('Amount', '₹${amount.toStringAsFixed(2)}'),
          Divider(height: 1, thickness: 1, color: AppColors.border),
          _staticRow('CGST', '₹${cgst.toStringAsFixed(2)}'),
          Divider(height: 1, thickness: 1, color: AppColors.border),
          _staticRow('SGST', '₹${sgst.toStringAsFixed(2)}'),
          Divider(height: 1, thickness: 1, color: AppColors.border),
          _staticRow('Total', '₹${total.toStringAsFixed(2)}', bold: true),
          Divider(height: 1, thickness: 1, color: AppColors.border),
          _inputRow('Discount %', _discCtrl, suffix: '%'),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  Widget _labelRow(String label, String value,
      {Widget? trailing, bool dimValue = false}) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textPrimary)),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.bodyMedium.copyWith(
                    color: dimValue
                        ? AppColors.textHint
                        : AppColors.textPrimary)),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _staticRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textPrimary)),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                    color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _inputRow(String label, TextEditingController ctrl,
      {String? prefix, String? suffix}) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textPrimary)),
          ),
          if (prefix != null)
            Text(prefix,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textPrimary)),
          Expanded(
            child: NumberInputField(
              controller: ctrl,
              onChanged: (_) => _emit(),
              label: '',
            ),
          ),
          if (suffix != null)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(suffix,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
            ),
        ],
      ),
    );
  }
}

// ── LineItemsHeader ───────────────────────────────────────────────────────────
// Restyled from multi-column table header to Refrens primary-colored header bar.

class LineItemsHeader extends StatelessWidget {
  const LineItemsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 12),
      color: AppColors.primary,
      child: Text(
        'Item',
        style: AppTextStyles.bodyMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── InvoiceTotalsCard ─────────────────────────────────────────────────────────
// Restyled to Refrens totals section.
// All existing fields (paymentMethod, paidAmount, due amount) preserved exactly.

class InvoiceTotalsCard extends StatelessWidget {
  const InvoiceTotalsCard({
    super.key,
    required this.subTotal,
    required this.totalDiscount,
    required this.totalGst,
    required this.roundOff,
    required this.grandTotal,
    required this.paidAmount,
    required this.paymentMethod,
    required this.onPaidAmountChanged,
    required this.onPaymentMethodChanged,
  });

  final double subTotal;
  final double totalDiscount;
  final double totalGst;
  final double roundOff;
  final double grandTotal;
  final double paidAmount;
  final String paymentMethod;
  final void Function(double) onPaidAmountChanged;
  final void Function(String) onPaymentMethodChanged;

  static const _paymentMethods = [
    'Cash',
    'UPI',
    'Bank Transfer',
    'Cheque',
    'Credit',
    'Other'
  ];

  @override
  Widget build(BuildContext context) {
    final due = (grandTotal - paidAmount).clamp(0.0, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _totalRow('Amount', '₹${subTotal.toStringAsFixed(2)}'),
        _totalRow('GST', '₹${totalGst.toStringAsFixed(2)}'),
        if (totalDiscount > 0)
          _totalRow('Discount', '-₹${totalDiscount.toStringAsFixed(2)}'),
        const SizedBox(height: AppSpacing.md),
        Divider(color: AppColors.border, height: AppSpacing.lg),
        // Grand Total
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
        // ── Existing payment fields (unchanged) ──
        DropdownButtonFormField<String>(
          initialValue: paymentMethod,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Payment Method',
            prefixIcon: Icon(Icons.payment_rounded, size: 18),
          ),
          items: _paymentMethods
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: (v) => onPaymentMethodChanged(v!),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          initialValue: paidAmount > 0 ? paidAmount.toStringAsFixed(2) : '',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Paid Amount (₹)',
            prefixIcon: Icon(Icons.currency_rupee_rounded, size: 18),
            hintText: '0.00',
          ),
          onChanged: (v) => onPaidAmountChanged(double.tryParse(v) ?? 0),
        ),
        if (due > 0) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(color: AppColors.error, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Due Amount',
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                Text('₹${due.toStringAsFixed(2)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.error)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _totalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
          const Spacer(),
          Text(value,
              style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

}

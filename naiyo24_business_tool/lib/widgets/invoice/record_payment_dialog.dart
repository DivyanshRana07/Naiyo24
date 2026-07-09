import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:naiyo24_business_tool/models/invoice_model.dart';
import 'package:naiyo24_business_tool/notifiers/invoice_notifier.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';

class RecordPaymentDialog extends ConsumerStatefulWidget {
  const RecordPaymentDialog({super.key, required this.invoice});

  final InvoiceModel invoice;

  @override
  ConsumerState<RecordPaymentDialog> createState() =>
      _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends ConsumerState<RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountCtrl;
  String _paymentMethod = 'Cash';

  static const _paymentMethods = [
    'Cash',
    'UPI',
    'Bank Transfer',
    'Cheque',
    'Credit',
    'Other',
  ];

  double get _dueAmount => widget.invoice.dueAmount;
  double get _newPaidAmount =>
      widget.invoice.paidAmount + (double.tryParse(_amountCtrl.text) ?? 0);
  double get _remainingAfter =>
      (widget.invoice.grandTotal - _newPaidAmount).clamp(0, double.infinity);

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: _dueAmount.toStringAsFixed(2));
    _amountCtrl.addListener(() => setState(() {}));
    _paymentMethod = widget.invoice.paymentMethod;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enteredAmount = double.tryParse(_amountCtrl.text) ?? 0;
    final isOverpay = enteredAmount > _dueAmount + 0.01;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                      ),
                      child: Icon(Icons.payments_rounded,
                          color: AppColors.success, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Record Payment', style: AppTextStyles.h2),
                          Text(widget.invoice.invoiceNo,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                          foregroundColor: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Divider(color: AppColors.border),
                const SizedBox(height: AppSpacing.lg),
                _summaryRow(
                    'Invoice Total',
                    '₹${widget.invoice.grandTotal.toStringAsFixed(2)}',
                    AppColors.textPrimary),
                _summaryRow(
                    'Previously Paid',
                    '₹${widget.invoice.paidAmount.toStringAsFixed(2)}',
                    AppColors.success),
                _summaryRow('Current Due', '₹${_dueAmount.toStringAsFixed(2)}',
                    AppColors.error,
                    bold: true),
                const SizedBox(height: AppSpacing.md),
                Divider(color: AppColors.border),
                const SizedBox(height: AppSpacing.md),
                _label('Payment Amount (₹) *'),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.currency_rupee_rounded,
                        color: AppColors.primary),
                    suffixText: isOverpay ? 'Exceeds due' : null,
                    suffixStyle:
                        AppTextStyles.caption.copyWith(color: AppColors.error),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Enter payment amount';
                    }
                    final d = double.tryParse(v);
                    if (d == null || d <= 0) {
                      return 'Enter a valid positive amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                if (enteredAmount > 0)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: _remainingAfter <= 0
                          ? AppColors.success.withValues(alpha: 0.07)
                          : AppColors.warning.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      border: Border.all(
                          color: _remainingAfter <= 0
                              ? AppColors.success.withValues(alpha: 0.3)
                              : AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _remainingAfter <= 0
                              ? Icons.check_circle_rounded
                              : Icons.timelapse_rounded,
                          size: 18,
                          color: _remainingAfter <= 0
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _remainingAfter <= 0
                                ? 'Invoice will be fully paid ✓'
                                : 'Remaining balance: ₹${_remainingAfter.toStringAsFixed(2)}',
                            style: AppTextStyles.caption.copyWith(
                              color: _remainingAfter <= 0
                                  ? AppColors.success
                                  : AppColors.warning,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                _label('Payment Method'),
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.payment_rounded, size: 18),
                  ),
                  items: _paymentMethods
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppBorderRadius.md)),
                        ),
                        onPressed: _save,
                        icon: const Icon(Icons.check_rounded,
                            size: 18, color: Colors.white),
                        label: Text('Confirm Payment',
                            style: AppTextStyles.labelLarge
                                .copyWith(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final entered = double.tryParse(_amountCtrl.text) ?? 0;
    final newPaid = (widget.invoice.paidAmount + entered)
        .clamp(0.0, widget.invoice.grandTotal);

    final updated = widget.invoice.copyWith(
      paidAmount: newPaid,
      paymentMethod: _paymentMethod,
    );
    ref.read(invoiceNotifierProvider.notifier).updateInvoice(updated);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '₹${entered.toStringAsFixed(2)} recorded for ${widget.invoice.invoiceNo}.',
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color color,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
          Text(value,
              style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: bold ? FontWeight.w400 : FontWeight.w400,
                  color: color)),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w400, color: AppColors.textPrimary)),
      );
}

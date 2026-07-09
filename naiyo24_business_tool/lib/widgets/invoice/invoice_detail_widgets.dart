import 'package:flutter/material.dart';
import 'package:naiyo24_business_tool/models/invoice_model.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';

class LineItemsTable extends StatelessWidget {
  const LineItemsTable({super.key, required this.invoice});
  final InvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text('Line Items',
                style: AppTextStyles.labelLarge
                    .copyWith(fontWeight: FontWeight.w400)),
          ),
          Divider(height: 1, color: AppColors.border),
          _buildTable(),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 600),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(4),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(2),
            4: FlexColumnWidth(2),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: AppColors.background),
              children: [
                _th('Item Description'),
                _th('Qty'),
                _th('Price'),
                _th('GST %'),
                _th('Total', align: TextAlign.right),
              ],
            ),
            ...invoice.lineItems.map((item) {
              return TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                children: [
                  _td(item.name),
                  _td(item.qty.toStringAsFixed(0)),
                  _td('₹${item.rate.toStringAsFixed(2)}'),
                  _td('${item.gstPercent.toStringAsFixed(0)}%'),
                  _td('₹${item.totalAmount.toStringAsFixed(2)}',
                      align: TextAlign.right, bold: true),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _th(String text, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w400,
        ),
        textAlign: align,
      ),
    );
  }

  Widget _td(String text, {TextAlign align = TextAlign.left, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        text,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: bold ? FontWeight.w400 : FontWeight.w400,
        ),
        textAlign: align,
      ),
    );
  }
}

class InvoiceMeta extends StatelessWidget {
  const InvoiceMeta({super.key, required this.invoice});
  final InvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    final (statusLabel, statusColor) = switch (invoice.status) {
      InvoiceStatus.paid => ('PAID', AppColors.success),
      InvoiceStatus.partial => ('PARTIAL', AppColors.warning),
      InvoiceStatus.due => ('DUE', AppColors.error),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.md,
        children: [
          _metaTile('Invoice No.', invoice.invoiceNo, Icons.tag_rounded,
              AppColors.primary),
          _metaTile('Invoice Date', fmt(invoice.invoiceDate),
              Icons.calendar_today_rounded, AppColors.textSecondary),
          _metaTile('Due Date', fmt(invoice.dueDate), Icons.event_rounded,
              AppColors.textSecondary),
          _metaTile('Payment Method', invoice.paymentMethod,
              Icons.payment_rounded, AppColors.textSecondary),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.full),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(statusLabel,
                    style: AppTextStyles.labelLarge.copyWith(
                        color: statusColor, fontWeight: FontWeight.w400)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaTile(String label, String value, IconData icon, Color iconColor) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 5),
              Flexible(
                child: Text(value,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w400)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CustomerCard extends StatelessWidget {
  const CustomerCard({super.key, required this.invoice});
  final InvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary,
            child: Text(
              invoice.customerName[0].toUpperCase(),
              style:
                  AppTextStyles.h2.copyWith(color: Colors.white, fontSize: 20),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bill To',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(invoice.customerName, style: AppTextStyles.h2),
                const SizedBox(height: 4),
                _row(Icons.phone_rounded, invoice.customerMobile),
                if (invoice.customerAddress != null)
                  _row(Icons.location_on_rounded, invoice.customerAddress!),
                if (invoice.customerGst != null)
                  _row(
                      Icons.business_rounded, 'GSTIN: ${invoice.customerGst!}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 5),
            Expanded(
              child: Text(text,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
            ),
          ],
        ),
      );
}

class FinancialSummary extends StatelessWidget {
  const FinancialSummary({super.key, required this.invoice});
  final InvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Financial Summary',
              style: AppTextStyles.labelLarge
                  .copyWith(fontWeight: FontWeight.w400)),
          const SizedBox(height: AppSpacing.md),
          _row('Sub Total', '₹${invoice.subTotal.toStringAsFixed(2)}'),
          if (invoice.totalDiscount > 0)
            _row('Discount', '- ₹${invoice.totalDiscount.toStringAsFixed(2)}',
                color: AppColors.success),
          _row('GST', '₹${invoice.totalGst.toStringAsFixed(2)}'),
          if (invoice.roundOff != 0)
            _row('Round Off',
                '${invoice.roundOff >= 0 ? '+' : ''}₹${invoice.roundOff.toStringAsFixed(2)}'),
          Divider(color: AppColors.border, height: AppSpacing.xl),
          _row('Grand Total', '₹${invoice.grandTotal.toStringAsFixed(2)}',
              bold: true, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
          Text(value,
              style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: bold ? FontWeight.w400 : FontWeight.w400,
                  color: color ?? AppColors.textPrimary,
                  fontSize: bold ? 16 : 14)),
        ],
      ),
    );
  }
}

class PaymentPanel extends StatelessWidget {
  const PaymentPanel({super.key, required this.invoice});
  final InvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusLabel) = switch (invoice.status) {
      InvoiceStatus.paid => (AppColors.success, 'Fully Paid'),
      InvoiceStatus.partial => (AppColors.warning, 'Partially Paid'),
      InvoiceStatus.due => (AppColors.error, 'Payment Due'),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Status',
              style: AppTextStyles.labelLarge
                  .copyWith(fontWeight: FontWeight.w400)),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  invoice.status == InvoiceStatus.paid
                      ? Icons.check_circle_rounded
                      : invoice.status == InvoiceStatus.partial
                          ? Icons.timelapse_rounded
                          : Icons.warning_rounded,
                  color: statusColor,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(statusLabel,
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: statusColor, fontWeight: FontWeight.w400)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _amtRow('Invoice Amount', '₹${invoice.grandTotal.toStringAsFixed(2)}',
              AppColors.textPrimary),
          _amtRow('Amount Paid', '₹${invoice.paidAmount.toStringAsFixed(2)}',
              AppColors.success),
          Divider(color: AppColors.border, height: AppSpacing.lg),
          _amtRow('Balance Due', '₹${invoice.dueAmount.toStringAsFixed(2)}',
              invoice.dueAmount > 0 ? AppColors.error : AppColors.success,
              bold: true),
        ],
      ),
    );
  }

  Widget _amtRow(String label, String value, Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
          Text(value,
              style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: bold ? FontWeight.w400 : FontWeight.w400,
                  color: color,
                  fontSize: bold ? 15 : 14)),
        ],
      ),
    );
  }
}

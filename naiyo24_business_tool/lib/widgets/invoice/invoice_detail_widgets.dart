import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:naiyo24_business_tool/models/invoice_model.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';

String _formatCurrency(double val, Map<String, dynamic>? settings) {
  final formatSettings = settings?['format'] as Map<String, dynamic>?;
  final symbol = formatSettings?['currencySymbol'] as String? ?? '₹';
  final decimals = formatSettings?['decimals'] as int? ?? 2;
  return '$symbol${val.toStringAsFixed(decimals)}';
}

class InvoiceHeader extends StatelessWidget {
  const InvoiceHeader({super.key, required this.invoice});
  final InvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    final hasLogo = invoice.logo != null && invoice.logo!.isNotEmpty;
    ImageProvider? imageProvider;
    if (hasLogo) {
      try {
        final pureBase64 = invoice.logo!.contains(',')
            ? invoice.logo!.substring(invoice.logo!.indexOf(',') + 1)
            : invoice.logo!;
        imageProvider = MemoryImage(base64Decode(pureBase64));
      } catch (_) {}
    }

    final hasSubtitle = invoice.subtitle != null && invoice.subtitle!.isNotEmpty;

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.invoiceType == 'proforma' ? 'PROFORMA INVOICE' : 'TAX INVOICE',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  invoice.invoiceNo,
                  style: AppTextStyles.h1.copyWith(fontSize: 24),
                ),
                if (hasSubtitle) ...[
                  const SizedBox(height: 4),
                  Text(
                    invoice.subtitle!,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ],
                if (invoice.settings?['gst']?['gstin'] != null &&
                    invoice.settings?['gst']?['gstin'].toString().isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    'GSTIN: ${invoice.settings?['gst']?['gstin']}',
                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),
          if (imageProvider != null) ...[
            const SizedBox(width: AppSpacing.md),
            Container(
              constraints: const BoxConstraints(maxHeight: 70, maxWidth: 120),
              child: Image(image: imageProvider, fit: BoxFit.contain),
            ),
          ],
        ],
      ),
    );
  }
}

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
    final columnsSettings = invoice.settings?['columns'] as Map<String, dynamic>? ?? {
      'hsn': true,
      'discount': true,
      'gst': true,
      'unit': true,
      'category': true,
    };
    final gstEnabled = invoice.settings?['gst']?['enabled'] as bool? ?? true;

    final showHsn = columnsSettings['hsn'] ?? true;
    final showDiscount = columnsSettings['discount'] ?? true;
    final showGst = (columnsSettings['gst'] ?? true) && gstEnabled;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 600),
        child: DataTable(
          columnSpacing: 20,
          headingRowColor: WidgetStateProperty.all(AppColors.background),
          columns: [
            const DataColumn(label: Text('Item Description')),
            if (showHsn) const DataColumn(label: Text('HSN/SAC')),
            const DataColumn(label: Text('Qty'), numeric: true),
            const DataColumn(label: Text('Price'), numeric: true),
            if (showDiscount) const DataColumn(label: Text('Discount'), numeric: true),
            if (showGst) const DataColumn(label: Text('GST %'), numeric: true),
            const DataColumn(label: Text('Total'), numeric: true),
          ],
          rows: invoice.lineItems.map((item) {
            return DataRow(cells: [
              DataCell(Text(item.name)),
              if (showHsn) DataCell(Text(item.code.isNotEmpty ? item.code : '-')),
              DataCell(Text(item.qty.toStringAsFixed(0))),
              DataCell(Text(_formatCurrency(item.rate, invoice.settings))),
              if (showDiscount) DataCell(Text('${item.discountPercent}%')),
              if (showGst) DataCell(Text('${item.gstPercent}%')),
              DataCell(Text(_formatCurrency(item.totalAmount, invoice.settings),
                  style: const TextStyle(fontWeight: FontWeight.bold))),
            ]);
          }).toList(),
        ),
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
                if (invoice.customerGst != null && invoice.customerGst!.isNotEmpty)
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
          _row('Sub Total', _formatCurrency(invoice.subTotal, invoice.settings)),
          if (invoice.totalDiscount > 0)
            _row('Discount', '- ${_formatCurrency(invoice.totalDiscount, invoice.settings)}',
                color: AppColors.success),
          if (invoice.settings?['gst']?['enabled'] != false)
            _row('GST', _formatCurrency(invoice.totalGst, invoice.settings)),
          if (invoice.roundOff != 0)
            _row('Round Off',
                '${invoice.roundOff >= 0 ? '+' : ''}${_formatCurrency(invoice.roundOff, invoice.settings)}'),
          Divider(color: AppColors.border, height: AppSpacing.xl),
          _row('Grand Total', _formatCurrency(invoice.grandTotal, invoice.settings),
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
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
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
          _amtRow('Invoice Amount', _formatCurrency(invoice.grandTotal, invoice.settings),
              AppColors.textPrimary),
          _amtRow('Amount Paid', _formatCurrency(invoice.paidAmount, invoice.settings),
              AppColors.success),
          Divider(color: AppColors.border, height: AppSpacing.lg),
          _amtRow('Balance Due', _formatCurrency(invoice.dueAmount, invoice.settings),
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
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: color,
                  fontSize: bold ? 15 : 14)),
        ],
      ),
    );
  }
}

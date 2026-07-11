import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:naiyo24_business_tool/models/quotation_model.dart';
import 'package:naiyo24_business_tool/notifiers/auth_notifier.dart';
import 'package:naiyo24_business_tool/notifiers/quotation_notifier.dart';
import 'package:naiyo24_business_tool/routes/app_routes.dart';
import 'package:naiyo24_business_tool/theme/theme.dart';
import 'package:naiyo24_business_tool/widgets/common/dashboard_app_bar.dart';
import 'package:naiyo24_business_tool/widgets/common/screen_shell.dart';
import 'package:naiyo24_business_tool/widgets/invoice/send_options_dialog.dart';

String _formatCurrency(double val, Map<String, dynamic>? settings) {
  final formatSettings = settings?['format'] as Map<String, dynamic>?;
  final symbol = formatSettings?['currencySymbol'] as String? ?? '₹';
  final decimals = formatSettings?['decimals'] as int? ?? 2;
  return '$symbol${val.toStringAsFixed(decimals)}';
}

class QuotationDetailScreen extends ConsumerWidget {
  const QuotationDetailScreen({super.key, required this.quotationId});

  final String quotationId;

  Color _getStatusColor(QuotationStatus status) => switch (status) {
        QuotationStatus.accepted => const Color(0xFF10B981),
        QuotationStatus.rejected => const Color(0xFFEF4444),
        QuotationStatus.sent => const Color(0xFF06B6D4),
        QuotationStatus.viewed => const Color(0xFF8B5CF6),
        QuotationStatus.expired => const Color(0xFFF59E0B),
        QuotationStatus.draft => AppColors.textSecondary,
      };

  String _getStatusLabel(QuotationStatus status) => switch (status) {
        QuotationStatus.accepted => 'Accepted',
        QuotationStatus.rejected => 'Rejected',
        QuotationStatus.sent => 'Sent',
        QuotationStatus.viewed => 'Viewed',
        QuotationStatus.expired => 'Expired',
        QuotationStatus.draft => 'Draft',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final quotation =
        ref.watch(quotationNotifierProvider.notifier).findById(quotationId);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (quotation == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar:
            DashboardAppBar(email: authState.userEmail, showBackButton: true),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.description_outlined,
                  size: 64, color: AppColors.textHint),
              const SizedBox(height: AppSpacing.md),
              Text('Quotation not found.',
                  style: AppTextStyles.h2
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => context.go(AppRoutes.quotations),
                child: const Text('Back to Quotations'),
              ),
            ],
          ),
        ),
      );
    }

    final actionButtons = Wrap(
      spacing: context.responsive.spacing(AppSpacing.sm),
      runSpacing: context.responsive.spacing(AppSpacing.sm),
      children: [
        FilledButton.icon(
          onPressed: () => _showSendOptionsDialog(context, quotation),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: EdgeInsets.symmetric(
              horizontal: context.responsive.spacing(20), 
              vertical: context.responsive.spacing(12),
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.responsive.borderRadius(AppBorderRadius.md))),
          ),
          icon: Icon(Icons.send_rounded,
              size: context.responsive.iconSize(18), color: AppColors.textOnPrimary),
          label: Text('Send Quotation',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textOnPrimary,
                fontSize: context.responsive.fontSize(14),
              )),
        ),
        OutlinedButton.icon(
          onPressed: () => _confirmDelete(context, ref, quotation),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.error),
            padding: EdgeInsets.symmetric(
              horizontal: context.responsive.spacing(16), 
              vertical: context.responsive.spacing(12),
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.responsive.borderRadius(AppBorderRadius.md))),
          ),
          icon: Icon(Icons.delete_rounded,
              size: context.responsive.iconSize(18), color: AppColors.error),
          label: Text('Delete',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.error,
                fontSize: context.responsive.fontSize(14),
              )),
        ),
      ],
    );

    return ScreenShell(
      currentRoute: AppRoutes.quotations,
      title: quotation.quotationNo,
      icon: Icons.description_rounded,
      onBack: () => context.go(AppRoutes.quotations),
      actions: actionButtons,
      body: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: Column(
                    children: [
                      _QuotationHeader(quotation: quotation),
                      SizedBox(height: context.responsive.spacing(AppSpacing.lg)),
                      _QuotationMeta(quotation: quotation, statusLabel: _getStatusLabel(quotation.status), statusColor: _getStatusColor(quotation.status)),
                      SizedBox(height: context.responsive.spacing(AppSpacing.lg)),
                      _CustomerCard(quotation: quotation),
                      SizedBox(height: context.responsive.spacing(AppSpacing.lg)),
                      _LineItemsTable(quotation: quotation),
                      if (quotation.terms != null || quotation.notes != null) ...[
                        SizedBox(height: context.responsive.spacing(AppSpacing.lg)),
                        _NotesCard(quotation: quotation),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: context.responsive.spacing(AppSpacing.xl)),
                SizedBox(
                  width: 300,
                  child: Column(
                    children: [
                      _FinancialSummary(quotation: quotation),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                _QuotationHeader(quotation: quotation),
                SizedBox(height: context.responsive.spacing(AppSpacing.lg)),
                _QuotationMeta(quotation: quotation, statusLabel: _getStatusLabel(quotation.status), statusColor: _getStatusColor(quotation.status)),
                SizedBox(height: context.responsive.spacing(AppSpacing.lg)),
                _CustomerCard(quotation: quotation),
                SizedBox(height: context.responsive.spacing(AppSpacing.lg)),
                _LineItemsTable(quotation: quotation),
                SizedBox(height: context.responsive.spacing(AppSpacing.lg)),
                _FinancialSummary(quotation: quotation),
                if (quotation.terms != null || quotation.notes != null) ...[
                  SizedBox(height: context.responsive.spacing(AppSpacing.lg)),
                  _NotesCard(quotation: quotation),
                ],
              ],
            ),
    );
  }

  void _showSendOptionsDialog(BuildContext context, QuotationModel q) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final fmtDate = DateFormat('dd MMM yyyy');
    showDialog(
      context: context,
      builder: (_) => SendOptionsDialog(
        title: 'Quotation',
        invoiceId: q.id,
        invoiceNo: q.quotationNo,
        whatsappText: [
          '*Naiyo24 Quotation*',
          'Quotation No: ${q.quotationNo}',
          'Client: ${q.customerName}',
          'Amount: ${fmt.format(q.grandTotal)}',
        ].join('\n'),
        pdfContent: [
          'Naiyo24 Business Tool - Quotation',
          '========================================',
          'Quotation No: ${q.quotationNo}',
          'Client: ${q.customerName}',
          'Date: ${fmtDate.format(q.quotationDate)}',
          'Amount: ${fmt.format(q.grandTotal)}',
        ].join('\n'),
        filenamePrefix: 'quotation',
        onClose: () {},
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, QuotationModel quotation) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Quotation'),
        content: Text(
            'Delete ${quotation.quotationNo} for ${quotation.customerName}? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnPrimary,
            ),
            onPressed: () {
              ref
                  .read(quotationNotifierProvider.notifier)
                  .deleteQuotation(quotation.id);
              Navigator.pop(ctx);
              context.go(AppRoutes.quotations);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _QuotationHeader extends StatelessWidget {
  const _QuotationHeader({required this.quotation});
  final QuotationModel quotation;

  @override
  Widget build(BuildContext context) {
    final hasLogo = quotation.logo != null && quotation.logo!.isNotEmpty;
    ImageProvider? imageProvider;
    if (hasLogo) {
      try {
        final pureBase64 = quotation.logo!.contains(',')
            ? quotation.logo!.substring(quotation.logo!.indexOf(',') + 1)
            : quotation.logo!;
        imageProvider = MemoryImage(base64Decode(pureBase64));
      } catch (_) {}
    }

    final hasSubtitle = quotation.subtitle != null && quotation.subtitle!.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(context.responsive.spacing(AppSpacing.lg)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(context.responsive.borderRadius(AppBorderRadius.lg)),
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
                  'QUOTATION',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    fontSize: context.responsive.fontSize(10),
                  ),
                ),
                SizedBox(height: context.responsive.spacing(4)),
                Text(
                  quotation.quotationNo,
                  style: AppTextStyles.h1.copyWith(fontSize: context.responsive.fontSize(24)),
                ),
                if (hasSubtitle) ...[
                  SizedBox(height: context.responsive.spacing(4)),
                  Text(
                    quotation.subtitle!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: context.responsive.fontSize(14),
                    ),
                  ),
                ],
                if (quotation.settings?['gst']?['gstin'] != null &&
                    quotation.settings?['gst']?['gstin'].toString().isNotEmpty == true) ...[
                  SizedBox(height: context.responsive.spacing(8)),
                  Text(
                    'GSTIN: ${quotation.settings?['gst']?['gstin']}',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: context.responsive.fontSize(10),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (imageProvider != null) ...[
            SizedBox(width: context.responsive.spacing(AppSpacing.md)),
            Container(
              constraints: BoxConstraints(
                maxHeight: context.responsive.spacing(70), 
                maxWidth: context.responsive.spacing(120),
              ),
              child: Image(image: imageProvider, fit: BoxFit.contain),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuotationMeta extends StatelessWidget {
  const _QuotationMeta({
    required this.quotation,
    required this.statusLabel,
    required this.statusColor,
  });

  final QuotationModel quotation;
  final String statusLabel;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    return Container(
      padding: EdgeInsets.all(context.responsive.spacing(AppSpacing.lg)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(context.responsive.borderRadius(AppBorderRadius.lg)),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: context.responsive.spacing(AppSpacing.xl),
        runSpacing: context.responsive.spacing(AppSpacing.md),
        children: [
          _metaTile('Quotation Date', fmt(quotation.quotationDate),
              Icons.calendar_today_rounded, AppColors.textSecondary, context),
          _metaTile('Valid Until', fmt(quotation.validUntil), Icons.event_rounded,
              AppColors.textSecondary, context),
          if (quotation.paymentTerms.isNotEmpty)
            _metaTile('Payment Terms', quotation.paymentTerms,
                Icons.description_rounded, AppColors.textSecondary, context),
          if (quotation.reference != null && quotation.reference!.isNotEmpty)
            _metaTile('Reference No.', quotation.reference!,
                Icons.tag_rounded, AppColors.textSecondary, context),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status',
                  style: AppTextStyles.caption
                      .copyWith(
                        color: AppColors.textSecondary,
                        fontSize: context.responsive.fontSize(10),
                      )),
              SizedBox(height: context.responsive.spacing(4)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive.spacing(12), 
                  vertical: context.responsive.spacing(6),
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(context.responsive.borderRadius(AppBorderRadius.full)),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(statusLabel,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: statusColor, 
                      fontWeight: FontWeight.w400,
                      fontSize: context.responsive.fontSize(14),
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaTile(String label, String value, IconData icon, Color iconColor, BuildContext context) {
    return SizedBox(
      width: context.responsive.spacing(160),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(
                    color: AppColors.textSecondary,
                    fontSize: context.responsive.fontSize(10),
                  )),
          SizedBox(height: context.responsive.spacing(4)),
          Row(
            children: [
              Icon(icon, size: context.responsive.iconSize(14), color: iconColor),
              SizedBox(width: context.responsive.spacing(5)),
              Flexible(
                child: Text(value,
                    style: AppTextStyles.bodyMedium
                        .copyWith(
                          fontWeight: FontWeight.w400,
                          fontSize: context.responsive.fontSize(14),
                        )),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.quotation});
  final QuotationModel quotation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.responsive.spacing(AppSpacing.lg)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(context.responsive.borderRadius(AppBorderRadius.lg)),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: context.responsive.spacing(26),
            backgroundColor: AppColors.primary,
            child: Text(
              quotation.customerName[0].toUpperCase(),
              style:
                  AppTextStyles.h2.copyWith(
                    color: AppColors.textOnPrimary, 
                    fontSize: context.responsive.fontSize(20),
                  ),
            ),
          ),
          SizedBox(width: context.responsive.spacing(AppSpacing.md)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Client Detail',
                    style: AppTextStyles.caption
                        .copyWith(
                          color: AppColors.textSecondary,
                          fontSize: context.responsive.fontSize(10),
                        )),
                SizedBox(height: context.responsive.spacing(2)),
                Text(quotation.customerName, style: AppTextStyles.h2.copyWith(fontSize: context.responsive.fontSize(18))),
                SizedBox(height: context.responsive.spacing(4)),
                _row(Icons.phone_rounded, quotation.customerMobile, context),
                if (quotation.customerAddress != null && quotation.customerAddress!.isNotEmpty)
                  _row(Icons.location_on_rounded, quotation.customerAddress!, context),
                if (quotation.customerGst != null && quotation.customerGst!.isNotEmpty)
                  _row(
                      Icons.business_rounded, 'GSTIN: ${quotation.customerGst!}', context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text, BuildContext context) => Padding(
        padding: EdgeInsets.only(top: context.responsive.spacing(3)),
        child: Row(
          children: [
            Icon(icon, size: context.responsive.iconSize(14), color: AppColors.textSecondary),
            SizedBox(width: context.responsive.spacing(5)),
            Expanded(
              child: Text(text,
                  style: AppTextStyles.caption
                      .copyWith(
                        color: AppColors.textSecondary,
                        fontSize: context.responsive.fontSize(10),
                      )),
            ),
          ],
        ),
      );
}

class _LineItemsTable extends StatelessWidget {
  const _LineItemsTable({required this.quotation});
  final QuotationModel quotation;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(context.responsive.borderRadius(AppBorderRadius.lg)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(context.responsive.spacing(AppSpacing.lg)),
            child: Text('Line Items',
                style: AppTextStyles.labelLarge
                    .copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: context.responsive.fontSize(14),
                    )),
          ),
          Divider(height: 1, color: AppColors.border),
          _buildTable(context),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context) {
    final columnsSettings = quotation.settings?['columns'] as Map<String, dynamic>? ?? {
      'hsn': true,
      'discount': true,
      'gst': true,
      'unit': true,
      'category': true,
    };
    final gstEnabled = quotation.settings?['gst']?['enabled'] as bool? ?? true;

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
          rows: quotation.lineItems.map((item) {
            return DataRow(cells: [
              DataCell(Text(item.name)),
              if (showHsn) DataCell(Text(item.code.isNotEmpty ? item.code : '-')),
              DataCell(Text(item.qty.toStringAsFixed(0))),
              DataCell(Text(_formatCurrency(item.rate, quotation.settings))),
              if (showDiscount) DataCell(Text('${item.discountPercent}%')),
              if (showGst) DataCell(Text('${item.gstPercent}%')),
              DataCell(Text(_formatCurrency(item.totalAmount, quotation.settings),
                  style: const TextStyle(fontWeight: FontWeight.bold))),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

class _FinancialSummary extends StatelessWidget {
  const _FinancialSummary({required this.quotation});
  final QuotationModel quotation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.responsive.spacing(AppSpacing.lg)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(context.responsive.borderRadius(AppBorderRadius.lg)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Financial Summary',
              style: AppTextStyles.labelLarge
                  .copyWith(
                    fontWeight: FontWeight.w400,
                    fontSize: context.responsive.fontSize(14),
                  )),
          SizedBox(height: context.responsive.spacing(AppSpacing.md)),
          _row('Sub Total', _formatCurrency(quotation.subTotal, quotation.settings), context),
          if (quotation.totalDiscount > 0)
            _row('Discount', '- ${_formatCurrency(quotation.totalDiscount, quotation.settings)}', context,
                color: AppColors.success),
          if (quotation.settings?['gst']?['enabled'] != false)
            _row('GST', _formatCurrency(quotation.totalGst, quotation.settings), context),
          Divider(color: AppColors.border, height: context.responsive.spacing(AppSpacing.xl)),
          _row('Grand Total', _formatCurrency(quotation.grandTotal, quotation.settings), context,
              bold: true, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _row(String label, String value, BuildContext context, {bool bold = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.responsive.spacing(5)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.bodyMedium
                  .copyWith(
                    color: AppColors.textSecondary,
                    fontSize: context.responsive.fontSize(14),
                  )),
          Text(value,
              style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: color ?? AppColors.textPrimary,
                  fontSize: context.responsive.fontSize(bold ? 16 : 14))),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.quotation});
  final QuotationModel quotation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.responsive.spacing(AppSpacing.lg)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(context.responsive.borderRadius(AppBorderRadius.lg)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (quotation.terms != null && quotation.terms!.isNotEmpty) ...[
            Text('Terms & Conditions',
                style: AppTextStyles.labelLarge
                    .copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: context.responsive.fontSize(14),
                    )),
            SizedBox(height: context.responsive.spacing(AppSpacing.xs)),
            Text(quotation.terms!,
                style: AppTextStyles.bodyMedium
                    .copyWith(
                      color: AppColors.textSecondary,
                      fontSize: context.responsive.fontSize(14),
                    )),
            if (quotation.notes != null && quotation.notes!.isNotEmpty)
              Divider(height: context.responsive.spacing(AppSpacing.xl)),
          ],
          if (quotation.notes != null && quotation.notes!.isNotEmpty) ...[
            Text('Notes',
                style: AppTextStyles.labelLarge
                    .copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: context.responsive.fontSize(14),
                    )),
            SizedBox(height: context.responsive.spacing(AppSpacing.xs)),
            Text(quotation.notes!,
                style: AppTextStyles.bodyMedium
                    .copyWith(
                      color: AppColors.textSecondary,
                      fontSize: context.responsive.fontSize(14),
                    )),
          ],
        ],
      ),
    );
  }
}

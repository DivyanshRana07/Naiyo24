import 'package:flutter/material.dart';
import 'package:naiyo24_business_tool/models/invoice_model.dart';
import 'package:naiyo24_business_tool/widgets/common/badges.dart';

/// Status badge for invoices — maps [InvoiceStatus] to a coloured [BadgeWidget].
class InvoiceStatusBadge extends StatelessWidget {
  const InvoiceStatusBadge({super.key, required this.status});
  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, badgeStatus) = switch (status) {
      InvoiceStatus.paid => ('Paid', BadgeStatus.success),
      InvoiceStatus.partial => ('Partial', BadgeStatus.warning),
      InvoiceStatus.due => ('Due', BadgeStatus.error),
    };
    return BadgeWidget.status(label: label, status: badgeStatus);
  }
}

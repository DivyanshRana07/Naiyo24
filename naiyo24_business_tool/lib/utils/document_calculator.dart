import 'package:naiyo24_business_tool/models/line_item_model.dart';

class DocumentCalculator {
  static double getSubTotal(List<InvoiceLineItem> items, Map<String, dynamic> settings) {
    final gstEnabled = settings['gst']?['enabled'] as bool? ?? true;
    final isInclusive = settings['gst']?['isInclusive'] as bool? ?? false;
    
    if (gstEnabled && isInclusive) {
      return items.fold(0.0, (s, i) {
        final totalAmount = i.rate * i.qty;
        final taxable = totalAmount / (1 + i.gstPercent / 100);
        return s + taxable;
      });
    }
    return items.fold(0.0, (s, i) => s + (i.rate * i.qty));
  }

  static double getTotalDiscount(List<InvoiceLineItem> items) {
    return items.fold(0.0, (s, i) => s + i.discountAmount);
  }

  static double getTotalGst(List<InvoiceLineItem> items, Map<String, dynamic> settings) {
    final gstEnabled = settings['gst']?['enabled'] as bool? ?? true;
    final isInclusive = settings['gst']?['isInclusive'] as bool? ?? false;
    
    if (!gstEnabled) return 0.0;
    if (isInclusive) {
      return items.fold(0.0, (s, i) {
        final totalAmount = i.rate * i.qty - i.discountAmount;
        final taxable = totalAmount / (1 + i.gstPercent / 100);
        return s + (totalAmount - taxable);
      });
    }
    return items.fold(0.0, (s, i) => s + i.gstAmount);
  }

  static double getGrandTotal(List<InvoiceLineItem> items, Map<String, dynamic> settings) {
    final gstEnabled = settings['gst']?['enabled'] as bool? ?? true;
    final isInclusive = settings['gst']?['isInclusive'] as bool? ?? false;
    
    if (gstEnabled && isInclusive) {
      return items.fold(0.0, (s, i) => s + (i.rate * i.qty - i.discountAmount));
    }
    return getSubTotal(items, settings) - getTotalDiscount(items) + getTotalGst(items, settings);
  }
}

/// Shared line-item model used by Invoices and Quotations.
///
/// Kept in the model layer so that notifiers can import it without
/// depending on the widget layer.
class InvoiceLineItem {
  const InvoiceLineItem({
    required this.id,
    required this.itemType,
    required this.itemId,
    required this.code,
    required this.name,
    required this.qty,
    required this.rate,
    this.discountPercent = 0.0,
    this.gstPercent = 0.0,
  });

  final String id;
  final LineItemType itemType;
  final String itemId;
  final String code;
  final String name;
  final double qty;
  final double rate;
  final double discountPercent;
  final double gstPercent;

  double get discountAmount => (rate * qty) * (discountPercent / 100);
  double get baseAmount => (rate * qty) - discountAmount;
  double get gstAmount => baseAmount * (gstPercent / 100);
  double get totalAmount => baseAmount + gstAmount;

  InvoiceLineItem copyWith({
    String? id,
    LineItemType? itemType,
    String? itemId,
    String? code,
    String? name,
    double? qty,
    double? rate,
    double? discountPercent,
    double? gstPercent,
  }) {
    return InvoiceLineItem(
      id: id ?? this.id,
      itemType: itemType ?? this.itemType,
      itemId: itemId ?? this.itemId,
      code: code ?? this.code,
      name: name ?? this.name,
      qty: qty ?? this.qty,
      rate: rate ?? this.rate,
      discountPercent: discountPercent ?? this.discountPercent,
      gstPercent: gstPercent ?? this.gstPercent,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemType': itemType.name,
        'itemId': itemId,
        'code': code,
        'name': name,
        'qty': qty,
        'rate': rate,
        'discountPercent': discountPercent,
        'gstPercent': gstPercent,
      };

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) {
    // Handle both invoice format and quotation item format from backend
    final typeStr = json['itemType'] as String? ?? json['item_type'] as String? ?? 'item';
    final itemType = (typeStr == 'product' || typeStr == 'item')
        ? LineItemType.item
        : LineItemType.service;
    
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    return InvoiceLineItem(
      id: json['id']?.toString() ?? json['quotation_item_id']?.toString() ?? '',
      itemType: itemType,
      itemId: json['itemId'] as String? ?? json['item_id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      qty: json['qty'] != null 
          ? toDouble(json['qty'])
          : toDouble(json['quantity'] ?? 1.0),
      rate: json['rate'] != null
          ? toDouble(json['rate'])
          : toDouble(json['price']),
      discountPercent: json['discountPercent'] != null
          ? toDouble(json['discountPercent'])
          : toDouble(json['discount_percent']),
      gstPercent: json['gstPercent'] != null
          ? toDouble(json['gstPercent'])
          : toDouble(json['gst_percent'] ?? json['gst_rate']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is InvoiceLineItem && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

enum LineItemType { item, service }

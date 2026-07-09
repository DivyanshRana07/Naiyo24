import 'package:naiyo24_business_tool/models/line_item_model.dart';

class InvoiceModel {
  const InvoiceModel({
    required this.id,
    required this.invoiceNo,
    required this.customerId,
    required this.customerName,
    required this.customerMobile,
    required this.customerAddress,
    required this.customerGst,
    required this.invoiceDate,
    required this.dueDate,
    required this.lineItems,
    required this.paymentMethod,
    required this.paidAmount,
    this.invoiceType = 'regular',
    this.roundOff = 0.0,
    this.notes,
    this.status = InvoiceStatus.due,
    this.subtitle,
    this.logo,
    this.settings,
  });

  final String id;
  final String invoiceNo;
  final String customerId;
  final String customerName;
  final String customerMobile;
  final String? customerAddress;
  final String? customerGst;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final List<InvoiceLineItem> lineItems;
  final String paymentMethod;
  final double paidAmount;
  final String invoiceType; // 'regular' or 'proforma'
  final double roundOff;
  final String? notes;
  final InvoiceStatus status;
  final String? subtitle;
  final String? logo;
  final Map<String, dynamic>? settings;

  double get subTotal =>
      lineItems.fold(0, (sum, item) => sum + (item.rate * item.qty));

  double get totalDiscount =>
      lineItems.fold(0, (sum, item) => sum + item.discountAmount);

  double get totalGst => lineItems.fold(0, (sum, item) => sum + item.gstAmount);

  double get grandTotal => subTotal - totalDiscount + totalGst + roundOff;

  double get dueAmount => grandTotal - paidAmount;

  InvoiceModel copyWith({
    String? id,
    String? invoiceNo,
    String? customerId,
    String? customerName,
    String? customerMobile,
    String? customerAddress,
    String? customerGst,
    DateTime? invoiceDate,
    DateTime? dueDate,
    List<InvoiceLineItem>? lineItems,
    String? paymentMethod,
    double? paidAmount,
    String? invoiceType,
    double? roundOff,
    String? notes,
    InvoiceStatus? status,
    String? subtitle,
    String? logo,
    Map<String, dynamic>? settings,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerMobile: customerMobile ?? this.customerMobile,
      customerAddress: customerAddress ?? this.customerAddress,
      customerGst: customerGst ?? this.customerGst,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      lineItems: lineItems ?? this.lineItems,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAmount: paidAmount ?? this.paidAmount,
      invoiceType: invoiceType ?? this.invoiceType,
      roundOff: roundOff ?? this.roundOff,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      subtitle: subtitle ?? this.subtitle,
      logo: logo ?? this.logo,
      settings: settings ?? this.settings,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'invoiceNo': invoiceNo,
        'customerId': customerId,
        'customerName': customerName,
        'customerMobile': customerMobile,
        'customerAddress': customerAddress,
        'customerGst': customerGst,
        'invoiceDate': invoiceDate.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'lineItems': lineItems.map((e) => e.toJson()).toList(),
        'paymentMethod': paymentMethod,
        'paidAmount': paidAmount,
        'invoiceType': invoiceType,
        'roundOff': roundOff,
        'notes': notes,
        'status': status.name,
        'subtitle': subtitle,
        'logo': logo,
        'settings': settings,
      };

  factory InvoiceModel.fromJson(Map<String, dynamic> json) => InvoiceModel(
        id: json['id']?.toString() ?? '',
        invoiceNo: json['invoiceNo'] as String? ?? json['invoice_number'] as String? ?? '',
        customerId: json['customerId'] as String? ?? '',
        customerName: json['customerName'] as String? ?? '',
        customerMobile: json['customerMobile'] as String? ?? '',
        customerAddress: json['customerAddress'] as String?,
        customerGst: json['customerGst'] as String?,
        invoiceDate: DateTime.parse((json['invoiceDate'] ?? json['invoice_date']) as String),
        dueDate: json['dueDate'] != null
            ? DateTime.parse(json['dueDate'] as String)
            : (json['due_date'] != null
                ? DateTime.parse(json['due_date'] as String)
                : DateTime.parse((json['invoiceDate'] ?? json['invoice_date']) as String).add(const Duration(days: 15))),
        lineItems: (json['lineItems'] as List? ?? json['items'] as List? ?? [])
            .map((e) => InvoiceLineItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        paymentMethod: json['paymentMethod'] as String? ?? json['payment_method'] as String? ?? 'Cash',
        paidAmount: (json['paidAmount'] ?? json['paid_amount'] as num?)?.toDouble() ?? 0.0,
        invoiceType: json['invoiceType'] as String? ?? json['invoice_type'] as String? ?? 'regular',
        roundOff: (json['roundOff'] ?? json['round_off'] as num?)?.toDouble() ?? 0.0,
        notes: json['notes'] as String?,
        status: InvoiceStatus.values.byName(
          (json['status'] as String? ?? 'due').toLowerCase(),
        ),
        subtitle: json['subtitle'] as String?,
        logo: json['logo'] as String?,
        settings: json['settings'] as Map<String, dynamic>?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is InvoiceModel && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'InvoiceModel($invoiceNo, customer: $customerName)';
}

enum InvoiceStatus {
  paid,

  partial,

  due,
}

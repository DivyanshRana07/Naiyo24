import 'package:naiyo24_business_tool/models/line_item_model.dart';

class QuotationModel {
  const QuotationModel({
    required this.id,
    required this.quotationNo,
    required this.customerId,
    required this.customerName,
    required this.customerMobile,
    required this.customerAddress,
    required this.customerGst,
    required this.quotationDate,
    required this.validUntil,
    this.reference,
    required this.lineItems,
    required this.paymentTerms,
    required this.currency,
    this.terms,
    this.notes,
    this.attachedFilePath,
    this.status = QuotationStatus.draft,
    this.subtitle,
    this.logo,
    this.settings,
  });

  final String id;

  final String quotationNo;

  final String customerId;
  final String customerName;
  final String customerMobile;
  final String? customerAddress;
  final String? customerGst;

  final DateTime quotationDate;
  final DateTime validUntil;
  final String? reference;

  final List<InvoiceLineItem> lineItems;

  final String paymentTerms;
  final String currency;

  final String? terms;
  final String? notes;

  final String? attachedFilePath;

  final QuotationStatus status;
  final String? subtitle;
  final String? logo;
  final Map<String, dynamic>? settings;

  double get subTotal =>
      lineItems.fold(0, (sum, item) => sum + (item.rate * item.qty));

  double get totalDiscount =>
      lineItems.fold(0, (sum, item) => sum + item.discountAmount);

  double get totalGst => lineItems.fold(0, (sum, item) => sum + item.gstAmount);

  double get taxableAmount => subTotal - totalDiscount;

  double get grandTotal => taxableAmount + totalGst;

  QuotationModel copyWith({
    String? id,
    String? quotationNo,
    String? customerId,
    String? customerName,
    String? customerMobile,
    String? customerAddress,
    String? customerGst,
    DateTime? quotationDate,
    DateTime? validUntil,
    String? reference,
    List<InvoiceLineItem>? lineItems,
    String? paymentTerms,
    String? currency,
    String? terms,
    String? notes,
    String? attachedFilePath,
    QuotationStatus? status,
    String? subtitle,
    String? logo,
    Map<String, dynamic>? settings,
  }) {
    return QuotationModel(
      id: id ?? this.id,
      quotationNo: quotationNo ?? this.quotationNo,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerMobile: customerMobile ?? this.customerMobile,
      customerAddress: customerAddress ?? this.customerAddress,
      customerGst: customerGst ?? this.customerGst,
      quotationDate: quotationDate ?? this.quotationDate,
      validUntil: validUntil ?? this.validUntil,
      reference: reference ?? this.reference,
      lineItems: lineItems ?? this.lineItems,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      currency: currency ?? this.currency,
      terms: terms ?? this.terms,
      notes: notes ?? this.notes,
      attachedFilePath: attachedFilePath ?? this.attachedFilePath,
      status: status ?? this.status,
      subtitle: subtitle ?? this.subtitle,
      logo: logo ?? this.logo,
      settings: settings ?? this.settings,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'quotationNo': quotationNo,
        'customerId': customerId,
        'customerName': customerName,
        'customerMobile': customerMobile,
        'customerAddress': customerAddress,
        'customerGst': customerGst,
        'quotationDate': quotationDate.toIso8601String(),
        'validUntil': validUntil.toIso8601String(),
        'reference': reference,
        'lineItems': lineItems.map((e) => e.toJson()).toList(),
        'paymentTerms': paymentTerms,
        'currency': currency,
        'terms': terms,
        'notes': notes,
        'attachedFilePath': attachedFilePath,
        'status': status.name,
        'subtitle': subtitle,
        'logo': logo,
        'settings': settings,
      };

  factory QuotationModel.fromJson(Map<String, dynamic> json) {
    try {
      return QuotationModel(
        id: json['id']?.toString() ?? '',
        quotationNo: json['quotationNo'] as String? ?? json['quotation_no'] as String? ?? 'QT-${DateTime.now().millisecondsSinceEpoch}',
        customerId: json['customerId'] as String? ?? json['customer_id']?.toString() ?? '',
        customerName: json['customerName'] as String? ?? json['customer_name'] as String? ?? '',
        customerMobile: json['customerMobile'] as String? ?? json['customer_mobile'] as String? ?? '',
        customerAddress: json['customerAddress'] as String? ?? json['customer_address'] as String? ?? '',
        customerGst: json['customerGst'] as String? ?? json['customer_gst'] as String?,
        quotationDate: json['quotationDate'] != null 
            ? DateTime.parse(json['quotationDate'] as String)
            : (json['quotation_date'] != null
                ? DateTime.parse(json['quotation_date'] as String)
                : DateTime.now()),
        validUntil: json['validUntil'] != null
            ? DateTime.parse(json['validUntil'] as String)
            : (json['valid_until'] != null
                ? DateTime.parse(json['valid_until'] as String)
                : DateTime.now().add(const Duration(days: 30))),
        reference: json['reference'] as String?,
        lineItems: json['lineItems'] != null
            ? (json['lineItems'] as List)
                .map((e) => InvoiceLineItem.fromJson(e as Map<String, dynamic>))
                .toList()
            : (json['items'] != null
                ? (json['items'] as List)
                    .map((e) => InvoiceLineItem.fromJson(e as Map<String, dynamic>))
                    .toList()
                : []),
        paymentTerms: json['paymentTerms'] as String? ?? json['payment_terms'] as String? ?? 'Net 30 Days',
        currency: json['currency'] as String? ?? 'INR',
        terms: json['terms'] as String?,
        notes: json['notes'] as String?,
        attachedFilePath: json['attachedFilePath'] as String? ?? json['attached_file_path'] as String?,
        status: json['status'] != null
            ? QuotationStatus.values.byName((json['status'] as String).toLowerCase())
            : QuotationStatus.draft,
        subtitle: json['subtitle'] as String?,
        logo: json['logo'] as String?,
        settings: json['settings'] as Map<String, dynamic>?,
      );
    } catch (e) {
      // Log the error with the JSON data for debugging
      print('Error parsing QuotationModel from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is QuotationModel && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'QuotationModel($quotationNo, customer: $customerName)';
}

enum QuotationStatus {
  draft,
  sent,
  viewed,
  accepted,
  rejected,
  expired,
}

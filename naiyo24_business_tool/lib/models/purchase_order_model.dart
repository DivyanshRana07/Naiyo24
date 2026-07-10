import 'package:flutter/foundation.dart';

enum POStatus {
  payed,
  unpayed,
}

class PurchaseOrderItemModel {
  final String id;
  final String name;
  final double quantity;
  final double price;
  final double gstRate;
  final double lineTotal;

  const PurchaseOrderItemModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.gstRate,
    required this.lineTotal,
  });

  factory PurchaseOrderItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      gstRate: (json['gst_rate'] as num?)?.toDouble() ?? (json['gstRate'] as num?)?.toDouble() ?? 0.0,
      lineTotal: (json['line_total'] as num?)?.toDouble() ?? (json['lineTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PurchaseOrderModel {
  final String id;
  final String poNumber;
  final String title;
  final String description;
  final String vendorId;
  final String vendorName;
  final DateTime date;
  final double totalAmount;
  final POStatus status;
  final double gstAmount;
  final String? receiptImage;
  final List<PurchaseOrderItemModel> items;

  const PurchaseOrderModel({
    required this.id,
    required this.poNumber,
    required this.title,
    this.description = '',
    required this.vendorId,
    required this.vendorName,
    required this.date,
    required this.totalAmount,
    required this.status,
    this.gstAmount = 0.0,
    this.receiptImage,
    this.items = const [],
  });

  PurchaseOrderModel copyWith({
    String? id,
    String? poNumber,
    String? title,
    String? description,
    String? vendorId,
    String? vendorName,
    DateTime? date,
    double? totalAmount,
    POStatus? status,
    double? gstAmount,
    String? receiptImage,
    List<PurchaseOrderItemModel>? items,
  }) {
    return PurchaseOrderModel(
      id: id ?? this.id,
      poNumber: poNumber ?? this.poNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      date: date ?? this.date,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      gstAmount: gstAmount ?? this.gstAmount,
      receiptImage: receiptImage ?? this.receiptImage,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'poNumber': poNumber,
        'title': title,
        'description': description,
        'vendorId': vendorId,
        'vendorName': vendorName,
        'date': date.toIso8601String(),
        'totalAmount': totalAmount,
        'status': status.name,
        'gstAmount': gstAmount,
        'receiptImage': receiptImage,
        'items': items.map((i) => {
          'id': i.id,
          'name': i.name,
          'quantity': i.quantity,
          'price': i.price,
          'gst_rate': i.gstRate,
          'line_total': i.lineTotal,
        }).toList(),
      };

  factory PurchaseOrderModel.fromJson(Map<String, dynamic> json) {
    try {
      return PurchaseOrderModel(
        id: json['id']?.toString() ?? '',
        poNumber: json['poNumber'] as String? ?? json['po_number'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        vendorId: json['vendorId']?.toString() ?? json['vendor_id']?.toString() ?? '',
        vendorName: json['vendorName'] as String? ?? json['vendor_name'] as String? ?? '',
        date: json['date'] != null
            ? DateTime.parse(json['date'] as String)
            : (json['po_date'] != null
                ? DateTime.parse(json['po_date'] as String)
                : DateTime.now()),
        totalAmount: json['totalAmount'] != null
            ? (json['totalAmount'] as num).toDouble()
            : (json['total_amount'] != null
                ? (json['total_amount'] as num).toDouble()
                : 0.0),
        status: json['status'] != null
            ? _parseStatus(json['status'] as String)
            : POStatus.unpayed,
        gstAmount: json['gstAmount'] != null
            ? (json['gstAmount'] as num).toDouble()
            : (json['gst_amount'] != null
                ? (json['gst_amount'] as num).toDouble()
                : 0.0),
        receiptImage: json['receiptImage'] as String? ?? json['receipt_image'] as String?,
        items: (json['items'] as List?)
                ?.map((i) => PurchaseOrderItemModel.fromJson(i as Map<String, dynamic>))
                .toList() ??
            const [],
      );
    } catch (e) {
      debugPrint('Error parsing PurchaseOrderModel from JSON: $e');
      rethrow;
    }
  }

  static POStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'payed':
      case 'completed':
        return POStatus.payed;
      default:
        return POStatus.unpayed;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PurchaseOrderModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}


enum POStatus {
  payed,
  unpayed,
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
      );
    } catch (e) {
      print('Error parsing PurchaseOrderModel from JSON: $e');
      print('JSON data: $json');
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


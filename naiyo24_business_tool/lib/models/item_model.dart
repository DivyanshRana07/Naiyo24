class ItemModel {
  const ItemModel({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.unit,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.stockQty,
    required this.gstPercent,
    this.status = ItemStatus.active,
  });

  final String id;

  final String code;

  final String name;
  final String category;

  final String unit;

  final double purchasePrice;
  final double sellingPrice;
  final int stockQty;

  final double gstPercent;

  final ItemStatus status;

  ItemModel copyWith({
    String? id,
    String? code,
    String? name,
    String? category,
    String? unit,
    double? purchasePrice,
    double? sellingPrice,
    int? stockQty,
    double? gstPercent,
    ItemStatus? status,
  }) {
    return ItemModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stockQty: stockQty ?? this.stockQty,
      gstPercent: gstPercent ?? this.gstPercent,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'category': category,
        'unit': unit,
        'purchasePrice': purchasePrice,
        'sellingPrice': sellingPrice,
        'stockQty': stockQty,
        'gstPercent': gstPercent,
        'status': status.name,
      };

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    try {
      return ItemModel(
        id: json['id']?.toString() ?? '',
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        category: json['category'] as String? ?? '',
        unit: json['unit'] as String? ?? '',
        purchasePrice: json['purchasePrice'] != null
            ? (json['purchasePrice'] as num).toDouble()
            : (json['purchase_price'] != null
                ? (json['purchase_price'] as num).toDouble()
                : 0.0),
        sellingPrice: json['sellingPrice'] != null
            ? (json['sellingPrice'] as num).toDouble()
            : (json['selling_price'] != null
                ? (json['selling_price'] as num).toDouble()
                : 0.0),
        stockQty: json['stockQty'] != null
            ? (json['stockQty'] as num).toInt()
            : (json['stock_qty'] != null
                ? (json['stock_qty'] as num).toInt()
                : 0),
        gstPercent: json['gstPercent'] != null
            ? (json['gstPercent'] as num).toDouble()
            : (json['gst_percent'] != null
                ? (json['gst_percent'] as num).toDouble()
                : 0.0),
        status: json['status'] != null
            ? ItemStatus.values.byName(json['status'] as String)
            : ItemStatus.active,
      );
    } catch (e) {
      print('Error parsing ItemModel from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ItemModel && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ItemModel(code: $code, name: $name)';
}

enum ItemStatus { active, inactive }

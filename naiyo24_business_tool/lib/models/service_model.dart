class ServiceModel {
  const ServiceModel({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.sellingPrice,
    required this.gstPercent,
    this.status = ServiceStatus.active,
  });

  final String id;

  final String code;

  final String name;

  final String category;

  final double sellingPrice;

  final double gstPercent;

  final ServiceStatus status;

  ServiceModel copyWith({
    String? id,
    String? code,
    String? name,
    String? category,
    double? sellingPrice,
    double? gstPercent,
    ServiceStatus? status,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      category: category ?? this.category,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      gstPercent: gstPercent ?? this.gstPercent,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'category': category,
        'sellingPrice': sellingPrice,
        'gstPercent': gstPercent,
        'status': status.name,
      };

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
        id: json['id'] as String,
        code: json['code'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        sellingPrice: (json['sellingPrice'] as num).toDouble(),
        gstPercent: (json['gstPercent'] as num).toDouble(),
        status: ServiceStatus.values.byName(
          json['status'] as String? ?? 'active',
        ),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ServiceModel && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ServiceModel(code: $code, name: $name)';
}

enum ServiceStatus { active, inactive }

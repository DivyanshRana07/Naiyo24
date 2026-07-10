import 'package:flutter/foundation.dart';

class CustomerModel {
  const CustomerModel({
    required this.id,
    required this.code,
    required this.name,
    required this.mobile,
    this.email,
    this.address,
    this.gstNumber,
    this.openingBalance = 0.0,
    this.creditLimit = 0.0,
    this.status = CustomerStatus.active,
  });

  final String id;

  final String code;

  final String name;
  final String mobile;
  final String? email;
  final String? address;

  final String? gstNumber;

  final double openingBalance;

  final double creditLimit;

  final CustomerStatus status;

  CustomerModel copyWith({
    String? id,
    String? code,
    String? name,
    String? mobile,
    String? email,
    String? address,
    String? gstNumber,
    double? openingBalance,
    double? creditLimit,
    CustomerStatus? status,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      address: address ?? this.address,
      gstNumber: gstNumber ?? this.gstNumber,
      openingBalance: openingBalance ?? this.openingBalance,
      creditLimit: creditLimit ?? this.creditLimit,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'mobile': mobile,
        'email': email,
        'address': address,
        'gstNumber': gstNumber,
        'openingBalance': openingBalance,
        'creditLimit': creditLimit,
        'status': status.name,
      };

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    try {
      return CustomerModel(
        id: json['id']?.toString() ?? '',
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        mobile: json['mobile'] as String? ?? '',
        email: json['email'] as String?,
        address: json['address'] as String?,
        gstNumber: json['gstNumber'] as String? ?? json['gst_number'] as String?,
        openingBalance: json['openingBalance'] != null
            ? (json['openingBalance'] as num).toDouble()
            : (json['opening_balance'] != null
                ? (json['opening_balance'] as num).toDouble()
                : 0.0),
        creditLimit: json['creditLimit'] != null
            ? (json['creditLimit'] as num).toDouble()
            : (json['credit_limit'] != null
                ? (json['credit_limit'] as num).toDouble()
                : 0.0),
        status: json['status'] != null
            ? CustomerStatus.values.byName(json['status'] as String)
            : CustomerStatus.active,
      );
    } catch (e) {
      debugPrint('Error parsing CustomerModel from JSON: $e');
      debugPrint('JSON data: $json');
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CustomerModel && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CustomerModel(code: $code, name: $name)';
}

enum CustomerStatus { active, inactive }

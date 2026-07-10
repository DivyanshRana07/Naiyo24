import 'package:flutter/foundation.dart';

class VendorModel {
  final String id;
  final String name;
  final String contactPerson;
  final String email;
  final String phone;
  final String address;

  const VendorModel({
    required this.id,
    required this.name,
    this.contactPerson = '',
    this.email = '',
    this.phone = '',
    this.address = '',
  });

  VendorModel copyWith({
    String? id,
    String? name,
    String? contactPerson,
    String? email,
    String? phone,
    String? address,
  }) {
    return VendorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'contactPerson': contactPerson,
        'email': email,
        'phone': phone,
        'address': address,
      };

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    try {
      return VendorModel(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        contactPerson: json['contactPerson'] as String? ?? 
                       json['contact_person'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        address: json['address'] as String? ?? '',
      );
    } catch (e) {
      debugPrint('Error parsing VendorModel from JSON: $e');
      debugPrint('JSON data: $json');
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is VendorModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}


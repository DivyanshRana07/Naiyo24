import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:naiyo24_business_tool/api_services/api_routes.dart';
import 'package:naiyo24_business_tool/models/vendor_model.dart';

class VendorService {
  const VendorService();
  Future<List<VendorModel>> getVendors() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiRoutes.baseUrl}${ApiRoutes.vendorsList}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> vendorsJson = data['data'] as List;
        return vendorsJson.map((json) => VendorModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load vendors: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching vendors: $e');
    }
  }

  Future<VendorModel> createVendor({
    required String name,
    String? contactPerson,
    String? email,
    String? phone,
    String? address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiRoutes.baseUrl}${ApiRoutes.vendorsCreate}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'contact_person': contactPerson,
          'email': email,
          'phone': phone,
          'address': address,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return VendorModel.fromJson(data['data']);
      } else {
        throw Exception('Failed to create vendor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating vendor: $e');
    }
  }

  Future<VendorModel> updateVendor(int id, Map<String, dynamic> updates) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiRoutes.baseUrl}${ApiRoutes.vendorUpdate(id.toString())}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return VendorModel.fromJson(data['data']);
      } else {
        throw Exception('Failed to update vendor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating vendor: $e');
    }
  }

  Future<void> deleteVendor(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiRoutes.baseUrl}${ApiRoutes.vendorDelete(id.toString())}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete vendor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting vendor: $e');
    }
  }
}

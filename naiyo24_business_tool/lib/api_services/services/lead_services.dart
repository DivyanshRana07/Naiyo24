import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:naiyo24_business_tool/api_services/api_routes.dart';
import 'package:naiyo24_business_tool/models/lead_model.dart';
import 'package:naiyo24_business_tool/models/customer_model.dart';

class LeadService {
  const LeadService();
  Future<List<LeadModel>> getLeads({String? status}) async {
    try {
      var url = '${ApiRoutes.baseUrl}${ApiRoutes.leadsList}';
      if (status != null) {
        url += '?status=$status';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> leadsJson = data['data'] as List;
        return leadsJson.map((json) => LeadModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load leads: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching leads: $e');
    }
  }

  Future<LeadModel> createLead({
    required String name,
    String? email,
    String? phone,
    String? company,
    String? notes,
    String? source,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiRoutes.baseUrl}${ApiRoutes.leadsCreate}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'phone': phone,
          'company': company,
          'status': 'new',
          'notes': notes,
          'source': source,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return LeadModel.fromJson(data['data']);
      } else {
        throw Exception('Failed to create lead: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating lead: $e');
    }
  }

  Future<LeadModel> updateLead(int id, Map<String, dynamic> updates) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiRoutes.baseUrl}${ApiRoutes.leadUpdate(id.toString())}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return LeadModel.fromJson(data['data']);
      } else {
        throw Exception('Failed to update lead: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating lead: $e');
    }
  }

  Future<void> deleteLead(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiRoutes.baseUrl}${ApiRoutes.leadDelete(id.toString())}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete lead: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting lead: $e');
    }
  }

  Future<CustomerModel> convertToCustomer(int id) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiRoutes.baseUrl}${ApiRoutes.leadConvert(id.toString())}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CustomerModel.fromJson(data['data']);
      } else {
        throw Exception('Failed to convert lead: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error converting lead: $e');
    }
  }
}

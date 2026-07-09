import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:naiyo24_business_tool/api_services/api_routes.dart';
import 'package:naiyo24_business_tool/models/quotation_model.dart';

class QuotationService {
  static Future<List<QuotationModel>> getQuotations() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiRoutes.baseUrl}${ApiRoutes.quotationsList}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> quotationsJson = data['data'] as List;
        return quotationsJson.map((json) => QuotationModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load quotations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching quotations: $e');
    }
  }

  static Future<QuotationModel> createQuotation(Map<String, dynamic> quotationData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiRoutes.baseUrl}${ApiRoutes.quotationsCreate}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(quotationData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return QuotationModel.fromJson(data['data']);
      } else {
        final errorBody = response.body;
        throw Exception('Failed to create quotation (${response.statusCode}): $errorBody');
      }
    } catch (e) {
      throw Exception('Error creating quotation: $e');
    }
  }

  static Future<QuotationModel> updateQuotation(int id, Map<String, dynamic> updates) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiRoutes.baseUrl}${ApiRoutes.quotationUpdate(id.toString())}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return QuotationModel.fromJson(data['data']);
      } else {
        throw Exception('Failed to update quotation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating quotation: $e');
    }
  }

  static Future<void> deleteQuotation(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiRoutes.baseUrl}${ApiRoutes.quotationDelete(id.toString())}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete quotation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting quotation: $e');
    }
  }
}

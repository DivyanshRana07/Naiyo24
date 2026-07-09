import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:naiyo24_business_tool/api_services/api_routes.dart';
import 'package:naiyo24_business_tool/models/purchase_order_model.dart';

class PurchaseOrderService {
  static Future<List<PurchaseOrderModel>> getPurchaseOrders() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiRoutes.baseUrl}${ApiRoutes.purchaseOrdersList}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> posJson = data['data'] as List;
        return posJson.map((json) => PurchaseOrderModel.fromJson(json)).toList();
      } else {
        final errorBody = response.body;
        throw Exception('Failed to load purchase orders (${response.statusCode}): $errorBody');
      }
    } catch (e) {
      throw Exception('Error fetching purchase orders: $e');
    }
  }

  static Future<PurchaseOrderModel> createPurchaseOrder(Map<String, dynamic> poData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiRoutes.baseUrl}${ApiRoutes.purchaseOrdersCreate}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(poData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PurchaseOrderModel.fromJson(data['data']);
      } else {
        final errorBody = response.body;
        throw Exception('Failed to create purchase order (${response.statusCode}): $errorBody');
      }
    } catch (e) {
      throw Exception('Error creating purchase order: $e');
    }
  }

  static Future<PurchaseOrderModel> updatePurchaseOrder(int id, Map<String, dynamic> updates) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiRoutes.baseUrl}${ApiRoutes.purchaseOrderUpdate(id.toString())}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PurchaseOrderModel.fromJson(data['data']);
      } else {
        final errorBody = response.body;
        throw Exception('Failed to update purchase order (${response.statusCode}): $errorBody');
      }
    } catch (e) {
      throw Exception('Error updating purchase order: $e');
    }
  }

  static Future<void> deletePurchaseOrder(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiRoutes.baseUrl}${ApiRoutes.purchaseOrderDelete(id.toString())}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        final errorBody = response.body;
        throw Exception('Failed to delete purchase order (${response.statusCode}): $errorBody');
      }
    } catch (e) {
      throw Exception('Error deleting purchase order: $e');
    }
  }
}

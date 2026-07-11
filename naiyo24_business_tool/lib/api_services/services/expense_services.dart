import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:naiyo24_business_tool/api_services/api_routes.dart';
import 'package:naiyo24_business_tool/models/expense_model.dart';

class ExpenseService {
  const ExpenseService();
  
  Future<List<ExpenseModel>> getExpenses() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiRoutes.baseUrl}${ApiRoutes.expensesList}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> expensesJson = data['data'] as List;
        return expensesJson.map((json) => ExpenseModel.fromJson(json)).toList();
      } else {
        final errorBody = response.body;
        throw Exception('Failed to load expenses (${response.statusCode}): $errorBody');
      }
    } catch (e) {
      throw Exception('Error fetching expenses: $e');
    }
  }

  Future<ExpenseModel> createExpense(Map<String, dynamic> expenseData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiRoutes.baseUrl}${ApiRoutes.expensesCreate}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(expenseData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ExpenseModel.fromJson(data['data']);
      } else {
        final errorBody = response.body;
        throw Exception('Failed to create expense (${response.statusCode}): $errorBody');
      }
    } catch (e) {
      throw Exception('Error creating expense: $e');
    }
  }

  Future<ExpenseModel> updateExpense(int id, Map<String, dynamic> updates) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiRoutes.baseUrl}${ApiRoutes.expenseUpdate(id.toString())}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ExpenseModel.fromJson(data['data']);
      } else {
        final errorBody = response.body;
        throw Exception('Failed to update expense (${response.statusCode}): $errorBody');
      }
    } catch (e) {
      throw Exception('Error updating expense: $e');
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiRoutes.baseUrl}${ApiRoutes.expenseDelete(id.toString())}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        final errorBody = response.body;
        throw Exception('Failed to delete expense (${response.statusCode}): $errorBody');
      }
    } catch (e) {
      throw Exception('Error deleting expense: $e');
    }
  }
}

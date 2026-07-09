import 'package:dio/dio.dart';
import 'package:naiyo24_business_tool/api_services/api_client.dart';
import 'package:naiyo24_business_tool/api_services/api_routes.dart';
import 'package:naiyo24_business_tool/models/customer_model.dart';
import 'package:naiyo24_business_tool/utils/logger.dart';

class CustomerService {
  final ApiClient _client;

  CustomerService(this._client);

  Future<List<CustomerModel>> listCustomers() async {
    try {
      final response = await _client.dio.get(ApiRoutes.customers);
      if (response.data['success'] == true) {
        final list = response.data['data'] as List;
        return list.map((e) => CustomerModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to load customers');
    } on DioException catch (e, st) {
      AppLogger.error('listCustomers API error', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<CustomerModel> createCustomer(CustomerModel customer) async {
    try {
      final payload = {
        'name': customer.name,
        'mobile': customer.mobile,
        'email': customer.email,
        'address': customer.address,
        'gstNumber': customer.gstNumber,
        'openingBalance': customer.openingBalance,
        'creditLimit': customer.creditLimit,
        'status': customer.status.name,
      };
      final response = await _client.dio.post(ApiRoutes.customers, data: payload);
      if (response.data['success'] == true) {
        return CustomerModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw Exception(response.data['message'] ?? 'Failed to create customer');
    } on DioException catch (e, st) {
      AppLogger.error('createCustomer API error', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<CustomerModel> updateCustomer(CustomerModel customer) async {
    try {
      final payload = {
        'name': customer.name,
        'mobile': customer.mobile,
        'email': customer.email,
        'address': customer.address,
        'gstNumber': customer.gstNumber,
        'openingBalance': customer.openingBalance,
        'creditLimit': customer.creditLimit,
        'status': customer.status.name,
      };
      final response = await _client.dio.put(
        ApiRoutes.customerUpdate(customer.id),
        data: payload,
      );
      if (response.data['success'] == true) {
        return CustomerModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw Exception(response.data['message'] ?? 'Failed to update customer');
    } on DioException catch (e, st) {
      AppLogger.error('updateCustomer API error', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      final response = await _client.dio.delete(ApiRoutes.customerDelete(id));
      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to delete customer');
      }
    } on DioException catch (e, st) {
      AppLogger.error('deleteCustomer API error', error: e, stackTrace: st);
      rethrow;
    }
  }
}

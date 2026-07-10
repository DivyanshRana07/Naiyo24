import 'package:dio/dio.dart';
import 'package:naiyo24_business_tool/api_services/api_client.dart';
import 'package:naiyo24_business_tool/api_services/api_routes.dart';
import 'package:naiyo24_business_tool/models/service_model.dart';
import 'package:naiyo24_business_tool/utils/logger.dart';

class ServiceApiService {
  final ApiClient _client;

  ServiceApiService(this._client);

  Future<List<ServiceModel>> listServices() async {
    try {
      final response = await _client.dio.get(ApiRoutes.services);
      if (response.data['success'] == true) {
        final list = response.data['data'] as List;
        return list
            .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to load services');
    } on DioException catch (e, st) {
      AppLogger.error('listServices API error', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<ServiceModel> createService(ServiceModel service) async {
    try {
      final payload = {
        'name': service.name,
        'category': service.category,
        'sellingPrice': service.sellingPrice,
        'gstPercent': service.gstPercent,
        'status': service.status.name,
      };
      final response =
          await _client.dio.post(ApiRoutes.services, data: payload);
      if (response.data['success'] == true) {
        return ServiceModel.fromJson(
            response.data['data'] as Map<String, dynamic>);
      }
      throw Exception(response.data['message'] ?? 'Failed to create service');
    } on DioException catch (e, st) {
      AppLogger.error('createService API error', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<ServiceModel> updateService(ServiceModel service) async {
    try {
      final payload = {
        'name': service.name,
        'category': service.category,
        'sellingPrice': service.sellingPrice,
        'gstPercent': service.gstPercent,
        'status': service.status.name,
      };
      final response = await _client.dio
          .put(ApiRoutes.serviceUpdate(service.id), data: payload);
      if (response.data['success'] == true) {
        return ServiceModel.fromJson(
            response.data['data'] as Map<String, dynamic>);
      }
      throw Exception(response.data['message'] ?? 'Failed to update service');
    } on DioException catch (e, st) {
      AppLogger.error('updateService API error', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> deleteService(String id) async {
    try {
      final response =
          await _client.dio.delete(ApiRoutes.serviceDelete(id));
      if (response.data['success'] != true) {
        throw Exception(
            response.data['message'] ?? 'Failed to delete service');
      }
    } on DioException catch (e, st) {
      AppLogger.error('deleteService API error', error: e, stackTrace: st);
      rethrow;
    }
  }
}

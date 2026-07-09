import 'package:dio/dio.dart';
import 'package:naiyo24_business_tool/api_services/api_client.dart';
import 'package:naiyo24_business_tool/api_services/api_routes.dart';
import 'package:naiyo24_business_tool/models/item_model.dart';
import 'package:naiyo24_business_tool/utils/logger.dart';

class ItemService {
  final ApiClient _client;

  ItemService(this._client);

  Future<List<ItemModel>> listItems() async {
    try {
      final response = await _client.dio.get(ApiRoutes.items);
      if (response.data['success'] == true) {
        final list = response.data['data'] as List;
        return list.map((e) => ItemModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to load items');
    } on DioException catch (e, st) {
      AppLogger.error('listItems API error', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<ItemModel> createItem(ItemModel item) async {
    try {
      final payload = {
        'name': item.name,
        'category': item.category,
        'unit': item.unit,
        'purchasePrice': item.purchasePrice,
        'sellingPrice': item.sellingPrice,
        'stockQty': item.stockQty,
        'gstPercent': item.gstPercent,
        'status': item.status.name,
      };
      final response = await _client.dio.post(ApiRoutes.items, data: payload);
      if (response.data['success'] == true) {
        return ItemModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw Exception(response.data['message'] ?? 'Failed to create item');
    } on DioException catch (e, st) {
      AppLogger.error('createItem API error', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<ItemModel> updateItem(ItemModel item) async {
    try {
      final payload = {
        'name': item.name,
        'category': item.category,
        'unit': item.unit,
        'purchasePrice': item.purchasePrice,
        'sellingPrice': item.sellingPrice,
        'stockQty': item.stockQty,
        'gstPercent': item.gstPercent,
        'status': item.status.name,
      };
      final response = await _client.dio.put(ApiRoutes.itemUpdate(item.id), data: payload);
      if (response.data['success'] == true) {
        return ItemModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw Exception(response.data['message'] ?? 'Failed to update item');
    } on DioException catch (e, st) {
      AppLogger.error('updateItem API error', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<ItemModel> updateItemStock(String id, {int? deduct, int? restore}) async {
    try {
      final payload = <String, dynamic>{};
      if (deduct != null) payload['deduct'] = deduct;
      if (restore != null) payload['restore'] = restore;

      final response = await _client.dio.patch(
        ApiRoutes.itemStock(id),
        data: payload,
      );
      if (response.data['success'] == true) {
        return ItemModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw Exception(response.data['message'] ?? 'Failed to update item stock');
    } on DioException catch (e, st) {
      AppLogger.error('updateItemStock API error', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      final response = await _client.dio.delete(ApiRoutes.itemDelete(id));
      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to delete item');
      }
    } on DioException catch (e, st) {
      AppLogger.error('deleteItem API error', error: e, stackTrace: st);
      rethrow;
    }
  }
}

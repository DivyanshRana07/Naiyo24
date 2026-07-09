import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:naiyo24_business_tool/models/item_model.dart';
import 'package:naiyo24_business_tool/utils/logger.dart';

import 'package:naiyo24_business_tool/providers/api_providers.dart';

class ItemNotifier extends AutoDisposeNotifier<List<ItemModel>> {
  @override
  List<ItemModel> build() {
    // Watch provider to trigger rebuilds if client config changes
    ref.watch(itemApiServiceProvider);

    // Trigger async fetch in background to sync with backend
    _fetchItems();

    return [];
  }

  Future<void> _fetchItems() async {
    try {
      final items = await ref.read(itemApiServiceProvider).listItems();
      state = items;
      AppLogger.info('Items list updated from backend', data: {'count': state.length});
    } catch (e, st) {
      AppLogger.error('Failed to fetch items from backend', error: e, stackTrace: st);
    }
  }

  Future<void> addItem(ItemModel item) async {
    try {
      final saved = await ref.read(itemApiServiceProvider).createItem(item);
      state = [...state, saved];
      AppLogger.info('Item added on backend', data: {
        'id': saved.id,
        'name': saved.name,
        'code': saved.code,
      });
    } catch (e, st) {
      AppLogger.error('Failed to add item on backend', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateItem(ItemModel updated) async {
    try {
      final saved = await ref.read(itemApiServiceProvider).updateItem(updated);
      state = [
        for (final p in state) p.id == saved.id ? saved : p,
      ];
      AppLogger.info('Item updated on backend', data: {
        'id': saved.id,
        'name': saved.name,
      });
    } catch (e, st) {
      AppLogger.error('Failed to update item on backend', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await ref.read(itemApiServiceProvider).deleteItem(id);
      state = state.where((p) => p.id != id).toList();
      AppLogger.info('Item deleted on backend', data: {'id': id});
    } catch (e, st) {
      AppLogger.error('Failed to delete item on backend', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> deductStock(String itemId, int qty) async {
    try {
      final saved = await ref.read(itemApiServiceProvider).updateItemStock(itemId, deduct: qty);
      state = [
        for (final p in state) p.id == saved.id ? saved : p,
      ];
      AppLogger.info('Stock deducted on backend', data: {
        'itemId': itemId,
        'qty': qty,
      });
    } catch (e, st) {
      AppLogger.error('Failed to deduct stock on backend', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> restoreStock(String itemId, int qty) async {
    try {
      final saved = await ref.read(itemApiServiceProvider).updateItemStock(itemId, restore: qty);
      state = [
        for (final p in state) p.id == saved.id ? saved : p,
      ];
      AppLogger.info('Stock restored on backend', data: {
        'itemId': itemId,
        'qty': qty,
      });
    } catch (e, st) {
      AppLogger.error('Failed to restore stock on backend', error: e, stackTrace: st);
      rethrow;
    }
  }

  List<ItemModel> search(String query) {
    final q = query.toLowerCase();
    return state
        .where(
          (p) =>
              p.status == ItemStatus.active &&
              (p.name.toLowerCase().contains(q) ||
                  p.code.toLowerCase().contains(q)),
        )
        .toList();
  }
}

// Provider
final itemNotifierProvider = AutoDisposeNotifierProvider<ItemNotifier, List<ItemModel>>(
  () => ItemNotifier(),
);

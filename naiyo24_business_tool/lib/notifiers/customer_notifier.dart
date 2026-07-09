import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:naiyo24_business_tool/models/customer_model.dart';
import 'package:naiyo24_business_tool/utils/logger.dart';

import 'package:naiyo24_business_tool/providers/api_providers.dart';

class CustomerNotifier extends AutoDisposeNotifier<List<CustomerModel>> {
  @override
  List<CustomerModel> build() {
    // Watch provider to trigger rebuilds if client config changes
    ref.watch(customerApiServiceProvider);

    // Trigger async fetch in background to sync with backend
    _fetchCustomers();

    return [];
  }

  Future<void> _fetchCustomers() async {
    try {
      final customers = await ref.read(customerApiServiceProvider).listCustomers();
      state = customers;
      AppLogger.info('Customers list updated from backend', data: {'count': state.length});
    } catch (e, st) {
      AppLogger.error('Failed to fetch customers from backend', error: e, stackTrace: st);
    }
  }

  Future<void> addCustomer(CustomerModel customer) async {
    try {
      final saved = await ref.read(customerApiServiceProvider).createCustomer(customer);
      state = [...state, saved];
      AppLogger.info('Customer added on backend', data: {
        'id': saved.id,
        'name': saved.name,
        'code': saved.code,
      });
    } catch (e, st) {
      AppLogger.error('Failed to add customer on backend', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateCustomer(CustomerModel updated) async {
    try {
      final saved = await ref.read(customerApiServiceProvider).updateCustomer(updated);
      state = [
        for (final c in state) c.id == saved.id ? saved : c,
      ];
      AppLogger.info('Customer updated on backend', data: {
        'id': saved.id,
        'name': saved.name,
      });
    } catch (e, st) {
      AppLogger.error('Failed to update customer on backend', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await ref.read(customerApiServiceProvider).deleteCustomer(id);
      state = state.where((c) => c.id != id).toList();
      AppLogger.info('Customer deleted on backend', data: {'id': id});
    } catch (e, st) {
      AppLogger.error('Failed to delete customer on backend', error: e, stackTrace: st);
      rethrow;
    }
  }

  List<CustomerModel> search(String query) {
    final q = query.toLowerCase();
    return state
        .where(
          (c) =>
              c.status == CustomerStatus.active &&
              (c.name.toLowerCase().contains(q) ||
                  c.mobile.contains(q) ||
                  c.code.toLowerCase().contains(q)),
        )
        .toList();
  }

  CustomerModel? findById(String id) {
    try {
      return state.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}

// Manual provider
final customerNotifierProvider =
    AutoDisposeNotifierProvider<CustomerNotifier, List<CustomerModel>>(
  () => CustomerNotifier(),
);

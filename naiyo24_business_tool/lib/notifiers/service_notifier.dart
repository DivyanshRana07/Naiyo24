import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:naiyo24_business_tool/models/service_model.dart';
import 'package:naiyo24_business_tool/utils/logger.dart';

import 'package:naiyo24_business_tool/providers/api_providers.dart';

class ServiceNotifier extends AutoDisposeNotifier<List<ServiceModel>> {
  @override
  List<ServiceModel> build() {
    // Watch provider to trigger rebuilds if client config changes
    ref.watch(serviceApiServiceProvider);

    // Trigger async fetch in background to sync with backend
    _fetchServices();

    return [];
  }

  Future<void> _fetchServices() async {
    try {
      final services = await ref.read(serviceApiServiceProvider).listServices();
      state = services;
      AppLogger.info('Services list updated from backend', data: {'count': state.length});
    } catch (e, st) {
      AppLogger.error('Failed to fetch services from backend', error: e, stackTrace: st);
    }
  }

  Future<void> addService(ServiceModel service) async {
    try {
      final saved = await ref.read(serviceApiServiceProvider).createService(service);
      state = [...state, saved];
      AppLogger.info('Service added on backend', data: {
        'id': saved.id,
        'name': saved.name,
        'code': saved.code,
      });
    } catch (e, st) {
      AppLogger.error('Failed to add service on backend', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateService(ServiceModel updated) async {
    try {
      final saved = await ref.read(serviceApiServiceProvider).updateService(updated);
      state = [
        for (final s in state) s.id == saved.id ? saved : s,
      ];
      AppLogger.info('Service updated on backend', data: {
        'id': saved.id,
        'name': saved.name,
      });
    } catch (e, st) {
      AppLogger.error('Failed to update service on backend', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> deleteService(String id) async {
    try {
      await ref.read(serviceApiServiceProvider).deleteService(id);
      state = state.where((s) => s.id != id).toList();
      AppLogger.info('Service deleted on backend', data: {'id': id});
    } catch (e, st) {
      AppLogger.error('Failed to delete service on backend', error: e, stackTrace: st);
      rethrow;
    }
  }

  List<ServiceModel> search(String query) {
    final q = query.toLowerCase();
    return state
        .where(
          (s) =>
              s.status == ServiceStatus.active &&
              (s.name.toLowerCase().contains(q) ||
                  s.code.toLowerCase().contains(q)),
        )
        .toList();
  }
}

// Provider
final serviceNotifierProvider = AutoDisposeNotifierProvider<ServiceNotifier, List<ServiceModel>>(
  () => ServiceNotifier(),
);

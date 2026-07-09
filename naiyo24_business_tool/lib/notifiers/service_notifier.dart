import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:naiyo24_business_tool/models/service_model.dart';
import 'package:naiyo24_business_tool/utils/logger.dart';

/// Service state is held in-memory with seed data.
/// When the backend is ready, replace [_seed] with an API call in [build].
class ServiceNotifier extends AutoDisposeNotifier<List<ServiceModel>> {
  @override
  List<ServiceModel> build() => _seed;

  void addService(ServiceModel service) {
    state = [...state, service];
    AppLogger.info('Service added', data: {'id': service.id, 'name': service.name});
  }

  void updateService(ServiceModel updated) {
    state = [for (final s in state) s.id == updated.id ? updated : s];
    AppLogger.info('Service updated', data: {'id': updated.id, 'name': updated.name});
  }

  void deleteService(String id) {
    state = state.where((s) => s.id != id).toList();
    AppLogger.info('Service deleted', data: {'id': id});
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

// TODO(backend): Replace with AutoDisposeAsyncNotifierProvider once API is wired.
final serviceNotifierProvider =
    AutoDisposeNotifierProvider<ServiceNotifier, List<ServiceModel>>(
  () => ServiceNotifier(),
);

// ---------------------------------------------------------------------------
// Seed / dummy data — replace with API call in build() when backend is ready
// ---------------------------------------------------------------------------
const _seed = [
  ServiceModel(
    id: 's-seed-001',
    code: 'S001',
    name: 'Home Delivery',
    category: 'Delivery',
    sellingPrice: 30.0,
    gstPercent: 18,
  ),
  ServiceModel(
    id: 's-seed-002',
    code: 'S002',
    name: 'Consultation Fee',
    category: 'Consulting',
    sellingPrice: 200.0,
    gstPercent: 18,
  ),
  ServiceModel(
    id: 's-seed-003',
    code: 'S003',
    name: 'Lab Test',
    category: 'Laboratory',
    sellingPrice: 150.0,
    gstPercent: 5,
  ),
];

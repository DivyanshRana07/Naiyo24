import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naiyo24_business_tool/api_services/services/vendor_services.dart';
import 'package:naiyo24_business_tool/models/vendor_model.dart';
import 'package:naiyo24_business_tool/providers/api_providers.dart';
import 'package:naiyo24_business_tool/utils/logger.dart';

/// Vendor state fetched from backend API
class VendorNotifier extends AutoDisposeAsyncNotifier<List<VendorModel>> {
  late final VendorService _service;

  @override
  Future<List<VendorModel>> build() async {
    _service = ref.watch(vendorApiServiceProvider);
    return await loadVendors();
  }

  Future<List<VendorModel>> loadVendors() async {
    try {
      return await _service.getVendors();
    } catch (e) {
      AppLogger.error('Failed to load vendors', error: e);
      return [];
    }
  }

  Future<void> addVendor({
    required String name,
    String? contactPerson,
    String? email,
    String? phone,
    String? address,
  }) async {
    try {
      final newVendor = await _service.createVendor(
        name: name,
        contactPerson: contactPerson,
        email: email,
        phone: phone,
        address: address,
      );
      
      state = AsyncData([...?state.value, newVendor]);
      AppLogger.info('Vendor added', data: {'id': newVendor.id, 'name': newVendor.name});
    } catch (e) {
      AppLogger.error('Failed to add vendor', error: e);
      rethrow;
    }
  }

  Future<void> updateVendor(VendorModel vendor) async {
    try {
      // Parse ID to int if it's a string
      final id = int.tryParse(vendor.id) ?? 0;
      
      final updatedVendor = await _service.updateVendor(id, {
        'name': vendor.name,
        'contact_person': vendor.contactPerson,
        'email': vendor.email,
        'phone': vendor.phone,
        'address': vendor.address,
      });
      
      state = AsyncData([
        for (final v in state.value ?? [])
          v.id == vendor.id ? updatedVendor : v
      ]);
      AppLogger.info('Vendor updated', data: {'id': vendor.id, 'name': vendor.name});
    } catch (e) {
      AppLogger.error('Failed to update vendor', error: e);
      rethrow;
    }
  }

  Future<void> deleteVendor(String id) async {
    try {
      final vendorId = int.tryParse(id) ?? 0;
      await _service.deleteVendor(vendorId);
      
      state = AsyncData(
        (state.value ?? []).where((v) => v.id != id).toList()
      );
      AppLogger.info('Vendor deleted', data: {'id': id});
    } catch (e) {
      AppLogger.error('Failed to delete vendor', error: e);
      rethrow;
    }
  }

  VendorModel? findById(String id) {
    try {
      return state.value?.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }
}

final vendorNotifierProvider =
    AutoDisposeAsyncNotifierProvider<VendorNotifier, List<VendorModel>>(
  () => VendorNotifier(),
);

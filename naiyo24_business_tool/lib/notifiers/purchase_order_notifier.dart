import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naiyo24_business_tool/api_services/services/purchase_order_services.dart';
import 'package:naiyo24_business_tool/models/purchase_order_model.dart';
import 'package:naiyo24_business_tool/utils/logger.dart';

/// Purchase Order state fetched from backend API
class PurchaseOrderNotifier
    extends AutoDisposeAsyncNotifier<List<PurchaseOrderModel>> {
  @override
  Future<List<PurchaseOrderModel>> build() async {
    return await loadPurchaseOrders();
  }

  Future<List<PurchaseOrderModel>> loadPurchaseOrders() async {
    try {
      return await PurchaseOrderService.getPurchaseOrders();
    } catch (e) {
      AppLogger.error('Failed to load purchase orders', error: e);
      return [];
    }
  }

  Future<void> addPurchaseOrder(Map<String, dynamic> poData) async {
    try {
      final newPO = await PurchaseOrderService.createPurchaseOrder(poData);
      
      state = AsyncData([newPO, ...?state.value]);
      AppLogger.info('Purchase order added', data: {
        'id': newPO.id,
        'poNumber': newPO.poNumber,
        'vendorName': newPO.vendorName,
      });
    } catch (e) {
      AppLogger.error('Failed to add purchase order', error: e);
      rethrow;
    }
  }

  Future<void> updatePurchaseOrder(PurchaseOrderModel po) async {
    try {
      final id = int.tryParse(po.id) ?? 0;
      
      final updatedPO = await PurchaseOrderService.updatePurchaseOrder(id, {
        'vendor_id': int.tryParse(po.vendorId) ?? 0,
        'po_number': po.poNumber,
        'po_date': po.date.toIso8601String().split('T')[0],
        'status': po.status.name,
        'title': po.title,
        'description': po.description,
        'total_amount': po.totalAmount,
        'gst_amount': po.gstAmount,
        'receipt_image': po.receiptImage,
      });
      
      state = AsyncData([
        for (final p in state.value ?? [])
          p.id == po.id ? updatedPO : p
      ]);
      AppLogger.info('Purchase order updated', data: {'id': po.id, 'poNumber': po.poNumber});
    } catch (e) {
      AppLogger.error('Failed to update purchase order', error: e);
      rethrow;
    }
  }

  Future<void> deletePurchaseOrder(String id) async {
    try {
      final poId = int.tryParse(id) ?? 0;
      await PurchaseOrderService.deletePurchaseOrder(poId);
      
      state = AsyncData(
        (state.value ?? []).where((p) => p.id != id).toList()
      );
      AppLogger.info('Purchase order deleted', data: {'id': id});
    } catch (e) {
      AppLogger.error('Failed to delete purchase order', error: e);
      rethrow;
    }
  }

  Future<void> toggleStatus(String id) async {
    try {
      final po = state.value?.firstWhere((p) => p.id == id);
      if (po == null) return;
      
      final newStatus = po.status == POStatus.payed ? POStatus.unpayed : POStatus.payed;
      final updatedPO = po.copyWith(status: newStatus);
      
      await updatePurchaseOrder(updatedPO);
    } catch (e) {
      AppLogger.error('Failed to toggle status', error: e);
    }
  }

  PurchaseOrderModel? findById(String id) {
    try {
      return state.value?.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

final purchaseOrderNotifierProvider =
    AutoDisposeAsyncNotifierProvider<PurchaseOrderNotifier,
        List<PurchaseOrderModel>>(
  () => PurchaseOrderNotifier(),
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naiyo24_business_tool/api_services/services/quotation_services.dart';
import 'package:naiyo24_business_tool/models/quotation_model.dart';
import 'package:naiyo24_business_tool/utils/logger.dart';

/// Quotation state fetched from backend API
class QuotationNotifier extends AutoDisposeAsyncNotifier<List<QuotationModel>> {
  @override
  Future<List<QuotationModel>> build() async {
    return await loadQuotations();
  }

  Future<List<QuotationModel>> loadQuotations() async {
    try {
      return await QuotationService.getQuotations();
    } catch (e) {
      AppLogger.error('Failed to load quotations', error: e);
      return [];
    }
  }

  Future<void> addQuotation(Map<String, dynamic> quotationData) async {
    try {
      final newQuotation = await QuotationService.createQuotation(quotationData);
      
      state = AsyncData([newQuotation, ...?state.value]);
      AppLogger.info('Quotation added', data: {
        'id': newQuotation.id,
        'quotationNo': newQuotation.quotationNo,
        'customerName': newQuotation.customerName,
      });
    } catch (e) {
      AppLogger.error('Failed to add quotation', error: e);
      rethrow;
    }
  }

  Future<void> updateQuotation(QuotationModel quotation) async {
    try {
      // Parse ID to int if it's a string
      final id = int.tryParse(quotation.id) ?? 0;
      
      final updatedQuotation = await QuotationService.updateQuotation(id, {
        'customer_id': int.tryParse(quotation.customerId) ?? 0,
        'quotation_date': quotation.quotationDate.toIso8601String(),
        'valid_until': quotation.validUntil.toIso8601String(),
        'status': quotation.status.name,
      });
      
      state = AsyncData([
        for (final q in state.value ?? [])
          q.id == quotation.id ? updatedQuotation : q
      ]);
      AppLogger.info('Quotation updated', data: {'id': quotation.id, 'quotationNo': quotation.quotationNo});
    } catch (e) {
      AppLogger.error('Failed to update quotation', error: e);
      rethrow;
    }
  }

  Future<void> deleteQuotation(String id) async {
    try {
      final quotationId = int.tryParse(id) ?? 0;
      await QuotationService.deleteQuotation(quotationId);
      
      state = AsyncData(
        (state.value ?? []).where((q) => q.id != id).toList()
      );
      AppLogger.info('Quotation deleted', data: {'id': id});
    } catch (e) {
      AppLogger.error('Failed to delete quotation', error: e);
      rethrow;
    }
  }

  QuotationModel? findById(String id) {
    try {
      return state.value?.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }
}

final quotationNotifierProvider =
    AutoDisposeAsyncNotifierProvider<QuotationNotifier, List<QuotationModel>>(
  () => QuotationNotifier(),
);

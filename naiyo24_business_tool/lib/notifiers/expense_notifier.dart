import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naiyo24_business_tool/api_services/services/expense_services.dart';
import 'package:naiyo24_business_tool/models/expense_model.dart';
import 'package:naiyo24_business_tool/providers/api_providers.dart';
import 'package:naiyo24_business_tool/utils/logger.dart';

/// Expense state fetched from backend API
class ExpenseNotifier
    extends AutoDisposeAsyncNotifier<List<ExpenseModel>> {
  late final ExpenseService _service;

  @override
  Future<List<ExpenseModel>> build() async {
    _service = ref.watch(expenseApiServiceProvider);
    return await loadExpenses();
  }

  Future<List<ExpenseModel>> loadExpenses() async {
    try {
      return await _service.getExpenses();
    } catch (e) {
      AppLogger.error('Failed to load expenses', error: e);
      return [];
    }
  }

  Future<void> addExpense(Map<String, dynamic> expenseData) async {
    try {
      final newExpense = await _service.createExpense(expenseData);
      
      state = AsyncData([newExpense, ...?state.value]);
      AppLogger.info('Expense added', data: {
        'id': newExpense.id,
        'expenseNumber': newExpense.expenseNumber,
        'vendorName': newExpense.vendorName,
      });
    } catch (e) {
      AppLogger.error('Failed to add expense', error: e);
      rethrow;
    }
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      final id = int.tryParse(expense.id) ?? 0;
      
      final updatedExpense = await _service.updateExpense(id, {
        'vendor_id': int.tryParse(expense.vendorId) ?? 0,
        'expense_number': expense.expenseNumber,
        'expense_date': expense.date.toIso8601String().split('T')[0],
        'status': expense.status.name,
        'title': expense.title,
        'description': expense.description,
        'total_amount': expense.totalAmount,
        'gst_amount': expense.gstAmount,
        'receipt_image': expense.receiptImage,
      });
      
      state = AsyncData([
        for (final e in state.value ?? [])
          e.id == expense.id ? updatedExpense : e
      ]);
      AppLogger.info('Expense updated', data: {'id': expense.id, 'expenseNumber': expense.expenseNumber});
    } catch (e) {
      AppLogger.error('Failed to update expense', error: e);
      rethrow;
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      final expenseId = int.tryParse(id) ?? 0;
      await _service.deleteExpense(expenseId);
      
      state = AsyncData(
        (state.value ?? []).where((e) => e.id != id).toList()
      );
      AppLogger.info('Expense deleted', data: {'id': id});
    } catch (e) {
      AppLogger.error('Failed to delete expense', error: e);
      rethrow;
    }
  }

  Future<void> toggleStatus(String id) async {
    try {
      final expense = state.value?.firstWhere((e) => e.id == id);
      if (expense == null) return;
      
      final newStatus = expense.status == ExpenseStatus.paid ? ExpenseStatus.unpaid : ExpenseStatus.paid;
      final updatedExpense = expense.copyWith(status: newStatus);
      
      await updateExpense(updatedExpense);
    } catch (e) {
      AppLogger.error('Failed to toggle status', error: e);
    }
  }

  ExpenseModel? findById(String id) {
    try {
      return state.value?.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}

final expenseNotifierProvider =
    AutoDisposeAsyncNotifierProvider<ExpenseNotifier,
        List<ExpenseModel>>(
  () => ExpenseNotifier(),
);

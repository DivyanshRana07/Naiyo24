import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:naiyo24_business_tool/models/invoice_model.dart';
import 'package:naiyo24_business_tool/models/line_item_model.dart';
import 'package:naiyo24_business_tool/notifiers/item_notifier.dart';
import 'package:naiyo24_business_tool/utils/logger.dart';

import 'package:naiyo24_business_tool/providers/api_providers.dart';
import 'package:naiyo24_business_tool/notifiers/customer_notifier.dart';
import 'package:naiyo24_business_tool/notifiers/business_profile_notifier.dart';
import 'package:naiyo24_business_tool/models/customer_model.dart';
import 'package:naiyo24_business_tool/utils/export_helper.dart';

class InvoiceNotifier extends AutoDisposeNotifier<List<InvoiceModel>> {
  @override
  List<InvoiceModel> build() {
    // Watch providers to trigger rebuilds if configs change
    ref.watch(invoiceApiServiceProvider);
    ref.watch(customerNotifierProvider);

    // Sync with backend asynchronously
    _fetchInvoices();

    return [];
  }

  List<InvoiceModel> _resolveCustomerIds(List<InvoiceModel> invoices) {
    final customers = ref.read(customerNotifierProvider);
    return invoices.map((inv) {
      if (inv.customerId.isNotEmpty) {
        return inv;
      }
      final matched = customers.firstWhere(
        (c) => c.mobile == inv.customerMobile || c.name == inv.customerName,
        orElse: () => const CustomerModel(id: '', code: '', name: '', mobile: ''),
      );
      return inv.copyWith(
        customerId: matched.id,
      );
    }).toList();
  }

  Future<void> _fetchInvoices() async {
    try {
      final invoices = await ref.read(invoiceApiServiceProvider).listInvoices();
      final resolved = _resolveCustomerIds(invoices);
      state = resolved;
      AppLogger.info('Invoices list updated from backend', data: {'count': state.length});
    } catch (e, st) {
      AppLogger.error('Failed to fetch invoices from backend', error: e, stackTrace: st);
    }
  }

  Future<InvoiceModel> saveInvoice(InvoiceModel invoice) async {
    final statusVal = _resolveStatus(invoice);

    try {
      // Map business details
      final businessProfile = ref.read(businessProfileNotifierProvider);
      final businessGst = businessProfile.gstNumber.trim();
      final businessStateCode = businessGst.length >= 2 ? businessGst.substring(0, 2) : '27';
      final businessDetails = {
        'name': businessProfile.businessName.isNotEmpty ? businessProfile.businessName : 'My Business',
        'address': businessProfile.address,
        'address_line_1': businessProfile.address,
        'address_line_2': '',
        'city': '',
        'state_name': '',
        'state_code': businessStateCode,
        'postal_code': '',
        'gstin': businessProfile.gstNumber,
        'phone': businessProfile.phone,
        'email': '',
      };

      // Map customer details
      final customerList = ref.read(customerNotifierProvider);
      final customer = customerList.firstWhere(
        (c) => c.id == invoice.customerId,
        orElse: () => CustomerModel(
          id: '',
          code: '',
          name: invoice.customerName,
          mobile: invoice.customerMobile,
          address: invoice.customerAddress,
          gstNumber: invoice.customerGst,
        ),
      );
      final customerGst = customer.gstNumber?.trim() ?? '';
      final customerStateCode = customerGst.length >= 2 ? customerGst.substring(0, 2) : '27';
      final customerDetails = {
        'name': customer.name,
        'address': customer.address,
        'address_line_1': customer.address,
        'address_line_2': '',
        'city': '',
        'state_name': '',
        'state_code': customerStateCode,
        'postal_code': '',
        'gstin': customer.gstNumber,
        'phone': customer.mobile,
        'email': customer.email,
      };

      // Map line items
      final items = invoice.lineItems.map((item) {
        return {
          'name': item.name,
          'quantity': item.qty,
          'price': item.rate,
          'gst_rate': item.gstPercent,
        };
      }).toList();

      final saved = await ref.read(invoiceApiServiceProvider).createInvoice(
        businessDetails: businessDetails,
        customerDetails: customerDetails,
        items: items,
        invoiceDate: invoice.invoiceDate,
        dueDate: invoice.dueDate,
        notes: invoice.notes,
        paymentMethod: invoice.paymentMethod,
        paidAmount: invoice.paidAmount,
        roundOff: invoice.roundOff,
        status: statusVal.name,
      );

      final withCustomerId = saved.copyWith(customerId: invoice.customerId);
      state = [...state, withCustomerId];

      // Deduct stock locally
      for (final item in invoice.lineItems) {
        if (item.itemType == LineItemType.item) {
          ref
              .read(itemNotifierProvider.notifier)
              .deductStock(item.itemId, item.qty.toInt());
        }
      }

      AppLogger.info('Invoice saved on backend', data: {
        'id': withCustomerId.id,
        'invoiceNo': withCustomerId.invoiceNo,
      });

      return withCustomerId;
    } catch (e, st) {
      AppLogger.error('Failed to save invoice on backend', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateInvoice(InvoiceModel updated) async {
    final statusVal = _resolveStatus(updated);

    try {
      final customerList = ref.read(customerNotifierProvider);
      final customer = customerList.firstWhere(
        (c) => c.id == updated.customerId,
        orElse: () => CustomerModel(
          id: '',
          code: '',
          name: updated.customerName,
          mobile: updated.customerMobile,
          address: updated.customerAddress,
          gstNumber: updated.customerGst,
        ),
      );
      final customerGst = customer.gstNumber?.trim() ?? '';
      final customerStateCode = customerGst.length >= 2 ? customerGst.substring(0, 2) : '27';
      final customerDetails = {
        'name': customer.name,
        'address': customer.address,
        'address_line_1': customer.address,
        'address_line_2': '',
        'city': '',
        'state_name': '',
        'state_code': customerStateCode,
        'postal_code': '',
        'gstin': customer.gstNumber,
        'phone': customer.mobile,
        'email': customer.email,
      };

      final saved = await ref.read(invoiceApiServiceProvider).updateInvoice(
        updated.id,
        dueDate: updated.dueDate,
        notes: updated.notes,
        customerDetails: customerDetails,
        paymentMethod: updated.paymentMethod,
        paidAmount: updated.paidAmount,
        roundOff: updated.roundOff,
        status: statusVal.name,
      );

      final withCustomerId = saved.copyWith(customerId: updated.customerId);
      state = [
        for (final inv in state) inv.id == withCustomerId.id ? withCustomerId : inv,
      ];
      AppLogger.info('Invoice updated on backend', data: {
        'id': withCustomerId.id,
        'invoiceNo': withCustomerId.invoiceNo,
      });
    } catch (e, st) {
      AppLogger.error('Failed to update invoice on backend', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> deleteInvoice(String id) async {
    try {
      await ref.read(invoiceApiServiceProvider).deleteInvoice(id);
      state = state.where((inv) => inv.id != id).toList();
      AppLogger.info('Invoice deleted on backend', data: {'id': id});
    } catch (e, st) {
      AppLogger.error('Failed to delete invoice on backend', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> downloadInvoicePdf(String id, String invoiceNo) async {
    try {
      final bytes = await ref.read(invoiceApiServiceProvider).downloadInvoicePdf(id);
      downloadBytes(
        filename: 'Invoice-$invoiceNo.pdf',
        bytes: bytes,
        mimeType: 'application/pdf',
      );
      AppLogger.info('Invoice PDF downloaded', data: {'id': id, 'invoiceNo': invoiceNo});
    } catch (e, st) {
      AppLogger.error('Failed to download invoice PDF', error: e, stackTrace: st);
    }
  }

  InvoiceModel? findById(String id) {
    try {
      return state.firstWhere((inv) => inv.id == id);
    } catch (_) {
      return null;
    }
  }

  List<InvoiceModel> forCustomer(String customerId) {
    return state.where((inv) => inv.customerId == customerId).toList()
      ..sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
  }

  InvoiceStatus _resolveStatus(InvoiceModel invoice) {
    if (invoice.paidAmount <= 0) return InvoiceStatus.due;
    if (invoice.paidAmount >= invoice.grandTotal) return InvoiceStatus.paid;
    return InvoiceStatus.partial;
  }
}

// Manual provider
final invoiceNotifierProvider = AutoDisposeNotifierProvider<InvoiceNotifier, List<InvoiceModel>>(
  () => InvoiceNotifier(),
);

import 'package:dio/dio.dart';
import 'package:naiyo24_business_tool/api_services/api_client.dart';
import 'package:naiyo24_business_tool/api_services/api_routes.dart';
import 'package:naiyo24_business_tool/models/invoice_model.dart';
import 'package:naiyo24_business_tool/models/line_item_model.dart';
import 'package:naiyo24_business_tool/utils/logger.dart';

class InvoiceService {
  final ApiClient _client;

  InvoiceService(this._client);

  Future<List<InvoiceModel>> listInvoices() async {
    try {
      final response = await _client.dio.get(ApiRoutes.invoicesList);
      if (response.data['success'] == true) {
        final list = response.data['data'] as List;
        return list.map((e) => mapJsonToInvoiceModel(e as Map<String, dynamic>)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to load invoices');
    } on DioException catch (e, st) {
      AppLogger.error('listInvoices API error', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<InvoiceModel> createInvoice({
    String? invoiceNo,
    required Map<String, dynamic> businessDetails,
    required Map<String, dynamic> customerDetails,
    required List<Map<String, dynamic>> items,
    required DateTime invoiceDate,
    DateTime? dueDate,
    String? notes,
    String? paymentMethod,
    double paidAmount = 0.0,
    double roundOff = 0.0,
    String status = 'due',
    String? subtitle,
    String? logo,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final payload = {
        if (invoiceNo != null && invoiceNo.isNotEmpty) 'invoice_number': invoiceNo,
        'invoice_date': invoiceDate.toIso8601String().split('T').first,
        if (dueDate != null) 'due_date': dueDate.toIso8601String().split('T').first,
        'notes': notes,
        'subtitle': subtitle,
        'logo': logo,
        'settings': settings,
        'business': businessDetails,
        'customer': customerDetails,
        'items': items,
        'payment_method': paymentMethod,
        'paid_amount': paidAmount,
        'round_off': roundOff,
        'status': status,
      };

      final response = await _client.dio.post(ApiRoutes.invoicesCreate, data: payload);
      if (response.data['success'] == true) {
        return mapJsonToInvoiceModel(response.data['data'] as Map<String, dynamic>);
      }
      throw Exception(response.data['message'] ?? 'Failed to create invoice');
    } on DioException catch (e, st) {
      AppLogger.error('createInvoice API error', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<InvoiceModel> updateInvoice(String id, {
    DateTime? dueDate,
    String? notes,
    Map<String, dynamic>? customerDetails,
    String? paymentMethod,
    double? paidAmount,
    double? roundOff,
    String? status,
  }) async {
    try {
      final payload = {
        if (dueDate != null) 'due_date': dueDate.toIso8601String().split('T').first,
        'notes': notes,
        if (customerDetails != null) 'customer': customerDetails,
        'payment_method': paymentMethod,
        if (paidAmount != null) 'paid_amount': paidAmount,
        if (roundOff != null) 'round_off': roundOff,
        if (status != null) 'status': status,
      };

      final response = await _client.dio.put(ApiRoutes.invoiceUpdate(id), data: payload);
      if (response.data['success'] == true) {
        return mapJsonToInvoiceModel(response.data['data'] as Map<String, dynamic>);
      }
      throw Exception(response.data['message'] ?? 'Failed to update invoice');
    } on DioException catch (e, st) {
      AppLogger.error('updateInvoice API error', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> deleteInvoice(String id) async {
    try {
      final response = await _client.dio.delete(ApiRoutes.invoiceDelete(id));
      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to delete invoice');
      }
    } on DioException catch (e, st) {
      AppLogger.error('deleteInvoice API error', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<List<int>> downloadInvoicePdf(String id) async {
    try {
      final response = await _client.dio.get<List<int>>(
        ApiRoutes.invoiceDownloadPdf(id),
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );
      if (response.data != null) {
        return response.data!;
      }
      throw Exception('Empty PDF response');
    } on DioException catch (e, st) {
      AppLogger.error('downloadInvoicePdf API error', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<List<int>> exportInvoiceListPdf() async {
    try {
      final response = await _client.dio.get<List<int>>(
        ApiRoutes.invoiceExportListPdf,
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );
      if (response.data != null) {
        return response.data!;
      }
      throw Exception('Empty PDF response');
    } on DioException catch (e, st) {
      AppLogger.error('exportInvoiceListPdf API error', error: e, stackTrace: st);
      rethrow;
    }
  }

  InvoiceModel mapJsonToInvoiceModel(Map<String, dynamic> json) {
    final customerDetails = json['customer_details'] as Map<String, dynamic>? ?? {};
    final itemsList = json['items'] as List? ?? [];

    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    final lineItems = itemsList.map((item) {
      final itemMap = item as Map<String, dynamic>;
      return InvoiceLineItem(
        id: itemMap['id']?.toString() ?? '',
        itemType: LineItemType.item,
        itemId: '',
        code: '',
        name: itemMap['name'] as String? ?? '',
        qty: toDouble(itemMap['quantity']),
        rate: toDouble(itemMap['price']),
        discountPercent: 0.0,
        gstPercent: toDouble(itemMap['gst_rate']),
      );
    }).toList();

    return InvoiceModel(
      id: json['id']?.toString() ?? '',
      invoiceNo: json['invoice_number'] as String? ?? '',
      customerId: '', // will be resolved in the notifier
      customerName: customerDetails['name'] as String? ?? '',
      customerMobile: customerDetails['phone'] as String? ?? '',
      customerAddress: customerDetails['address_line_1'] as String? ?? '',
      customerGst: customerDetails['gstin'] as String? ?? '',
      invoiceDate: DateTime.parse(json['invoice_date'] as String),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : DateTime.parse(json['invoice_date'] as String).add(const Duration(days: 15)),
      lineItems: lineItems,
      paymentMethod: json['payment_method'] as String? ?? 'Cash',
      paidAmount: toDouble(json['paid_amount']),
      roundOff: toDouble(json['round_off']),
      notes: json['notes'] as String?,
      status: InvoiceStatus.values.byName(json['status'] as String? ?? 'due'),
      subtitle: json['subtitle'] as String?,
      logo: json['logo'] as String?,
      settings: json['settings'] as Map<String, dynamic>?,
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naiyo24_business_tool/api_services/api_client.dart';
import 'package:naiyo24_business_tool/api_services/services/customer_services.dart';
import 'package:naiyo24_business_tool/api_services/services/item_services.dart';
import 'package:naiyo24_business_tool/api_services/services/invoice_services.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final customerApiServiceProvider = Provider<CustomerService>((ref) {
  final client = ref.watch(apiClientProvider);
  return CustomerService(client);
});

final itemApiServiceProvider = Provider<ItemService>((ref) {
  final client = ref.watch(apiClientProvider);
  return ItemService(client);
});

final invoiceApiServiceProvider = Provider<InvoiceService>((ref) {
  final client = ref.watch(apiClientProvider);
  return InvoiceService(client);
});

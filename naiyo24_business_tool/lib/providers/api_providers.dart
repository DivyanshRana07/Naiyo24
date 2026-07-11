import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naiyo24_business_tool/api_services/api_client.dart';
import 'package:naiyo24_business_tool/api_services/services/customer_services.dart';
import 'package:naiyo24_business_tool/api_services/services/item_services.dart';
import 'package:naiyo24_business_tool/api_services/services/invoice_services.dart';
import 'package:naiyo24_business_tool/api_services/services/service_services.dart';
import 'package:naiyo24_business_tool/api_services/services/expense_services.dart';
import 'package:naiyo24_business_tool/api_services/services/lead_services.dart';
import 'package:naiyo24_business_tool/api_services/services/vendor_services.dart';
import 'package:naiyo24_business_tool/api_services/services/quotation_services.dart';
import 'package:naiyo24_business_tool/api_services/services/activity_services.dart';
import 'package:naiyo24_business_tool/api_services/services/dashboard_services.dart';

// ── Core HTTP client ─────────────────────────────────────────────────────────
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// ── Existing providers ────────────────────────────────────────────────────────
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

final serviceApiServiceProvider = Provider<ServiceApiService>((ref) {
  final client = ref.watch(apiClientProvider);
  return ServiceApiService(client);
});

// ── Newly wired providers ─────────────────────────────────────────────────────
final expenseApiServiceProvider = Provider<ExpenseService>((ref) {
  return const ExpenseService();
});

final leadApiServiceProvider = Provider<LeadService>((ref) {
  return const LeadService();
});

final vendorApiServiceProvider = Provider<VendorService>((ref) {
  return const VendorService();
});

final quotationApiServiceProvider = Provider<QuotationService>((ref) {
  return const QuotationService();
});

final activityApiServiceProvider = Provider<ActivityService>((ref) {
  return const ActivityService();
});

final dashboardApiServiceProvider = Provider<DashboardService>((ref) {
  return const DashboardService();
});

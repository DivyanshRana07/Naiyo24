class ApiRoutes {
  ApiRoutes._();

  static const String baseUrl = 'http://localhost:8000/api/v1';

  // Invoices Endpoints
  static const String invoices = '/invoices';
  static const String invoicesList = '/invoices/list';
  static const String invoicesCreate = '/invoices/create';
  
  static String invoiceDetail(String id) => '/invoices/$id';
  static String invoiceUpdate(String id) => '/invoices/$id';
  static String invoiceDelete(String id) => '/invoices/$id';
  static String invoiceDownloadPdf(String id) => '/invoices/$id/download-pdf';

  // Customers Endpoints
  static const String customers = '/customers';
  static String customerDetail(String id) => '/customers/$id';
  static String customerUpdate(String id) => '/customers/$id';
  static String customerDelete(String id) => '/customers/$id';

  // Items Endpoints
  static const String items = '/items';
  static String itemDetail(String id) => '/items/$id';
  static String itemUpdate(String id) => '/items/$id';
  static String itemDelete(String id) => '/items/$id';
  static String itemStock(String id) => '/items/$id/stock';

  // Services Endpoints
  static const String services = '/services';
  static String serviceUpdate(String id) => '/services/$id';
  static String serviceDelete(String id) => '/services/$id';

  // Dashboard Endpoints
  static const String dashboardStats = '/dashboard/stats';

  // Leads Endpoints
  static const String leads = '/leads';
  static const String leadsList = '/leads/list';
  static const String leadsCreate = '/leads/create';
  static String leadDetail(String id) => '/leads/$id';
  static String leadUpdate(String id) => '/leads/$id';
  static String leadDelete(String id) => '/leads/$id';
  static String leadConvert(String id) => '/leads/$id/convert';

  // Vendors Endpoints
  static const String vendors = '/vendors';
  static const String vendorsList = '/vendors/list';
  static const String vendorsCreate = '/vendors/add';
  static String vendorDetail(String id) => '/vendors/$id';
  static String vendorUpdate(String id) => '/vendors/$id';
  static String vendorDelete(String id) => '/vendors/$id';

  // Quotations Endpoints
  static const String quotations = '/quotation';
  static const String quotationsList = '/quotation/list';
  static const String quotationsCreate = '/quotation/create';
  static String quotationDetail(String id) => '/quotation/$id';
  static String quotationUpdate(String id) => '/quotation/$id';
  static String quotationDelete(String id) => '/quotation/$id';
  static String quotationDownloadPdf(String id) => '/quotation/$id/download-pdf';


  // Purchase Orders Endpoints
  static const String purchaseOrders = '/purchase-orders';
  static const String purchaseOrdersList = '/purchase-orders/list';
  static const String purchaseOrdersCreate = '/purchase-orders/create';
  static String purchaseOrderDetail(String id) => '/purchase-orders/$id';
  static String purchaseOrderUpdate(String id) => '/purchase-orders/$id';
  static String purchaseOrderDelete(String id) => '/purchase-orders/$id';

  // Activity Endpoints
  static const String activityList = '/activity';
}

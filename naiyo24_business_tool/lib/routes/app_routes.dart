abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String onboarding = '/onboarding';

  static const String dashboard = '/dashboard';
  static const String invoices = '/invoices';
  static const String quotations = '/quotations';
  static const String purchaseOrders = '/purchase-orders';
  static const String vendors = '/vendors';
  static const String clients = '/clients';
  static const String items = '/items';
  static const String reports = '/reports';
  static const String settings = '/settings';

  static const String newInvoice = '/invoices/new';
  static const String invoiceDetail = '/invoices/:id';
  static const String returnItems = '/invoices/:id/return';
  static const String newQuotation = '/quotations/new';
  static const String quotationDetail = '/quotations/:id';
  static const String newPurchaseOrder = '/purchase-orders/new';
  static const String newVendor = '/vendors/new';
  static const String newClient = '/clients/new';
  static const String newItem = '/items/new';
  static const String newService = '/items/new-service';
  static const String sendReminder = '/reminders/new';
  static const String expenses = '/expenses';
  static const String leads = '/leads';
  static const String newLead = '/leads/new';

  static const Set<String> _authRoutes = {login, signup, splash};

  static const Set<String> _protectedRoutes = {
    dashboard,
    onboarding,
    invoices,
    quotations,
    purchaseOrders,
    vendors,
    clients,
    items,
    reports,
    settings,
    leads,
  };

  static bool isProtected(String path) => _protectedRoutes.contains(path);

  static bool isAuthScreen(String path) => _authRoutes.contains(path);

  static String invoiceDetailPath(String id) => '/invoices/$id';

  static String returnItemsPath(String id) => '/invoices/$id/return';

  static String quotationDetailPath(String id) => '/quotations/$id';

  static String expenseDetailPath(String id) => '/purchase-orders/$id';

  AppRoutes._();
}

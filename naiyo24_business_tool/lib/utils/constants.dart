library;

/// Application-wide constants
/// 
/// This file contains all magic strings, numbers, and configuration values
/// used throughout the application for maintainability and consistency.

/// Storage Keys for SharedPreferences
class StorageKeys {
  StorageKeys._();
  
  static const String isLoggedIn = 'isLoggedIn';
  static const String hasCompletedOnboarding = 'hasCompletedOnboarding';
  static const String userEmail = 'userEmail';
  static const String businessProfile = 'business_profile_data';
  static const String customersList = 'customers_list';
  static const String invoicesList = 'invoices_list';
  static const String invoiceCounter = 'invoice_counter';
  static const String quotationsList = 'quotations_list';
  static const String itemsList = 'products_list';
  static const String servicesList = 'services_list';
  static const String vendorsList = 'vendors_list';
  static const String purchaseOrdersList = 'purchase_orders_list';
}

/// Demo credentials for testing
class DemoCredentials {
  DemoCredentials._();
  
  static const String email = 'naiyodemo@gmail.com';
  static const String password = 'demo123';
}

/// App Configuration
class AppConfig {
  AppConfig._();
  
  static const String appName = 'Business Tool';
  static const String appVersion = '1.0.0';
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration debounceDelay = Duration(milliseconds: 500);
  
  // Invoice/Quotation
  static const int defaultQuotationValidityDays = 30;
  static const String defaultCurrency = 'INR - Indian Rupee (₹)';
  static const String defaultPaymentTerms = 'Net 30 Days';
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxBusinessNameLength = 100;
  static const int maxAddressLength = 500;
  
  // UI
  static const int maxTableItemsPerPage = 50;
  static const int searchDebounceMs = 500;
}

/// Error Messages
class ErrorMessages {
  ErrorMessages._();
  
  // Authentication
  static const String invalidCredentials = 'Invalid email or password';
  static const String emailRequired = 'Email is required';
  static const String passwordRequired = 'Password is required';
  static const String passwordTooShort = 'Password must be at least 6 characters';
  static const String invalidEmail = 'Please enter a valid email';
  
  // Forms
  static const String fieldRequired = 'This field is required';
  static const String selectCustomer = 'Please select a customer';
  static const String selectVendor = 'Please select a vendor';
  static const String addLineItems = 'Add at least one item or service';
  static const String invalidNumber = 'Please enter a valid number';
  static const String invalidGST = 'Please enter a valid GST number';
  static const String invalidMobile = 'Please enter a valid mobile number';
  
  // General
  static const String unknownError = 'An unexpected error occurred';
  static const String networkError = 'Network error. Please try again';
  static const String dataLoadError = 'Failed to load data';
  static const String dataSaveError = 'Failed to save data';
}

/// Success Messages
class SuccessMessages {
  SuccessMessages._();
  
  static const String loginSuccess = 'Login successful';
  static const String dataUpdated = 'Data updated successfully';
  static const String customerAdded = 'Customer added successfully';
  static const String itemAdded = 'Item added successfully';
  static const String invoiceCreated = 'Invoice created successfully';
  static const String quotationCreated = 'Quotation created successfully';
  static const String purchaseOrderCreated = 'Purchase order created successfully';
  static const String changesSaved = 'Changes saved successfully';
  static const String itemDeleted = 'Item deleted successfully';
}

/// Validation Patterns
class ValidationPatterns {
  ValidationPatterns._();
  
  static final RegExp email = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  
  static final RegExp mobile = RegExp(
    r'^[6-9]\d{9}$', // Indian mobile number
  );
  
  static final RegExp gst = RegExp(
    r'^\d{2}[A-Z]{5}\d{4}[A-Z]{1}[A-Z\d]{1}[Z]{1}[A-Z\d]{1}$',
  );
  
  static final RegExp pinCode = RegExp(
    r'^\d{6}$',
  );
  
  static final RegExp alphanumeric = RegExp(
    r'^[a-zA-Z0-9]+$',
  );
}

/// Date Formats
class DateFormats {
  DateFormats._();
  
  static const String display = 'dd MMM yyyy'; // 01 Jan 2024
  static const String displayShort = 'dd/MM/yyyy'; // 01/01/2024
  static const String api = 'yyyy-MM-dd'; // 2024-01-01
  static const String time = 'hh:mm a'; // 02:30 PM
  static const String dateTime = 'dd MMM yyyy, hh:mm a'; // 01 Jan 2024, 02:30 PM
}

/// Currency Formats
class CurrencyFormats {
  CurrencyFormats._();
  
  static const String locale = 'en_IN';
  static const String symbol = '₹';
  static const int decimalDigits = 2;
}

/// Feature Flags
class FeatureFlags {
  FeatureFlags._();
  
  static const bool enableAnalytics = false;
  static const bool enableCrashReporting = false;
  static const bool enableDebugMode = true;
  static const bool enableOfflineMode = true;
  static const bool enableMultiCurrency = false;
  static const bool enableEmailIntegration = false;
}

/// API Endpoints (Future use)
class ApiEndpoints {
  ApiEndpoints._();
  
  static const String baseUrl = 'https://api.example.com';
  static const String apiVersion = 'v1';
  
  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  
  // Resources
  static const String customers = '/customers';
  static const String items = '/items';
  static const String invoices = '/invoices';
  static const String quotations = '/quotations';
  static const String vendors = '/vendors';
  static const String purchaseOrders = '/purchase-orders';
}

/// Asset Paths
class AssetPaths {
  AssetPaths._();
  
  static const String logo = 'assets/images/logo.png';
  static const String emptyState = 'assets/images/empty_state.svg';
  static const String errorState = 'assets/images/error_state.svg';
}

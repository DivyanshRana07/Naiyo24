import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:naiyo24_business_tool/models/customer_model.dart';
import 'package:naiyo24_business_tool/models/item_model.dart';
import 'package:naiyo24_business_tool/models/vendor_model.dart';
import 'package:naiyo24_business_tool/models/service_model.dart';
import 'package:naiyo24_business_tool/screens/add_service_screen.dart'
    deferred as add_service_screen;

import 'package:naiyo24_business_tool/providers/auth_provider.dart';
import 'package:naiyo24_business_tool/screens/splash_screen.dart';
import 'package:naiyo24_business_tool/screens/onboarding_screen.dart'
    deferred as onboarding_screen;
import 'package:naiyo24_business_tool/screens/dashboard_screen.dart'
    deferred as dashboard;
import 'package:naiyo24_business_tool/screens/settings_screen.dart'
    deferred as settings;
import 'package:naiyo24_business_tool/screens/invoices_screen.dart'
    deferred as invoices;
import 'package:naiyo24_business_tool/screens/quotations_screen.dart'
    deferred as quotations;
import 'package:naiyo24_business_tool/screens/create_quotation_screen.dart'
    deferred as create_quotation_screen;
import 'package:naiyo24_business_tool/screens/quotation_detail_screen.dart'
    deferred as quotation_detail_screen;
import 'package:naiyo24_business_tool/screens/items_screen.dart'
    deferred as items;
import 'package:naiyo24_business_tool/screens/clients_screen.dart'
    deferred as clients;
import 'package:naiyo24_business_tool/screens/add_client_screen.dart'
    deferred as add_client_screen;
import 'package:naiyo24_business_tool/screens/add_item_screen.dart'
    deferred as add_item_screen;
import 'package:naiyo24_business_tool/screens/create_invoice_screen.dart'
    deferred as create_invoice_screen;
import 'package:naiyo24_business_tool/screens/invoice_detail_screen.dart'
    deferred as invoice_detail_screen;
import 'package:naiyo24_business_tool/screens/return_items_screen.dart'
    deferred as return_items_screen;
import 'package:naiyo24_business_tool/screens/reports_screen.dart'
    deferred as reports;
import 'package:naiyo24_business_tool/screens/vendors_screen.dart'
    deferred as vendors;
import 'package:naiyo24_business_tool/screens/add_vendor_screen.dart'
    deferred as add_vendor_screen;
import 'package:naiyo24_business_tool/screens/expenses_screen.dart'
    deferred as expenses_screen;
import 'package:naiyo24_business_tool/screens/create_expense_screen.dart'
    deferred as create_expense_screen;
import 'package:naiyo24_business_tool/screens/leads_screen.dart'
    deferred as leads;
import 'package:naiyo24_business_tool/screens/create_lead_screen.dart'
    deferred as create_lead;
import 'package:naiyo24_business_tool/screens/expense_detail_screen.dart'
    deferred as expense_detail_screen;
import 'package:naiyo24_business_tool/routes/app_routes.dart';

class DeferredWidget extends StatefulWidget {
  const DeferredWidget({
    super.key,
    required this.load,
    required this.builder,
  });

  final Future<void> Function() load;
  final WidgetBuilder builder;

  @override
  State<DeferredWidget> createState() => _DeferredWidgetState();
}

class _DeferredWidgetState extends State<DeferredWidget> {
  Future<void>? _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text('Error loading page: ${snapshot.error}'),
              ),
            );
          }
          return widget.builder(context);
        }
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

// Manual provider
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (BuildContext context, GoRouterState state) {
      final hasCompletedOnboarding = authState.hasCompletedOnboarding;
      final location = state.matchedLocation;

      if (location == AppRoutes.splash || location == AppRoutes.dashboard) {
        return null;
      }

      if (!hasCompletedOnboarding && location != AppRoutes.onboarding) {
        return AppRoutes.onboarding;
      }

      if (hasCompletedOnboarding && location == AppRoutes.onboarding) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SplashScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: DeferredWidget(
            load: onboarding_screen.loadLibrary,
            builder: (context) => onboarding_screen.OnboardingScreen(),
          ),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: DeferredWidget(
            load: dashboard.loadLibrary,
            builder: (context) => dashboard.DashboardScreen(),
          ),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.invoices,
        name: 'invoices',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: DeferredWidget(
            load: invoices.loadLibrary,
            builder: (context) => invoices.InvoicesScreen(),
          ),
          transitionsBuilder: _fadeTransition,
        ),
        routes: [
          GoRoute(
            path: 'new',
            name: 'new-invoice',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: DeferredWidget(
                load: create_invoice_screen.loadLibrary,
                builder: (context) =>
                    create_invoice_screen.CreateInvoiceScreen(),
              ),
              transitionsBuilder: _slideTransition,
            ),
          ),
          GoRoute(
            path: ':id',
            name: 'invoice-detail',
            pageBuilder: (context, state) {
              final invoiceId = state.pathParameters['id'] ?? '';
              return CustomTransitionPage(
                key: state.pageKey,
                child: DeferredWidget(
                  load: invoice_detail_screen.loadLibrary,
                  builder: (context) =>
                      invoice_detail_screen.InvoiceDetailScreen(
                          invoiceId: invoiceId),
                ),
                transitionsBuilder: _slideTransition,
              );
            },
            routes: [
              GoRoute(
                path: 'return',
                name: 'return-items',
                pageBuilder: (context, state) {
                  final invoiceId = state.pathParameters['id'] ?? '';
                  return CustomTransitionPage(
                    key: state.pageKey,
                    child: DeferredWidget(
                      load: return_items_screen.loadLibrary,
                      builder: (context) =>
                          return_items_screen.ReturnItemsScreen(
                              invoiceId: invoiceId),
                    ),
                    transitionsBuilder: _slideTransition,
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.quotations,
        name: 'quotations',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: DeferredWidget(
            load: quotations.loadLibrary,
            builder: (context) => quotations.QuotationsScreen(),
          ),
          transitionsBuilder: _fadeTransition,
        ),
        routes: [
          GoRoute(
            path: 'new',
            name: 'new-quotation',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: DeferredWidget(
                load: create_quotation_screen.loadLibrary,
                builder: (context) =>
                    create_quotation_screen.CreateQuotationScreen(),
              ),
              transitionsBuilder: _slideTransition,
            ),
          ),
          GoRoute(
            path: ':id',
            name: 'quotation-detail',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return CustomTransitionPage(
                key: state.pageKey,
                child: DeferredWidget(
                  load: quotation_detail_screen.loadLibrary,
                  builder: (context) =>
                      quotation_detail_screen.QuotationDetailScreen(quotationId: id),
                ),
                transitionsBuilder: _slideTransition,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.expenses,
        name: 'expenses',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: DeferredWidget(
            load: expenses_screen.loadLibrary,
            builder: (context) => expenses_screen.ExpensesScreen(),
          ),
          transitionsBuilder: _fadeTransition,
        ),
        routes: [
          GoRoute(
            path: 'new',
            name: 'new-expense',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: DeferredWidget(
                load: create_expense_screen.loadLibrary,
                builder: (context) =>
                    create_expense_screen.CreateExpenseScreen(),
              ),
              transitionsBuilder: _slideTransition,
            ),
          ),
          GoRoute(
            path: ':id',
            name: 'expense-detail',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return CustomTransitionPage(
                key: state.pageKey,
                child: DeferredWidget(
                  load: expense_detail_screen.loadLibrary,
                  builder: (context) =>
                      expense_detail_screen.ExpenseDetailScreen(expenseId: id),
                ),
                transitionsBuilder: _slideTransition,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.vendors,
        name: 'vendors',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: DeferredWidget(
            load: vendors.loadLibrary,
            builder: (context) => vendors.VendorsScreen(),
          ),
          transitionsBuilder: _fadeTransition,
        ),
        routes: [
          GoRoute(
            path: 'new',
            name: 'new-vendor',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: DeferredWidget(
                load: add_vendor_screen.loadLibrary,
                builder: (context) => add_vendor_screen.AddVendorScreen(
                  existing: state.extra as VendorModel?,
                ),
              ),
              transitionsBuilder: _slideTransition,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.clients,
        name: 'clients',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: DeferredWidget(
            load: clients.loadLibrary,
            builder: (context) => clients.ClientsScreen(),
          ),
          transitionsBuilder: _fadeTransition,
        ),
        routes: [
          GoRoute(
            path: 'new',
            name: 'new-client',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: DeferredWidget(
                load: add_client_screen.loadLibrary,
                builder: (context) => add_client_screen.AddClientScreen(
                  existing: state.extra as CustomerModel?,
                ),
              ),
              transitionsBuilder: _slideTransition,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.items,
        name: 'items',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: DeferredWidget(
            load: items.loadLibrary,
            builder: (context) => items.ItemsScreen(),
          ),
          transitionsBuilder: _fadeTransition,
        ),
        routes: [
          GoRoute(
            path: 'new',
            name: 'new-item',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: DeferredWidget(
                load: add_item_screen.loadLibrary,
                builder: (context) => add_item_screen.AddItemScreen(
                  existing: state.extra as ItemModel?,
                ),
              ),
              transitionsBuilder: _slideTransition,
            ),
          ),
          GoRoute(
            path: 'new-service',
            name: 'new-service',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: DeferredWidget(
                load: add_service_screen.loadLibrary,
                builder: (context) => add_service_screen.AddServiceScreen(
                  existing: state.extra as ServiceModel?,
                ),
              ),
              transitionsBuilder: _slideTransition,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.reports,
        name: 'reports',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: DeferredWidget(
            load: reports.loadLibrary,
            builder: (context) => reports.ReportsScreen(),
          ),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: DeferredWidget(
            load: settings.loadLibrary,
            builder: (context) => settings.SettingsScreen(),
          ),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.sendReminder,
        name: 'send-reminder',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const _PlaceholderScreen(title: 'Send Reminder'),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      GoRoute(
        path: '/leads',
        name: 'leads',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: DeferredWidget(
            load: leads.loadLibrary,
            builder: (context) => leads.LeadsScreen(),
          ),
          transitionsBuilder: _fadeTransition,
        ),
        routes: [
          GoRoute(
            path: 'new',
            name: 'new-lead',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: DeferredWidget(
                load: create_lead.loadLibrary,
                builder: (context) => create_lead.CreateLeadScreen(),
              ),
              transitionsBuilder: _slideTransition,
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.message ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});

Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
    child: child,
  );
}

Widget _slideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
    child: child,
  );
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title — Coming soon',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

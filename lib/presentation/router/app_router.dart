import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_body.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';
import '../features/admin/screens/staff_management_screen.dart';
import '../features/admin/screens/staff_form_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/providers/permission_provider.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/products/screens/product_list_screen.dart';
import '../features/products/screens/add_product_screen.dart';
import '../features/products/screens/product_detail_screen.dart';
import '../features/products/screens/edit_product_screen.dart';
import '../features/products/screens/category_list_screen.dart';
import '../features/products/screens/category_form_screen.dart';
import '../features/products/screens/brand_list_screen.dart';
import '../features/products/screens/brand_form_screen.dart';
import '../features/inventory/screens/inventory_list_screen.dart';
import '../features/inventory/screens/inventory_analytics_screen.dart';
import '../features/inventory/screens/barcode_scanner_screen.dart';
import '../features/inventory/screens/stock_movement_screen.dart';
import '../features/inventory/screens/low_stock_screen.dart';
import '../features/inventory/screens/adjust_stock_screen.dart';
import '../features/inventory/screens/transfer_stock_screen.dart';
import '../features/inventory/screens/stock_take_screen.dart';
import '../features/sales/screens/pos_screen.dart';
import '../features/sales/screens/sales_list_screen.dart';
import '../features/sales/screens/sales_detail_screen.dart';
import '../features/sales/screens/sales_return_screen.dart';
import '../features/customers/screens/customer_list_screen.dart';
import '../features/customers/screens/customer_form_screen.dart';
import '../features/purchases/screens/purchase_list_screen.dart';
import '../features/purchases/screens/add_purchase_screen.dart';
import '../features/purchases/screens/purchase_detail_screen.dart';
import '../features/purchases/screens/receive_purchase_screen.dart';
import '../features/purchases/screens/supplier_form_screen.dart';
import '../features/purchases/screens/supplier_list_screen.dart';
import '../features/reports/screens/reports_home_screen.dart';
import '../features/reports/screens/sales_report_screen.dart';
import '../features/reports/screens/profit_report_screen.dart';
import '../features/reports/screens/inventory_valuation_screen.dart';
import '../features/reports/screens/supplier_performance_screen.dart';
import '../features/reports/screens/stock_report_screen.dart';
import '../features/debug/screens/supabase_test_screen.dart';
import '../features/debug/screens/backend_health_screen.dart';
import '../features/debug/screens/sync_queue_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/admin/screens/bulk_data_screen.dart';
import '../features/admin/screens/audit_log_screen.dart';
import 'router_notifier.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);
  final canAccessAdmin = ref.watch(canAccessAdminProvider);
  final canAccessPos = ref.watch(canAccessPosProvider);
  final canAccessReports = ref.watch(canAccessReportsProvider);
  final canViewInventory = ref.watch(canViewInventoryProvider);
  final canEditProducts = ref.watch(canEditProductsProvider);
  final canViewSales = ref.watch(canViewSalesProvider);
  final canViewCustomers = ref.watch(canViewCustomersProvider);
  final canEditCustomers = ref.watch(canEditCustomersProvider);
  final canViewPurchases = ref.watch(canViewPurchasesProvider);
  final canEditPurchases = ref.watch(canEditPurchasesProvider);
  final routerNotifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: routerNotifier,
    routes: [
      // Auth Routes — custom fade transitions to avoid Hero assertion errors
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Admin Routes
      GoRoute(
        path: '/admin',
        name: 'admin',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const AdminDashboardScreen(),
        ),
        routes: [
          GoRoute(
            path: 'data-tools',
            name: 'admin_data_tools',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const BulkDataScreen(),
            ),
          ),
          GoRoute(
            path: 'staff',
            name: 'admin_staff',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const StaffManagementScreen(),
            ),
            routes: [
              GoRoute(
                path: 'add',
                name: 'staff_add',
                pageBuilder: (context, state) => MaterialPage(
                  key: state.pageKey,
                  child: const StaffFormScreen(),
                ),
              ),
              GoRoute(
                path: ':id/edit',
                name: 'staff_edit',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return MaterialPage(
                    key: state.pageKey,
                    child: StaffFormScreen(staffId: id),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'audit-log',
            name: 'admin_audit_log',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const AuditLogScreen(),
            ),
          ),
        ],
      ),

      // Main Routes
      GoRoute(
        path: '/',
        name: 'root',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const DashboardScreen(),
        ),
        routes: [
          GoRoute(
            path: 'notifications',
            name: 'notifications',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const NotificationsScreen(),
            ),
          ),
          GoRoute(
            path: 'profile',
            name: 'profile',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const ProfileScreen(),
            ),
          ),
          GoRoute(
            path: 'debug/supabase',
            name: 'supabase_test',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const SupabaseTestScreen(),
            ),
          ),
          GoRoute(
            path: 'debug/backend-health',
            name: 'backend_health',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const BackendHealthScreen(),
            ),
          ),
          GoRoute(
            path: 'debug/sync-queue',
            name: 'sync_queue',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const SyncQueueScreen(),
            ),
          ),
          // Products Routes
          GoRoute(
            path: 'products',
            name: 'products',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const ProductListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'categories',
                name: 'categories',
                pageBuilder: (context, state) => MaterialPage(
                  key: state.pageKey,
                  child: const CategoryListScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'add',
                    name: 'category_add',
                    pageBuilder: (context, state) => MaterialPage(
                      key: state.pageKey,
                      child: const CategoryFormScreen(),
                    ),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    name: 'category_edit',
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return MaterialPage(
                        key: state.pageKey,
                        child: CategoryFormScreen(categoryId: id),
                      );
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'brands',
                name: 'brands',
                pageBuilder: (context, state) => MaterialPage(
                  key: state.pageKey,
                  child: const BrandListScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'add',
                    name: 'brand_add',
                    pageBuilder: (context, state) => MaterialPage(
                      key: state.pageKey,
                      child: const BrandFormScreen(),
                    ),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    name: 'brand_edit',
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return MaterialPage(
                        key: state.pageKey,
                        child: BrandFormScreen(brandId: id),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'products/add',
            name: 'add_product',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const AddProductScreen(),
            ),
          ),
          GoRoute(
            path: 'products/:id',
            name: 'product_detail',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return MaterialPage(
                key: state.pageKey,
                child: ProductDetailScreen(productId: id),
              );
            },
          ),
          GoRoute(
            path: 'products/:id/edit',
            name: 'edit_product',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return MaterialPage(
                key: state.pageKey,
                child: EditProductScreen(productId: id),
              );
            },
          ),

          // Inventory Routes
          GoRoute(
            path: 'inventory',
            name: 'inventory',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const InventoryListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'analytics',
                name: 'inventory_analytics',
                pageBuilder: (context, state) => MaterialPage(
                  key: state.pageKey,
                  child: const InventoryAnalyticsScreen(),
                ),
              ),
              GoRoute(
                path: 'low-stock',
                name: 'low_stock',
                pageBuilder: (context, state) => MaterialPage(
                  key: state.pageKey,
                  child: const LowStockScreen(),
                ),
              ),
              GoRoute(
                path: 'adjust',
                name: 'adjust_stock',
                pageBuilder: (context, state) => MaterialPage(
                  key: state.pageKey,
                  child: const AdjustStockScreen(),
                ),
              ),
              GoRoute(
                path: 'transfer',
                name: 'transfer_stock',
                pageBuilder: (context, state) => MaterialPage(
                  key: state.pageKey,
                  child: const TransferStockScreen(),
                ),
              ),
              GoRoute(
                path: 'movements',
                name: 'stock_movements',
                pageBuilder: (context, state) => MaterialPage(
                  key: state.pageKey,
                  child: const StockMovementScreen(),
                ),
              ),
              GoRoute(
                path: 'stock-take',
                name: 'stock_take',
                pageBuilder: (context, state) => MaterialPage(
                  key: state.pageKey,
                  child: const StockTakeScreen(),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'scanner',
            name: 'scanner',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const BarcodeScannerScreen(),
            ),
          ),

          // Sales Routes
          GoRoute(
            path: 'pos',
            name: 'pos',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const PosScreen(),
            ),
          ),
          GoRoute(
            path: 'sales',
            name: 'sales',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const SalesListScreen(),
            ),
          ),
          GoRoute(
            path: 'customers',
            name: 'customers',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const CustomerListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'add',
                name: 'customer_add',
                pageBuilder: (context, state) => MaterialPage(
                  key: state.pageKey,
                  child: const CustomerFormScreen(),
                ),
              ),
              GoRoute(
                path: ':id/edit',
                name: 'customer_edit',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return MaterialPage(
                    key: state.pageKey,
                    child: CustomerFormScreen(customerId: id),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'sales/:id',
            name: 'sales_detail',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return MaterialPage(
                key: state.pageKey,
                child: SalesDetailScreen(salesOrderId: id),
              );
            },
            routes: [
              GoRoute(
                path: 'return',
                name: 'sales_return',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return MaterialPage(
                    key: state.pageKey,
                    child: SalesReturnScreen(salesOrderId: id),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'sales/add',
            name: 'add_sale',
            redirect: (context, state) => '/pos',
          ),

          // Purchase Routes
          GoRoute(
            path: 'purchases',
            name: 'purchases',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const PurchaseListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'suppliers',
                name: 'suppliers',
                pageBuilder: (context, state) => MaterialPage(
                  key: state.pageKey,
                  child: const SupplierListScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'add',
                    name: 'supplier_add',
                    pageBuilder: (context, state) => MaterialPage(
                      key: state.pageKey,
                      child: const SupplierFormScreen(),
                    ),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    name: 'supplier_edit',
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return MaterialPage(
                        key: state.pageKey,
                        child: SupplierFormScreen(supplierId: id),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'purchases/add',
            name: 'add_purchase',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const AddPurchaseScreen(),
            ),
          ),
          GoRoute(
            path: 'purchases/:id',
            name: 'purchase_detail',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return MaterialPage(
                key: state.pageKey,
                child: PurchaseDetailScreen(purchaseOrderId: id),
              );
            },
            routes: [
              GoRoute(
                path: 'receive',
                name: 'purchase_receive',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return MaterialPage(
                    key: state.pageKey,
                    child: ReceivePurchaseScreen(purchaseOrderId: id),
                  );
                },
              ),
            ],
          ),

          // Report Routes
          GoRoute(
            path: 'reports',
            name: 'reports_home',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const ReportsHomeScreen(),
            ),
          ),
          GoRoute(
            path: 'reports/sales',
            name: 'sales_report',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const SalesReportScreen(),
            ),
          ),
          GoRoute(
            path: 'reports/stock',
            name: 'stock_report',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const StockReportScreen(),
            ),
          ),
          GoRoute(
            path: 'reports/profit',
            name: 'profit_report',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const ProfitReportScreen(),
            ),
          ),
          GoRoute(
            path: 'reports/valuation',
            name: 'inventory_valuation',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const InventoryValuationScreen(),
            ),
          ),
          GoRoute(
            path: 'reports/suppliers',
            name: 'supplier_performance',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const SupplierPerformanceScreen(),
            ),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isLoggedIn = auth.user != null;
      final isAuthRoute = location == '/login' || location == '/register';

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/';
      }

      if (location.startsWith('/admin')) {
        if (!canAccessAdmin) {
          return '/';
        }
      }

      // Permission-based guards
      if (location == '/pos' && !canAccessPos) {
        return '/';
      }
      if (location.startsWith('/reports') && !canAccessReports) {
        return '/';
      }
      if ((location == '/inventory' || location.startsWith('/inventory/')) &&
          !canViewInventory) {
        return '/';
      }
      if (location.startsWith('/sales') && !canViewSales) {
        return '/';
      }
      if (location.startsWith('/customers') && !canViewCustomers) {
        return '/';
      }
      if (location.startsWith('/purchases') && !canViewPurchases) {
        return '/';
      }

      // Edit-only customer routes
      if (location == '/customers/add' && !canEditCustomers) {
        return '/customers';
      }
      if (location.startsWith('/customers/') && location.endsWith('/edit')) {
        if (!canEditCustomers) {
          return '/customers';
        }
      }

      // Edit-only product routes
      if (location == '/products/add' && !canEditProducts) {
        return '/products';
      }
      if (location.startsWith('/products/') && location.endsWith('/edit')) {
        if (!canEditProducts) {
          return '/products';
        }
      }

      // Edit-only purchase routes
      if (location == '/purchases/add' && !canEditPurchases) {
        return '/purchases';
      }
      if (location.startsWith('/purchases/') && location.endsWith('/receive')) {
        if (!canEditPurchases) {
          return '/purchases';
        }
      }

      return null;
    },
    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: Scaffold(
        body: AppBody(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('404', style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 8),
                Text('Page not found',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Go Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
});

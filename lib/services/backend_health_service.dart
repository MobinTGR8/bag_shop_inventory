import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/features/auth/providers/auth_provider.dart';
import 'supabase_service.dart';

enum BackendCheckStatus { ok, warning, error }

class BackendHealthCheck {
  final String title;
  final BackendCheckStatus status;
  final String detail;
  final String remediation;

  const BackendHealthCheck({
    required this.title,
    required this.status,
    required this.detail,
    required this.remediation,
  });
}

class BackendHealthReport {
  final List<BackendHealthCheck> checks;

  const BackendHealthReport(this.checks);

  bool get isHealthy =>
      checks.every((check) => check.status == BackendCheckStatus.ok);
  bool get hasErrors =>
      checks.any((check) => check.status == BackendCheckStatus.error);
}

final backendHealthServiceProvider = Provider<BackendHealthService>((ref) {
  return BackendHealthService(
    ref.watch(supabaseServiceProvider),
    ref.watch(authProvider),
  );
});

final backendHealthReportProvider =
    FutureProvider<BackendHealthReport>((ref) async {
  return ref.watch(backendHealthServiceProvider).buildReport();
});

class BackendHealthService {
  final SupabaseService _supabase;
  final AuthState _auth;

  const BackendHealthService(this._supabase, this._auth);

  Future<BackendHealthReport> buildReport() async {
    final checks = <BackendHealthCheck>[];

    checks.add(_checkCompanyLink());
    checks.add(await _checkRead(
      'Products table',
      'products',
      'id, sku, name, company_id',
    ));
    checks.add(await _checkRead(
      'Categories table',
      'categories',
      'id, name, company_id',
    ));
    checks.add(await _checkRead(
      'Brands table',
      'brands',
      'id, name, company_id',
    ));
    checks.add(await _checkRead(
      'Warehouses table',
      'warehouses',
      'id, name, company_id, is_default',
    ));
    checks.add(await _checkRead(
      'Customers table',
      'customers',
      'id, name, company_id',
    ));
    checks.add(await _checkRead(
      'Suppliers table',
      'suppliers',
      'id, name, company_id',
    ));
    checks.add(await _checkRead(
      'Purchase orders table',
      'purchase_orders',
      'id, company_id, status',
    ));
    checks.add(await _checkRead(
      'Purchase order items table',
      'purchase_order_items',
      'id, purchase_order_id, product_id, quantity',
      useCompanyFilter: false,
    ));
    checks.add(await _checkRead(
      'Sales orders table',
      'sales_orders',
      'id, company_id, status',
    ));
    checks.add(await _checkRead(
      'Sales order items table',
      'sales_order_items',
      'id, sales_order_id, product_id, quantity',
      useCompanyFilter: false,
    ));
    checks.add(await _checkRead(
      'Stock movements table',
      'stock_movements',
      'id, company_id, product_id, movement_type',
    ));

    return BackendHealthReport(checks);
  }

  BackendHealthCheck _checkCompanyLink() {
    if (_auth.user == null) {
      return const BackendHealthCheck(
        title: 'Signed-in account',
        status: BackendCheckStatus.warning,
        detail: 'No user session is active yet.',
        remediation: 'Sign in first, then rerun the health check.',
      );
    }

    if (_auth.companyId == null) {
      return const BackendHealthCheck(
        title: 'Company membership',
        status: BackendCheckStatus.error,
        detail: 'The account is not linked to a company row.',
        remediation: 'Register an owner or join with a valid staff invite.',
      );
    }

    return BackendHealthCheck(
      title: 'Company membership',
      status: BackendCheckStatus.ok,
      detail: 'Company ${_auth.companyId} is linked to the current session.',
      remediation: 'No action needed.',
    );
  }

  Future<BackendHealthCheck> _checkRead(
      String title, String table, String columns,
      {bool useCompanyFilter = true}) async {
    try {
      var query = _supabase.client.from(table).select(columns);
      final companyId = _auth.companyId;
      if (useCompanyFilter && companyId != null) {
        query = query.eq('company_id', companyId);
      }
      await query.limit(1);

      return BackendHealthCheck(
        title: title,
        status: BackendCheckStatus.ok,
        detail: 'Read succeeded.',
        remediation: 'No action needed.',
      );
    } catch (error) {
      final message = error.toString();
      final lower = message.toLowerCase();

      if (lower.contains('permission denied') || lower.contains('rls')) {
        return BackendHealthCheck(
          title: title,
          status: BackendCheckStatus.error,
          detail: 'Read blocked by row-level security or missing policy.',
          remediation:
              'Apply the Supabase RLS policies from the schema and verify the current user belongs to the company.',
        );
      }

      if (lower.contains('relation') && lower.contains('does not exist')) {
        return BackendHealthCheck(
          title: title,
          status: BackendCheckStatus.error,
          detail: 'The table is missing from Supabase.',
          remediation: 'Re-run the SQL schema in the Supabase project.',
        );
      }

      if (lower.contains('column') && lower.contains('does not exist')) {
        return BackendHealthCheck(
          title: title,
          status: BackendCheckStatus.error,
          detail: 'A required column is missing from the table.',
          remediation:
              'Apply the latest schema migration or update the SQL setup.',
        );
      }

      return BackendHealthCheck(
        title: title,
        status: BackendCheckStatus.error,
        detail: message,
        remediation: 'Inspect the table definition and Supabase logs.',
      );
    }
  }
}

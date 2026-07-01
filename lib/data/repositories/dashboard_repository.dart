import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/supabase_service.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(supabaseServiceProvider));
});

class DashboardRepository {
  final SupabaseService _supabase;

  DashboardRepository(this._supabase);

  String _dateOnly(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<int> countProducts({required String? companyId}) async {
    if (companyId == null) return 0;
    final rows = await _supabase.client
        .from('products')
        .select('id')
        .eq('company_id', companyId)
        .limit(5000);

    return (rows as List).length;
  }

  Future<double> sumSalesTotal({
    required String? companyId,
    required DateTime from,
    required DateTime to,
  }) async {
    if (companyId == null) return 0;

    final rows = await _supabase.client
        .from('sales_orders')
        .select('sale_date, total_amount')
        .eq('company_id', companyId)
        .gte('sale_date', _dateOnly(from))
        .lte('sale_date', _dateOnly(to));

    double total = 0;
    for (final r in (rows as List)) {
      final m = r as Map<String, dynamic>;
      total += (m['total_amount'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }
}

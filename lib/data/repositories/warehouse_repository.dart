import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/supabase_service.dart';
import '../models/warehouse/warehouse_model.dart';

final warehouseRepositoryProvider = Provider<WarehouseRepository>((ref) {
  return WarehouseRepository(ref.watch(supabaseServiceProvider));
});

class WarehouseRepository {
  final SupabaseService _supabase;

  WarehouseRepository(this._supabase);

  Future<List<WarehouseModel>> listWarehouses(
      {required String companyId}) async {
    final rows = await _supabase.client
        .from('warehouses')
        .select('id, company_id, name, type, is_default')
        .eq('company_id', companyId)
        .order('is_default', ascending: false)
        .order('name');

    return (rows as List)
        .map((e) => WarehouseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String?> getDefaultWarehouseId({required String companyId}) async {
    final defaultRow = await _supabase.client
        .from('warehouses')
        .select('id')
        .eq('company_id', companyId)
        .eq('is_default', true)
        .maybeSingle();

    if (defaultRow != null) return defaultRow['id'] as String;

    final anyRow = await _supabase.client
        .from('warehouses')
        .select('id')
        .eq('company_id', companyId)
        .limit(1)
        .maybeSingle();

    return anyRow?['id'] as String?;
  }
}

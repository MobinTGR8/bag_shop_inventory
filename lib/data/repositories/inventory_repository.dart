import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/supabase_service.dart';
import '../models/inventory/inventory_model.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(ref.watch(supabaseServiceProvider));
});

class InventoryRepository {
  final SupabaseService _supabase;

  InventoryRepository(this._supabase);

  Future<List<InventoryModel>> listInventory({String? companyId}) async {
    if (companyId == null) return <InventoryModel>[];
    // inventory table doesn't have company_id; filter through warehouses
    final response = await _supabase.client
        .from('inventory')
        .select(
            'id, product_id, warehouse_id, quantity, reserved_quantity, available_quantity, batch_number, manufacturing_date, expiry_date, condition, notes, last_counted, last_updated, products(name, sku), warehouses!inner(company_id, name)')
        .eq('warehouses.company_id', companyId)
        .order('last_updated', ascending: false)
        .limit(500);

    return (response as List)
        .map((e) => InventoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

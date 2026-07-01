import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/supabase_service.dart';
import '../models/inventory/stock_movement_model.dart';

final stockMovementRepositoryProvider =
    Provider<StockMovementRepository>((ref) {
  return StockMovementRepository(ref.watch(supabaseServiceProvider));
});

class StockMovementRepository {
  final SupabaseService _supabase;

  StockMovementRepository(this._supabase);

  Future<List<StockMovementModel>> listStockMovements({
    required String? companyId,
    String? warehouseId,
    String? productId,
    String? movementType,
    String? createdBy,
    String? referenceType,
    String? referenceId,
    DateTime? from,
    DateTime? to,
    int limit = 200,
  }) async {
    if (companyId == null) return <StockMovementModel>[];

    var q = _supabase.client
        .from('stock_movements')
        .select(
          'id, company_id, product_id, warehouse_id, movement_type, quantity_change, quantity_before,'
          'batch_number, reference_type, reference_id, notes, created_by, created_at,'
          'products(name, sku),'
          'warehouses(name)',
        )
        .eq('company_id', companyId);

    if (warehouseId != null && warehouseId.isNotEmpty) {
      q = q.eq('warehouse_id', warehouseId);
    }
    if (productId != null && productId.isNotEmpty) {
      q = q.eq('product_id', productId);
    }
    if (movementType != null && movementType.isNotEmpty) {
      q = q.eq('movement_type', movementType);
    }
    if (createdBy != null && createdBy.isNotEmpty) {
      q = q.eq('created_by', createdBy);
    }

    if (referenceType != null && referenceType.isNotEmpty) {
      q = q.eq('reference_type', referenceType);
    }
    if (referenceId != null && referenceId.isNotEmpty) {
      q = q.eq('reference_id', referenceId);
    }

    if (from != null) {
      q = q.gte('created_at', from.toUtc().toIso8601String());
    }
    if (to != null) {
      q = q.lt('created_at', to.toUtc().toIso8601String());
    }

    final rows = await q.order('created_at', ascending: false).limit(limit);

    return (rows as List)
        .map((e) => StockMovementModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../services/supabase_service.dart';
import '../../services/sync_service.dart';

final inventoryOperationsRepositoryProvider =
    Provider<InventoryOperationsRepository>((ref) {
  return InventoryOperationsRepository(
    ref.watch(supabaseServiceProvider),
    ref.watch(syncServiceProvider),
  );
});

class InventoryOperationsRepository {
  final SupabaseService _supabase;
  final SyncService _sync;
  final Uuid _uuid = const Uuid();

  InventoryOperationsRepository(this._supabase, this._sync);

  Future<int> _getInventoryQuantity({
    required String productId,
    required String warehouseId,
    String? batchNumber,
  }) async {
    var q = _supabase.client
        .from('inventory')
        .select('quantity, batch_number')
        .eq('product_id', productId)
        .eq('warehouse_id', warehouseId);

    if (batchNumber == null) {
      q = q.isFilter('batch_number', null);
    } else {
      q = q.eq('batch_number', batchNumber);
    }

    final row = await q.maybeSingle();
    if (row == null) return 0;
    return (row['quantity'] as int?) ?? 0;
  }

  Future<void> adjustStock({
    required String companyId,
    required String createdBy,
    required String productId,
    required String warehouseId,
    required int quantityDelta,
    String? batchNumber,
    String? reason,
  }) async {
    if (quantityDelta == 0) {
      throw Exception('Adjustment quantity cannot be 0');
    }

    final before = await _getInventoryQuantity(
      productId: productId,
      warehouseId: warehouseId,
      batchNumber: batchNumber,
    );

    final refId = _uuid.v4();
    final reasonText = reason?.trim();

    final row = {
      'company_id': companyId,
      'product_id': productId,
      'warehouse_id': warehouseId,
      'movement_type': 'ADJUSTMENT',
      'quantity_change': quantityDelta,
      'quantity_before': before,
      'reference_type': 'MANUAL_ADJUSTMENT',
      'reference_id': refId,
      if (batchNumber != null) 'batch_number': batchNumber,
      if (reasonText != null && reasonText.isNotEmpty) 'notes': reasonText,
      'created_by': createdBy,
    };

    try {
      await _supabase.client.from('stock_movements').insert(row);
    } catch (_) {
      await _sync.enqueueInsert(table: 'stock_movements', rows: [row]);
      throw const QueuedForSyncException(
          'Network issue: adjustment queued for sync.');
    }
  }

  Future<void> transferStock({
    required String companyId,
    required String createdBy,
    required String productId,
    required String fromWarehouseId,
    required String toWarehouseId,
    required int quantity,
    String? batchNumber,
  }) async {
    if (quantity <= 0) {
      throw Exception('Transfer quantity must be > 0');
    }
    if (fromWarehouseId == toWarehouseId) {
      throw Exception('Warehouses must be different');
    }

    final fromBefore = await _getInventoryQuantity(
      productId: productId,
      warehouseId: fromWarehouseId,
      batchNumber: batchNumber,
    );
    if (fromBefore < quantity) {
      throw Exception('Insufficient stock to transfer');
    }

    final toBefore = await _getInventoryQuantity(
      productId: productId,
      warehouseId: toWarehouseId,
      batchNumber: batchNumber,
    );

    final refId = _uuid.v4();

    final rows = [
      {
        'company_id': companyId,
        'product_id': productId,
        'warehouse_id': fromWarehouseId,
        'movement_type': 'TRANSFER',
        'quantity_change': -quantity,
        'quantity_before': fromBefore,
        'reference_type': 'STOCK_TRANSFER',
        'reference_id': refId,
        if (batchNumber != null) 'batch_number': batchNumber,
        'created_by': createdBy,
      },
      {
        'company_id': companyId,
        'product_id': productId,
        'warehouse_id': toWarehouseId,
        'movement_type': 'TRANSFER',
        'quantity_change': quantity,
        'quantity_before': toBefore,
        'reference_type': 'STOCK_TRANSFER',
        'reference_id': refId,
        if (batchNumber != null) 'batch_number': batchNumber,
        'created_by': createdBy,
      },
    ];

    try {
      await _supabase.client.from('stock_movements').insert(rows);
    } catch (_) {
      await _sync.enqueueInsert(table: 'stock_movements', rows: rows);
      throw const QueuedForSyncException(
          'Network issue: transfer queued for sync.');
    }
  }

  Future<void> stockTake({
    required String companyId,
    required String createdBy,
    required String warehouseId,
    required List<StockTakeLine> lines,
  }) async {
    if (lines.isEmpty) return;

    final sessionId = _uuid.v4();
    final nowUtc = DateTime.now().toUtc().toIso8601String();

    final rows = <Map<String, dynamic>>[];
    for (final line in lines) {
      final before = line.quantityBefore;
      final delta = line.countedQuantity - before;
      if (delta == 0) continue;
      rows.add({
        'company_id': companyId,
        'product_id': line.productId,
        'warehouse_id': warehouseId,
        'movement_type': 'ADJUSTMENT',
        'quantity_change': delta,
        'quantity_before': before,
        'reference_type': 'STOCK_TAKE',
        'reference_id': sessionId,
        'notes': 'Stock take',
        'created_by': createdBy,
      });
    }

    if (rows.isEmpty) return;

    try {
      await _supabase.client.from('stock_movements').insert(rows);
    } catch (_) {
      await _sync.enqueueInsert(table: 'stock_movements', rows: rows);
      throw const QueuedForSyncException(
          'Network issue: stock take queued for sync.');
    }

    // Best-effort: mark inventory as counted.
    // This does not affect quantities (trigger is based on stock_movements).
    for (final line in lines) {
      try {
        await _supabase.client
            .from('inventory')
            .update({'last_counted': nowUtc})
            .eq('product_id', line.productId)
            .eq('warehouse_id', warehouseId);
      } catch (_) {
        await _sync.enqueueUpdate(
          table: 'inventory',
          values: {'last_counted': nowUtc},
          match: {
            'product_id': line.productId,
            'warehouse_id': warehouseId,
          },
        );
      }
    }
  }
}

class StockTakeLine {
  final String productId;
  final int countedQuantity;
  final int quantityBefore;

  const StockTakeLine({
    required this.productId,
    required this.countedQuantity,
    required this.quantityBefore,
  });
}

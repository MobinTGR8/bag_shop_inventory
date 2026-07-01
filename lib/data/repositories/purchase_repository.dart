import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/supabase_service.dart';
import '../../services/stable_fingerprint.dart';
import '../../services/sync_service.dart';
import '../models/purchases/purchase_order_create_item.dart';
import '../models/purchases/purchase_order_detail_model.dart';
import '../models/purchases/purchase_order_item_model.dart';
import '../models/purchases/purchase_order_model.dart';
import '../models/purchases/supplier_model.dart';

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  return PurchaseRepository(
    ref.watch(supabaseServiceProvider),
    ref.watch(syncServiceProvider),
  );
});

class PurchaseRepository {
  final SupabaseService _supabase;
  final SyncService _sync;

  PurchaseRepository(this._supabase, this._sync);

  @visibleForTesting
  static double calculateSubtotal(List<PurchaseOrderCreateItem> items) {
    return items.fold<double>(
      0,
      (sum, item) => sum + (item.quantity * item.unitCost),
    );
  }

  @visibleForTesting
  static double calculateTotal({
    required double subtotal,
    required double taxAmount,
    required double shippingCost,
    required double discountAmount,
  }) {
    return subtotal + taxAmount + shippingCost - discountAmount;
  }

  @visibleForTesting
  static String resolveReceiveWarehouseId({
    required PurchaseOrderItemModel item,
    required String fallbackWarehouseId,
    Map<String, String?>? warehouseByItemId,
  }) {
    return warehouseByItemId?[item.id] ??
        item.warehouseId ??
        fallbackWarehouseId;
  }

  Future<List<PurchaseOrderModel>> listPurchaseOrders(
      {String? companyId}) async {
    if (companyId == null) return <PurchaseOrderModel>[];
    final response = await _supabase.client
        .from('purchase_orders')
        .select('*')
        .eq('company_id', companyId)
        .order('order_date', ascending: false)
        .limit(200);

    return (response as List)
        .map((e) => PurchaseOrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PurchaseOrderDetailModel> getPurchaseOrderDetail({
    required String purchaseOrderId,
  }) async {
    final row = await _supabase.client
        .from('purchase_orders')
        .select(
          'id, company_id, supplier_id, po_number, status, order_date, expected_delivery, actual_delivery, total_amount, notes,'
          'suppliers(name),'
          'purchase_order_items(id, product_id, quantity, unit_cost, warehouse_id, batch_number, received_quantity, products(name, sku))',
        )
        .eq('id', purchaseOrderId)
        .single();

    final map = row;
    final supplier = map['suppliers'] is Map<String, dynamic>
        ? (map['suppliers'] as Map<String, dynamic>)
        : null;
    final itemsRaw = (map['purchase_order_items'] as List?) ?? const [];

    final items = itemsRaw
        .map((e) => PurchaseOrderItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return PurchaseOrderDetailModel(
      order: PurchaseOrderModel.fromJson(map),
      supplierName: supplier?['name'] as String?,
      items: items,
    );
  }

  Future<List<SupplierModel>> listSuppliers({required String companyId}) async {
    final rows = await _supabase.client
        .from('suppliers')
        .select('id, name')
        .eq('company_id', companyId)
        .order('name');

    return (rows as List)
        .map((e) => SupplierModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> createPurchaseOrder({
    required String companyId,
    required String createdBy,
    String? supplierId,
    required DateTime orderDate,
    String? poNumber,
    required List<PurchaseOrderCreateItem> items,
    double shippingCost = 0,
    double discountAmount = 0,
    double taxAmount = 0,
    String? notes,
    String? clientRequestId,
  }) async {
    if (items.isEmpty) {
      throw Exception('Add at least one item');
    }

    final normalizedOrderDate =
        DateTime(orderDate.year, orderDate.month, orderDate.day);
    final subtotal = calculateSubtotal(items);
    final requestId = clientRequestId ??
        StableFingerprint.of({
          'companyId': companyId,
          'createdBy': createdBy,
          'supplierId': supplierId,
          'orderDate': normalizedOrderDate.toIso8601String().split('T').first,
          'items': [
            for (final item in items)
              {
                'productId': item.productId,
                'quantity': item.quantity,
                'unitCost': item.unitCost,
                'warehouseId': item.warehouseId,
                'batchNumber': item.batchNumber,
              }
          ],
          'shippingCost': shippingCost,
          'discountAmount': discountAmount,
          'taxAmount': taxAmount,
          'notes': notes?.trim(),
        });

    final total = calculateTotal(
      subtotal: subtotal,
      taxAmount: taxAmount,
      shippingCost: shippingCost,
      discountAmount: discountAmount,
    );
    final po = (poNumber == null || poNumber.trim().isEmpty)
        ? _generatePoNumber(normalizedOrderDate, requestId)
        : poNumber.trim();

    final existingOrder = await _supabase.client
        .from('purchase_orders')
        .select('id')
        .eq('company_id', companyId)
        .eq('po_number', po)
        .maybeSingle();

    final itemRows =
        items.map((i) => i.toInsertJson(purchaseOrderId: 'pending')).toList();

    if (existingOrder != null) {
      final purchaseOrderId = existingOrder['id'] as String;
      final existingItems = await _supabase.client
          .from('purchase_order_items')
          .select('product_id, quantity, unit_cost, warehouse_id, batch_number')
          .eq('purchase_order_id', purchaseOrderId);

      final existingFingerprints = {
        for (final row in (existingItems as List))
          StableFingerprint.of(
              _purchaseItemComparableRow(row as Map<String, dynamic>))
      };

      final missingRows = itemRows.where((row) {
        return !existingFingerprints.contains(
          StableFingerprint.of(_purchaseItemComparableRow(row)),
        );
      }).map((row) {
        final copy = Map<String, dynamic>.from(row);
        copy['purchase_order_id'] = purchaseOrderId;
        return copy;
      }).toList();

      if (missingRows.isNotEmpty) {
        await _supabase.client.from('purchase_order_items').insert(missingRows);
      }

      return purchaseOrderId;
    }

    final orderRow = await _supabase.client
        .from('purchase_orders')
        .insert({
          'company_id': companyId,
          'supplier_id': supplierId,
          'po_number': po,
          'status': 'PENDING',
          'order_date': normalizedOrderDate.toIso8601String().split('T').first,
          'subtotal': subtotal,
          'tax_amount': taxAmount,
          'shipping_cost': shippingCost,
          'discount_amount': discountAmount,
          'total_amount': total,
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
          'created_by': createdBy,
        })
        .select('id')
        .single();

    final purchaseOrderId = orderRow['id'] as String;

    try {
      final purchaseItemRows = items
          .map((i) => i.toInsertJson(purchaseOrderId: purchaseOrderId))
          .toList();
      await _supabase.client
          .from('purchase_order_items')
          .insert(purchaseItemRows);
    } catch (e) {
      // Best-effort cleanup to avoid leaving empty orders.
      await _supabase.client
          .from('purchase_orders')
          .delete()
          .eq('id', purchaseOrderId);
      rethrow;
    }

    return purchaseOrderId;
  }

  String _generatePoNumber(DateTime d, String requestId) {
    final yyyy = d.year.toString().padLeft(4, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final suffix = requestId.substring(0, 8);
    return 'PO-$yyyy$mm$dd-$suffix';
  }

  Map<String, dynamic> _purchaseItemComparableRow(Map<String, dynamic> row) {
    return {
      'product_id': row['product_id'],
      'quantity': row['quantity'],
      'unit_cost': row['unit_cost'],
      'warehouse_id': row['warehouse_id'],
      'batch_number': row['batch_number'],
    };
  }

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

    // Batch-aware inventory (matches DB trigger logic)
    if (batchNumber == null) {
      q = q.isFilter('batch_number', null);
    } else {
      q = q.eq('batch_number', batchNumber);
    }

    final row = await q.maybeSingle();
    if (row == null) return 0;
    final qty = (row['quantity'] as int?) ?? 0;
    return qty;
  }

  Future<void> receivePurchaseOrder({
    required String purchaseOrderId,
    required String companyId,
    required String receivedBy,
    required String fallbackWarehouseId,
    required Map<String, int> receiveByItemId,
    Map<String, String?>? warehouseByItemId,
  }) async {
    if (receiveByItemId.isEmpty) {
      throw Exception('Nothing to receive');
    }

    final detail =
        await getPurchaseOrderDetail(purchaseOrderId: purchaseOrderId);

    // Map itemId -> model, validate quantities.
    final itemById = <String, PurchaseOrderItemModel>{
      for (final i in detail.items) i.id: i,
    };

    final movementRows = <Map<String, dynamic>>[];

    final itemUpdateActions = <({String itemId, int newReceived})>[];
    var willBeFullyReceived = true;

    for (final entry in receiveByItemId.entries) {
      final itemId = entry.key;
      final receiveQty = entry.value;
      if (receiveQty <= 0) continue;

      final item = itemById[itemId];
      if (item == null) {
        throw Exception('Unknown purchase item: $itemId');
      }
      if (receiveQty > item.remainingQuantity) {
        throw Exception(
          'Receive qty exceeds remaining for ${item.productSku ?? item.productName ?? item.productId}',
        );
      }

      final warehouseId = resolveReceiveWarehouseId(
        item: item,
        fallbackWarehouseId: fallbackWarehouseId,
        warehouseByItemId: warehouseByItemId,
      );
      final beforeQty = await _getInventoryQuantity(
        productId: item.productId,
        warehouseId: warehouseId,
        batchNumber: item.batchNumber,
      );

      movementRows.add({
        'company_id': companyId,
        'product_id': item.productId,
        'warehouse_id': warehouseId,
        'movement_type': 'PURCHASE',
        'quantity_change': receiveQty,
        'quantity_before': beforeQty,
        'reference_type': 'PURCHASE_ORDER',
        'reference_id': purchaseOrderId,
        if (item.batchNumber != null) 'batch_number': item.batchNumber,
        'created_by': receivedBy,
      });

      final newReceived = item.receivedQuantity + receiveQty;
      itemUpdateActions.add((itemId: item.id, newReceived: newReceived));

      // Track whether the order will become fully received after applying this.
      if (newReceived < item.quantity) {
        willBeFullyReceived = false;
      }
    }

    // Items not included in receiveByItemId must already be fully received.
    for (final item in detail.items) {
      final delta = receiveByItemId[item.id] ?? 0;
      if (item.receivedQuantity + delta < item.quantity) {
        willBeFullyReceived = false;
        break;
      }
    }

    if (movementRows.isEmpty) {
      throw Exception('Nothing to receive');
    }

    // 1) Insert stock movements first (inventory trigger updates stock).
    try {
      await _supabase.client.from('stock_movements').insert(movementRows);
    } catch (_) {
      await _sync.enqueueInsert(table: 'stock_movements', rows: movementRows);
      for (final a in itemUpdateActions) {
        await _sync.enqueueUpdate(
          table: 'purchase_order_items',
          values: {'received_quantity': a.newReceived},
          match: {'id': a.itemId},
        );
      }
      if (willBeFullyReceived) {
        await _sync.enqueueUpdate(
          table: 'purchase_orders',
          values: {
            'status': 'RECEIVED',
            'actual_delivery':
                DateTime.now().toUtc().toIso8601String().split('T').first,
          },
          match: {'id': purchaseOrderId},
        );
      }
      throw const QueuedForSyncException(
          'Network issue: purchase receive queued for sync.');
    }

    // 2) Update received quantities.
    for (final a in itemUpdateActions) {
      try {
        await _supabase.client
            .from('purchase_order_items')
            .update({'received_quantity': a.newReceived}).eq('id', a.itemId);
      } catch (_) {
        await _sync.enqueueUpdate(
          table: 'purchase_order_items',
          values: {'received_quantity': a.newReceived},
          match: {'id': a.itemId},
        );
      }
    }

    // 3) If fully received after updates, mark order as RECEIVED.
    if (willBeFullyReceived) {
      try {
        await _supabase.client.from('purchase_orders').update({
          'status': 'RECEIVED',
          'actual_delivery':
              DateTime.now().toUtc().toIso8601String().split('T').first,
        }).eq('id', purchaseOrderId);
      } catch (_) {
        await _sync.enqueueUpdate(
          table: 'purchase_orders',
          values: {
            'status': 'RECEIVED',
            'actual_delivery':
                DateTime.now().toUtc().toIso8601String().split('T').first,
          },
          match: {'id': purchaseOrderId},
        );
      }
    }
  }
}

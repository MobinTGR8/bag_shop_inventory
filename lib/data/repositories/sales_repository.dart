import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/supabase_service.dart';
import '../../services/sync_service.dart';
import '../models/sales/sales_order_model.dart';
import '../models/sales/sales_order_detail_model.dart';

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  return SalesRepository(
    ref.watch(supabaseServiceProvider),
    ref.watch(syncServiceProvider),
  );
});

class SalesRepository {
  final SupabaseService _supabase;
  final SyncService _sync;

  SalesRepository(this._supabase, this._sync);

  Stream<List<SalesOrderModel>> watchSalesOrders({
    String? companyId,
    Duration pollInterval = const Duration(seconds: 10),
  }) async* {
    while (true) {
      yield await listSalesOrders(companyId: companyId);
      await Future<void>.delayed(pollInterval);
    }
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

    if (batchNumber == null) {
      q = q.isFilter('batch_number', null);
    } else {
      q = q.eq('batch_number', batchNumber);
    }

    final row = await q.maybeSingle();
    if (row == null) return 0;
    return (row['quantity'] as int?) ?? 0;
  }

  Future<List<SalesOrderModel>> listSalesOrders({
    String? companyId,
    int limit = 200,
  }) async {
    if (companyId == null) return <SalesOrderModel>[];
    final response = await _supabase.client
        .from('sales_orders')
        .select(
          'id, company_id, customer_id, invoice_number, status, sale_date, due_date, subtotal, tax_amount, discount_amount, shipping_charge, total_amount, amount_paid, payment_status, payment_method, shipping_address, shipping_method, tracking_number, notes, created_by, created_at, updated_at, customers(name)',
        )
        .eq('company_id', companyId)
        .order('sale_date', ascending: false)
        .limit(limit);

    final orders = <SalesOrderModel>[];
    for (final row in (response as List)) {
      try {
        orders.add(SalesOrderModel.fromJson(row as Map<String, dynamic>));
      } catch (_) {
        // Skip malformed rows so one bad record does not break the entire list.
      }
    }
    return orders;
  }

  String _dateOnly(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<({String id, String invoiceNumber, bool queuedForSync})> createSale({
    required String companyId,
    required String createdBy,
    required String warehouseId,
    required List<({String productId, int quantity, double unitPrice})> items,
    String status = 'CONFIRMED',
    String paymentStatus = 'PAID',
    String? paymentMethod,
    Map<String, dynamic>? paymentSplit,
    double taxAmount = 0,
    double discountAmount = 0,
    double shippingCharge = 0,
    String? clientRequestId,
  }) async {
    if (items.isEmpty) {
      throw Exception('Cart is empty');
    }

    // Fetch current inventory for audit + basic validation.
    final invRows = await _supabase.client
        .from('inventory')
        .select('product_id, quantity')
        .eq('warehouse_id', warehouseId)
        .limit(5000);

    final invByProduct = <String, int>{
      for (final r in (invRows as List))
        (r as Map<String, dynamic>)['product_id'] as String:
            (r['quantity'] as int?) ?? 0,
    };

    for (final item in items) {
      final current = invByProduct[item.productId] ?? 0;
      if (item.quantity <= 0) {
        throw Exception('Invalid quantity for ${item.productId}');
      }
      if (current < item.quantity) {
        throw Exception('Insufficient stock for ${item.productId}');
      }
    }

    final subtotal = items.fold<double>(
      0,
      (sum, i) => sum + (i.unitPrice * i.quantity),
    );
    final totalAmount = subtotal + taxAmount + shippingCharge - discountAmount;

    final resolvedPaymentMethod =
        paymentMethod ?? (paymentSplit != null ? 'SPLIT' : null);

    // Insert order without invoice_number (DB trigger will generate).
    final order = await _supabase.client
        .from('sales_orders')
        .insert({
          'company_id': companyId,
          'status': status,
          'sale_date': _dateOnly(DateTime.now()),
          'subtotal': subtotal,
          'tax_amount': taxAmount,
          'discount_amount': discountAmount,
          'shipping_charge': shippingCharge,
          'total_amount': totalAmount,
          'amount_paid': totalAmount,
          'payment_status': paymentStatus,
          if (resolvedPaymentMethod != null)
            'payment_method': resolvedPaymentMethod,
          'created_by': createdBy,
        })
        .select('id, invoice_number')
        .single();

    final salesOrderId = order['id'] as String;
    final invoiceNumber = (order['invoice_number'] as String?) ?? '';

    var queued = false;

    final itemRows = [
      for (final item in items)
        {
          'sales_order_id': salesOrderId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'discount_percent': 0,
          'warehouse_id': warehouseId,
        }
    ];

    try {
      await _supabase.client.from('sales_order_items').insert(itemRows);
    } catch (_) {
      await _sync.enqueueInsert(table: 'sales_order_items', rows: itemRows);
      queued = true;
    }

    // Record stock movements (will update inventory via trigger).
    final movementRows = [
      for (final item in items)
        {
          'company_id': companyId,
          'product_id': item.productId,
          'warehouse_id': warehouseId,
          'movement_type': 'SALE',
          'quantity_change': -item.quantity,
          'quantity_before': invByProduct[item.productId] ?? 0,
          'reference_type': 'SALES_ORDER',
          'reference_id': salesOrderId,
          'created_by': createdBy,
        }
    ];

    try {
      await _supabase.client.from('stock_movements').insert(movementRows);
    } catch (_) {
      await _sync.enqueueInsert(table: 'stock_movements', rows: movementRows);
      queued = true;
    }

    return (
      id: salesOrderId,
      invoiceNumber: invoiceNumber,
      queuedForSync: queued
    );
  }

  Future<SalesOrderDetailModel> getSalesOrderDetail({
    required String salesOrderId,
  }) async {
    final row = await _supabase.client
        .from('sales_orders')
        .select(
          'id, company_id, customer_id, invoice_number, status, sale_date, due_date, subtotal, tax_amount, discount_amount, shipping_charge, total_amount, amount_paid, payment_status, payment_method, shipping_address, shipping_method, tracking_number, notes, created_by, created_at, updated_at, customers(name),'
          'sales_order_items(id, product_id, quantity, unit_price, warehouse_id, products(name, sku), warehouses(name))',
        )
        .eq('id', salesOrderId)
        .single();

    final map = row;
    final itemsRaw = (map['sales_order_items'] as List?) ?? const [];
    final items = <SalesOrderItemDetailModel>[];
    for (final item in itemsRaw) {
      try {
        items.add(
            SalesOrderItemDetailModel.fromJson(item as Map<String, dynamic>));
      } catch (_) {
        // Keep the order visible even if one line item is malformed.
      }
    }

    return SalesOrderDetailModel(
      order: SalesOrderModel.fromJson(map),
      items: items,
    );
  }

  Future<void> returnSaleItems({
    required String companyId,
    required String createdBy,
    required String salesOrderId,
    required List<
            ({
              String itemId,
              String productId,
              String warehouseId,
              int quantity
            })>
        items,
  }) async {
    if (items.isEmpty) throw Exception('Nothing to return');

    final movements = <Map<String, dynamic>>[];
    for (final item in items) {
      if (item.quantity <= 0) continue;
      final before = await _getInventoryQuantity(
        productId: item.productId,
        warehouseId: item.warehouseId,
      );

      movements.add({
        'company_id': companyId,
        'product_id': item.productId,
        'warehouse_id': item.warehouseId,
        'movement_type': 'RETURN',
        'quantity_change': item.quantity,
        'quantity_before': before,
        'reference_type': 'SALES_ORDER',
        'reference_id': salesOrderId,
        'created_by': createdBy,
      });
    }

    if (movements.isEmpty) throw Exception('Nothing to return');
    try {
      await _supabase.client.from('stock_movements').insert(movements);
    } catch (_) {
      await _sync.enqueueInsert(table: 'stock_movements', rows: movements);
      throw const QueuedForSyncException(
          'Network issue: return queued for sync.');
    }
  }
}

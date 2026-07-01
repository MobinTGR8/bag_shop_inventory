import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/supabase_service.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(ref.watch(supabaseServiceProvider));
});

class SalesDailyTotal {
  final DateTime date;
  final double total;

  const SalesDailyTotal({required this.date, required this.total});
}

class TopSellingProduct {
  final String productId;
  final String? sku;
  final String name;
  final int quantity;
  final double revenue;

  const TopSellingProduct({
    required this.productId,
    required this.sku,
    required this.name,
    required this.quantity,
    required this.revenue,
  });
}

class SalesReportData {
  final DateTime from;
  final DateTime to;
  final int ordersCount;
  final double revenue;
  final List<SalesDailyTotal> dailyTotals;
  final List<TopSellingProduct> topProducts;

  const SalesReportData({
    required this.from,
    required this.to,
    required this.ordersCount,
    required this.revenue,
    required this.dailyTotals,
    required this.topProducts,
  });
}

class ProfitReportData {
  final DateTime from;
  final DateTime to;
  final double revenue;
  final double cogs;
  final double grossProfit;
  final double marginPercent;

  const ProfitReportData({
    required this.from,
    required this.to,
    required this.revenue,
    required this.cogs,
    required this.grossProfit,
    required this.marginPercent,
  });
}

class InventoryValuationLine {
  final String productId;
  final String sku;
  final String name;
  final int quantity;
  final double unitCost;
  final double value;

  const InventoryValuationLine({
    required this.productId,
    required this.sku,
    required this.name,
    required this.quantity,
    required this.unitCost,
    required this.value,
  });
}

class InventoryValuationReportData {
  final DateTime generatedAt;
  final double totalValue;
  final List<InventoryValuationLine> lines;

  const InventoryValuationReportData({
    required this.generatedAt,
    required this.totalValue,
    required this.lines,
  });
}

class SupplierPerformanceLine {
  final String supplierId;
  final String name;
  final int purchaseCount;
  final double totalOrdered;
  final int receivedCount;
  final double receivedAmount;

  const SupplierPerformanceLine({
    required this.supplierId,
    required this.name,
    required this.purchaseCount,
    required this.totalOrdered,
    required this.receivedCount,
    required this.receivedAmount,
  });
}

class SupplierPerformanceReportData {
  final DateTime from;
  final DateTime to;
  final List<SupplierPerformanceLine> lines;

  const SupplierPerformanceReportData({
    required this.from,
    required this.to,
    required this.lines,
  });
}

class StockReportLine {
  final String productId;
  final String sku;
  final String name;
  final int minStock;
  final int currentStock;

  const StockReportLine({
    required this.productId,
    required this.sku,
    required this.name,
    required this.minStock,
    required this.currentStock,
  });

  bool get isLowStock => currentStock <= minStock;
}

class ReportsRepository {
  final SupabaseService _supabase;

  ReportsRepository(this._supabase);

  String _dateOnly(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<SalesReportData> getSalesReport({
    required String companyId,
    int lastDays = 30,
  }) async {
    final to = DateTime.now();
    final from = to.subtract(Duration(days: lastDays));

    final ordersRaw = await _supabase.client
        .from('sales_orders')
        .select('sale_date, total_amount')
        .eq('company_id', companyId)
        .gte('sale_date', _dateOnly(from))
        .lte('sale_date', _dateOnly(to))
        .order('sale_date');

    final orders = ordersRaw as List;

    double revenue = 0;
    final byDay = <String, double>{};

    for (final row in orders) {
      final map = row as Map<String, dynamic>;
      final dateStr = map['sale_date'] as String?;
      final total = (map['total_amount'] as num?)?.toDouble() ?? 0.0;
      revenue += total;

      if (dateStr != null) {
        byDay.update(dateStr, (v) => v + total, ifAbsent: () => total);
      }
    }

    final dailyTotals = byDay.entries
        .map(
            (e) => SalesDailyTotal(date: DateTime.parse(e.key), total: e.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Top products (by revenue) from sales_order_items joined to orders
    final items = await _supabase.client
        .from('sales_order_items')
        .select(
          'product_id, quantity, line_total, products(name, sku), sales_orders!inner(company_id, sale_date)',
        )
        .eq('sales_orders.company_id', companyId)
        .gte('sales_orders.sale_date', _dateOnly(from))
        .lte('sales_orders.sale_date', _dateOnly(to))
        .limit(5000);

    final byProduct =
        <String, ({String name, String? sku, int qty, double rev})>{};

    for (final row in (items as List)) {
      final map = row as Map<String, dynamic>;
      final productId = map['product_id'] as String?;
      if (productId == null) continue;

      final qty = (map['quantity'] as int?) ?? 0;
      final lineTotal = (map['line_total'] as num?)?.toDouble() ?? 0.0;
      final product = map['products'] is Map<String, dynamic>
          ? map['products'] as Map<String, dynamic>
          : null;
      final name = (product?['name'] as String?) ?? 'Unknown';
      final sku = product?['sku'] as String?;

      final existing = byProduct[productId];
      if (existing == null) {
        byProduct[productId] = (name: name, sku: sku, qty: qty, rev: lineTotal);
      } else {
        byProduct[productId] = (
          name: existing.name,
          sku: existing.sku,
          qty: existing.qty + qty,
          rev: existing.rev + lineTotal,
        );
      }
    }

    final topProducts = byProduct.entries
        .map(
          (e) => TopSellingProduct(
            productId: e.key,
            sku: e.value.sku,
            name: e.value.name,
            quantity: e.value.qty,
            revenue: e.value.rev,
          ),
        )
        .toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    return SalesReportData(
      from: from,
      to: to,
      ordersCount: orders.length,
      revenue: revenue,
      dailyTotals: dailyTotals,
      topProducts: topProducts.take(8).toList(),
    );
  }

  Future<List<StockReportLine>> getStockReport({
    required String companyId,
  }) async {
    // inventory has no company_id; filter through warehouses join.
    final rows = await _supabase.client
        .from('inventory')
        .select(
          'product_id, quantity, available_quantity, products!inner(id, company_id, sku, name, min_stock), warehouses!inner(company_id)',
        )
        .eq('warehouses.company_id', companyId)
        .eq('products.company_id', companyId)
        .limit(5000);

    final byProduct =
        <String, ({String sku, String name, int minStock, int stock})>{};

    for (final row in (rows as List)) {
      final map = row as Map<String, dynamic>;
      final productId = map['product_id'] as String?;
      if (productId == null) continue;

      final product = map['products'] is Map<String, dynamic>
          ? map['products'] as Map<String, dynamic>
          : null;
      if (product == null) continue;

      final sku = (product['sku'] as String?) ?? '';
      final name = (product['name'] as String?) ?? 'Unknown';
      final minStock = (product['min_stock'] as int?) ?? 0;

      final available = (map['available_quantity'] as int?);
      final qty = (map['quantity'] as int?) ?? 0;
      final stock = available ?? qty;

      final existing = byProduct[productId];
      if (existing == null) {
        byProduct[productId] =
            (sku: sku, name: name, minStock: minStock, stock: stock);
      } else {
        byProduct[productId] = (
          sku: existing.sku,
          name: existing.name,
          minStock: existing.minStock,
          stock: existing.stock + stock,
        );
      }
    }

    final lines = byProduct.entries
        .map(
          (e) => StockReportLine(
            productId: e.key,
            sku: e.value.sku,
            name: e.value.name,
            minStock: e.value.minStock,
            currentStock: e.value.stock,
          ),
        )
        .toList()
      ..sort((a, b) {
        final al = a.isLowStock ? 0 : 1;
        final bl = b.isLowStock ? 0 : 1;
        if (al != bl) return al.compareTo(bl);
        return a.currentStock.compareTo(b.currentStock);
      });

    return lines;
  }

  Future<ProfitReportData> getProfitReport({
    required String companyId,
    int lastDays = 30,
  }) async {
    final to = DateTime.now();
    final from = to.subtract(Duration(days: lastDays));

    final sales = await _supabase.client
        .from('sales_orders')
        .select('id, total_amount, sale_date')
        .eq('company_id', companyId)
        .gte('sale_date', _dateOnly(from))
        .lte('sale_date', _dateOnly(to));

    final items = await _supabase.client
        .from('sales_order_items')
        .select(
            'quantity, unit_price, products(unit_cost), sales_orders!inner(company_id, sale_date)')
        .eq('sales_orders.company_id', companyId)
        .gte('sales_orders.sale_date', _dateOnly(from))
        .lte('sales_orders.sale_date', _dateOnly(to));

    var revenue = 0.0;
    for (final row in sales as List) {
      final map = row as Map<String, dynamic>;
      revenue += (map['total_amount'] as num?)?.toDouble() ?? 0.0;
    }

    var cogs = 0.0;
    for (final row in items as List) {
      final map = row as Map<String, dynamic>;
      final qty = (map['quantity'] as int?) ?? 0;
      final product = map['products'] is Map<String, dynamic>
          ? map['products'] as Map<String, dynamic>
          : null;
      final unitCost = (product?['unit_cost'] as num?)?.toDouble() ?? 0.0;
      cogs += (qty * unitCost).toDouble();
    }

    final grossProfit = revenue - cogs;
    final marginPercent = revenue <= 0 ? 0.0 : (grossProfit / revenue) * 100;

    return ProfitReportData(
      from: from,
      to: to,
      revenue: revenue,
      cogs: cogs,
      grossProfit: grossProfit,
      marginPercent: marginPercent,
    );
  }

  Future<InventoryValuationReportData> getInventoryValuation({
    required String companyId,
  }) async {
    final rows = await _supabase.client
        .from('inventory')
        .select(
            'quantity, products!inner(id, company_id, sku, name, unit_cost), warehouses!inner(company_id)')
        .eq('warehouses.company_id', companyId)
        .eq('products.company_id', companyId)
        .limit(5000);

    final lines = <InventoryValuationLine>[];
    var totalValue = 0.0;

    for (final row in rows as List) {
      final map = row as Map<String, dynamic>;
      final product = map['products'] as Map<String, dynamic>?;
      if (product == null) continue;
      final quantity = (map['quantity'] as int?) ?? 0;
      final unitCost = (product['unit_cost'] as num?)?.toDouble() ?? 0;
      final value = (quantity * unitCost).toDouble();
      totalValue += value;
      lines.add(InventoryValuationLine(
        productId: product['id'] as String,
        sku: (product['sku'] as String?) ?? '',
        name: (product['name'] as String?) ?? 'Unknown',
        quantity: quantity,
        unitCost: unitCost,
        value: value,
      ));
    }

    lines.sort((a, b) => b.value.compareTo(a.value));

    return InventoryValuationReportData(
      generatedAt: DateTime.now(),
      totalValue: totalValue,
      lines: lines,
    );
  }

  Future<SupplierPerformanceReportData> getSupplierPerformance({
    required String companyId,
    int lastDays = 90,
  }) async {
    final to = DateTime.now();
    final from = to.subtract(Duration(days: lastDays));

    final rows = await _supabase.client
        .from('purchase_orders')
        .select(
            'supplier_id, total_amount, status, suppliers(name), purchase_order_items(quantity, unit_cost)')
        .eq('company_id', companyId)
        .gte('order_date', _dateOnly(from))
        .lte('order_date', _dateOnly(to))
        .limit(5000);

    final bySupplier = <String,
        ({
      String name,
      int count,
      double ordered,
      int received,
      double receivedAmount
    })>{};

    for (final row in rows as List) {
      final map = row as Map<String, dynamic>;
      final supplierId = map['supplier_id'] as String? ?? 'unknown';
      final supplier = map['suppliers'] as Map<String, dynamic>?;
      final name = supplier?['name'] as String? ?? 'Unknown';
      final ordered = (map['total_amount'] as num?)?.toDouble() ?? 0.0;
      final status = (map['status'] as String?) ?? 'PENDING';
      double receivedAmount = 0;
      final items = (map['purchase_order_items'] as List?) ?? const [];
      for (final item in items) {
        final im = item as Map<String, dynamic>;
        final qty = (im['quantity'] as int?) ?? 0;
        final unitCost = (im['unit_cost'] as num?)?.toDouble() ?? 0.0;
        receivedAmount += qty * unitCost;
      }

      final current = bySupplier[supplierId];
      if (current == null) {
        bySupplier[supplierId] = (
          name: name,
          count: 1,
          ordered: ordered,
          received: status == 'RECEIVED' ? 1 : 0,
          receivedAmount: receivedAmount,
        );
      } else {
        bySupplier[supplierId] = (
          name: current.name,
          count: current.count + 1,
          ordered: current.ordered + ordered,
          received: current.received + (status == 'RECEIVED' ? 1 : 0),
          receivedAmount: current.receivedAmount + receivedAmount,
        );
      }
    }

    final lines = bySupplier.entries
        .map((e) => SupplierPerformanceLine(
              supplierId: e.key,
              name: e.value.name,
              purchaseCount: e.value.count,
              totalOrdered: e.value.ordered,
              receivedCount: e.value.received,
              receivedAmount: e.value.receivedAmount,
            ))
        .toList()
      ..sort((a, b) => b.totalOrdered.compareTo(a.totalOrdered));

    return SupplierPerformanceReportData(from: from, to: to, lines: lines);
  }
}

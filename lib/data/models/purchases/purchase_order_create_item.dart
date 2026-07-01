class PurchaseOrderCreateItem {
  final String productId;
  final int quantity;
  final double unitCost;
  final String? warehouseId;
  final String? batchNumber;

  const PurchaseOrderCreateItem({
    required this.productId,
    required this.quantity,
    required this.unitCost,
    this.warehouseId,
    this.batchNumber,
  });

  Map<String, dynamic> toInsertJson({required String purchaseOrderId}) {
    return {
      'purchase_order_id': purchaseOrderId,
      'product_id': productId,
      'quantity': quantity,
      'unit_cost': unitCost,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      if (batchNumber != null) 'batch_number': batchNumber,
    };
  }
}

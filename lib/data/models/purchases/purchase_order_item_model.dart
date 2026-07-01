class PurchaseOrderItemModel {
  final String id;
  final String productId;
  final int quantity;
  final double? unitCost;
  final String? warehouseId;
  final String? batchNumber;
  final int receivedQuantity;

  // Joined fields
  final String? productName;
  final String? productSku;

  const PurchaseOrderItemModel({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.unitCost,
    required this.warehouseId,
    required this.batchNumber,
    required this.receivedQuantity,
    required this.productName,
    required this.productSku,
  });

  int get remainingQuantity {
    final remaining = quantity - receivedQuantity;
    return remaining < 0 ? 0 : remaining;
  }

  factory PurchaseOrderItemModel.fromJson(Map<String, dynamic> json) {
    final product = json['products'] is Map<String, dynamic>
        ? (json['products'] as Map<String, dynamic>)
        : null;

    return PurchaseOrderItemModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      quantity: (json['quantity'] as int?) ?? 0,
      unitCost: (json['unit_cost'] as num?)?.toDouble(),
      warehouseId: json['warehouse_id'] as String?,
      batchNumber: json['batch_number'] as String?,
      receivedQuantity: (json['received_quantity'] as int?) ?? 0,
      productName: product?['name'] as String?,
      productSku: product?['sku'] as String?,
    );
  }
}

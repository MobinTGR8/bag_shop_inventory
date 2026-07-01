import 'package:equatable/equatable.dart';

class InventoryModel extends Equatable {
  final String? id;
  final String productId;
  final String warehouseId;

  final String? productName;
  final String? productSku;
  final String? warehouseName;

  final int quantity;
  final int reservedQuantity;
  final int? availableQuantity;

  final String? batchNumber;
  final DateTime? manufacturingDate;
  final DateTime? expiryDate;

  final String condition;
  final String? notes;

  final DateTime? lastCounted;

  final DateTime lastUpdated;

  InventoryModel({
    this.id,
    required this.productId,
    required this.warehouseId,
    this.productName,
    this.productSku,
    this.warehouseName,
    this.quantity = 0,
    this.reservedQuantity = 0,
    this.availableQuantity,
    this.batchNumber,
    this.manufacturingDate,
    this.expiryDate,
    this.condition = 'NEW',
    this.notes,
    this.lastCounted,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    final product = json['products'];
    final warehouse = json['warehouses'];

    final productMap = product is Map<String, dynamic> ? product : null;
    final warehouseMap = warehouse is Map<String, dynamic> ? warehouse : null;

    return InventoryModel(
      id: json['id'],
      productId: json['product_id'],
      warehouseId: json['warehouse_id'],
      productName: productMap?['name'] as String?,
      productSku: productMap?['sku'] as String?,
      warehouseName: warehouseMap?['name'] as String?,
      quantity: json['quantity'] ?? 0,
      reservedQuantity: json['reserved_quantity'] ?? 0,
      availableQuantity: json['available_quantity'],
      batchNumber: json['batch_number'],
      manufacturingDate: json['manufacturing_date'] != null
          ? DateTime.parse(json['manufacturing_date'])
          : null,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'])
          : null,
      condition: json['condition'] ?? 'NEW',
      notes: json['notes'],
      lastCounted: json['last_counted'] != null
          ? DateTime.parse(json['last_counted'])
          : null,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'product_id': productId,
      'warehouse_id': warehouseId,
      'quantity': quantity,
      'reserved_quantity': reservedQuantity,
      if (availableQuantity != null) 'available_quantity': availableQuantity,
      if (batchNumber != null) 'batch_number': batchNumber,
      if (manufacturingDate != null)
        'manufacturing_date': manufacturingDate!.toIso8601String(),
      if (expiryDate != null) 'expiry_date': expiryDate!.toIso8601String(),
      'condition': condition,
      if (notes != null) 'notes': notes,
      if (lastCounted != null) 'last_counted': lastCounted!.toIso8601String(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        warehouseId,
        productName,
        productSku,
        warehouseName,
        quantity,
        reservedQuantity,
        availableQuantity,
        batchNumber,
        manufacturingDate,
        expiryDate,
        condition,
        notes,
        lastCounted,
        lastUpdated,
      ];
}

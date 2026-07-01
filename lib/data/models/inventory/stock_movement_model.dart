import 'package:equatable/equatable.dart';

class StockMovementModel extends Equatable {
  final String id;
  final String companyId;
  final String productId;
  final String warehouseId;
  final String movementType;
  final int quantityChange;
  final int? quantityBefore;
  final String? batchNumber;
  final String? referenceType;
  final String? referenceId;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;

  // Joined fields
  final String? productName;
  final String? productSku;
  final String? warehouseName;

  const StockMovementModel({
    required this.id,
    required this.companyId,
    required this.productId,
    required this.warehouseId,
    required this.movementType,
    required this.quantityChange,
    required this.quantityBefore,
    required this.batchNumber,
    required this.referenceType,
    required this.referenceId,
    required this.notes,
    required this.createdBy,
    required this.createdAt,
    required this.productName,
    required this.productSku,
    required this.warehouseName,
  });

  factory StockMovementModel.fromJson(Map<String, dynamic> json) {
    final product = json['products'];
    final warehouse = json['warehouses'];

    final productMap = product is Map<String, dynamic> ? product : null;
    final warehouseMap = warehouse is Map<String, dynamic> ? warehouse : null;

    return StockMovementModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      productId: json['product_id'] as String,
      warehouseId: json['warehouse_id'] as String,
      movementType: (json['movement_type'] as String?) ?? '',
      quantityChange: (json['quantity_change'] as int?) ?? 0,
      quantityBefore: json['quantity_before'] as int?,
      batchNumber: json['batch_number'] as String?,
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as String?,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      productName: productMap?['name'] as String?,
      productSku: productMap?['sku'] as String?,
      warehouseName: warehouseMap?['name'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        productId,
        warehouseId,
        movementType,
        quantityChange,
        quantityBefore,
        batchNumber,
        referenceType,
        referenceId,
        notes,
        createdBy,
        createdAt,
        productName,
        productSku,
        warehouseName,
      ];
}

import 'package:equatable/equatable.dart';

import 'sales_order_model.dart';

class SalesOrderItemDetailModel extends Equatable {
  final String id;
  final String productId;
  final int quantity;
  final double unitPrice;
  final String? warehouseId;

  final String? productName;
  final String? productSku;
  final String? warehouseName;

  const SalesOrderItemDetailModel({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.warehouseId,
    required this.productName,
    required this.productSku,
    required this.warehouseName,
  });

  factory SalesOrderItemDetailModel.fromJson(Map<String, dynamic> json) {
    final product = json['products'];
    final warehouse = json['warehouses'];

    final productMap = product is Map<String, dynamic> ? product : null;
    final warehouseMap = warehouse is Map<String, dynamic> ? warehouse : null;

    return SalesOrderItemDetailModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      quantity: (json['quantity'] as int?) ?? 0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      warehouseId: json['warehouse_id'] as String?,
      productName: productMap?['name'] as String?,
      productSku: productMap?['sku'] as String?,
      warehouseName: warehouseMap?['name'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        quantity,
        unitPrice,
        warehouseId,
        productName,
        productSku,
        warehouseName,
      ];
}

class SalesOrderDetailModel extends Equatable {
  final SalesOrderModel order;
  final List<SalesOrderItemDetailModel> items;

  const SalesOrderDetailModel({
    required this.order,
    required this.items,
  });

  @override
  List<Object?> get props => [order, items];
}

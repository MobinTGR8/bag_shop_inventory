import 'purchase_order_model.dart';
import 'purchase_order_item_model.dart';

class PurchaseOrderDetailModel {
  final PurchaseOrderModel order;
  final String? supplierName;
  final List<PurchaseOrderItemModel> items;

  const PurchaseOrderDetailModel({
    required this.order,
    required this.supplierName,
    required this.items,
  });

  bool get isFullyReceived => items.every((i) => i.remainingQuantity <= 0);
}

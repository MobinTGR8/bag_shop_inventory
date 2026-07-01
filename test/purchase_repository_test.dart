import 'package:flutter_test/flutter_test.dart';

import 'package:bag_shop_inventory/data/models/purchases/purchase_order_create_item.dart';
import 'package:bag_shop_inventory/data/models/purchases/purchase_order_item_model.dart';
import 'package:bag_shop_inventory/data/repositories/purchase_repository.dart';

void main() {
  test('PurchaseRepository calculates totals from line items', () {
    final items = [
      const PurchaseOrderCreateItem(
        productId: 'p1',
        quantity: 3,
        unitCost: 10,
      ),
      const PurchaseOrderCreateItem(
        productId: 'p2',
        quantity: 2,
        unitCost: 7.5,
      ),
    ];

    final subtotal = PurchaseRepository.calculateSubtotal(items);
    final total = PurchaseRepository.calculateTotal(
      subtotal: subtotal,
      taxAmount: 5,
      shippingCost: 2,
      discountAmount: 4,
    );

    expect(subtotal, 45);
    expect(total, 48);
  });

  test('PurchaseRepository resolves receive warehouse overrides', () {
    const item = PurchaseOrderItemModel(
      id: 'item-1',
      productId: 'p1',
      quantity: 10,
      unitCost: 5,
      warehouseId: 'item-wh',
      batchNumber: null,
      receivedQuantity: 4,
      productName: 'Bag',
      productSku: 'BAG-1',
    );

    expect(
      PurchaseRepository.resolveReceiveWarehouseId(
        item: item,
        fallbackWarehouseId: 'default-wh',
        warehouseByItemId: const {'item-1': 'override-wh'},
      ),
      'override-wh',
    );

    expect(
      PurchaseRepository.resolveReceiveWarehouseId(
        item: item,
        fallbackWarehouseId: 'default-wh',
        warehouseByItemId: const {},
      ),
      'item-wh',
    );

    const fallbackOnlyItem = PurchaseOrderItemModel(
      id: 'item-2',
      productId: 'p2',
      quantity: 2,
      unitCost: 15,
      warehouseId: null,
      batchNumber: null,
      receivedQuantity: 0,
      productName: 'Bag 2',
      productSku: 'BAG-2',
    );

    expect(
      PurchaseRepository.resolveReceiveWarehouseId(
        item: fallbackOnlyItem,
        fallbackWarehouseId: 'default-wh',
        warehouseByItemId: null,
      ),
      'default-wh',
    );
  });
}

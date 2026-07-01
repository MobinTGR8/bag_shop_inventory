import 'package:flutter_test/flutter_test.dart';

import 'package:bag_shop_inventory/data/models/sales/sales_order_model.dart';
import 'package:bag_shop_inventory/presentation/features/inventory/providers/stock_movements_provider.dart';

void main() {
  test('SalesOrderModel preserves payment split data', () {
    final model = SalesOrderModel.fromJson(const {
      'invoice_number': 'INV-1',
      'payment_status': 'PAID',
      'payment_split': {
        'CASH': 100.0,
        'CARD': 50.0,
      },
    });

    expect(model.paymentSplit, isNotNull);
    expect(model.paymentSplit?['CASH'], 100.0);
    expect(model.toJson()['payment_split'], isA<Map<String, dynamic>>());
  });

  test('StockMovementsQuery equality includes createdBy', () {
    const first = StockMovementsQuery(createdBy: 'user-1', limit: 50);
    const second = StockMovementsQuery(createdBy: 'user-2', limit: 50);

    expect(first == second, isFalse);
    expect(first.props, contains('user-1'));
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/sales/sales_order_detail_model.dart';
import '../../../../data/repositories/sales_repository.dart';

final salesOrderDetailProvider =
    FutureProvider.family<SalesOrderDetailModel, String>((ref, id) async {
  return ref
      .watch(salesRepositoryProvider)
      .getSalesOrderDetail(salesOrderId: id);
});

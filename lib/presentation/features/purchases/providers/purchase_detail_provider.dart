import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/purchases/purchase_order_detail_model.dart';
import '../../../../data/repositories/purchase_repository.dart';

final purchaseOrderDetailProvider =
    FutureProvider.family<PurchaseOrderDetailModel, String>((ref, id) async {
  return ref
      .watch(purchaseRepositoryProvider)
      .getPurchaseOrderDetail(purchaseOrderId: id);
});

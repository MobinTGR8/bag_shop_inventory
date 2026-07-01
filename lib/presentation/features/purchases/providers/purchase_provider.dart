import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/purchases/purchase_order_model.dart';
import '../../../../data/repositories/purchase_repository.dart';
import '../../auth/providers/auth_provider.dart';

final purchaseOrdersProvider =
    FutureProvider<List<PurchaseOrderModel>>((ref) async {
  final companyId = ref.watch(authProvider).companyId;
  return ref
      .watch(purchaseRepositoryProvider)
      .listPurchaseOrders(companyId: companyId);
});

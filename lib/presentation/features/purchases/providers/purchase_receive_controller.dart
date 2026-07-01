import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/purchase_repository.dart';

final purchaseReceiveControllerProvider =
    StateNotifierProvider<PurchaseReceiveController, AsyncValue<void>>((ref) {
  return PurchaseReceiveController(ref.watch(purchaseRepositoryProvider));
});

class PurchaseReceiveController extends StateNotifier<AsyncValue<void>> {
  final PurchaseRepository _repo;

  PurchaseReceiveController(this._repo) : super(const AsyncValue.data(null));

  Future<void> receive({
    required String purchaseOrderId,
    required String companyId,
    required String receivedBy,
    required String fallbackWarehouseId,
    required Map<String, int> receiveByItemId,
    Map<String, String?>? warehouseByItemId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repo.receivePurchaseOrder(
        purchaseOrderId: purchaseOrderId,
        companyId: companyId,
        receivedBy: receivedBy,
        fallbackWarehouseId: fallbackWarehouseId,
        receiveByItemId: receiveByItemId,
        warehouseByItemId: warehouseByItemId,
      );
    });
  }
}

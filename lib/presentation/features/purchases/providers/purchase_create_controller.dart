import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/purchases/purchase_order_create_item.dart';
import '../../../../data/repositories/purchase_repository.dart';

final purchaseCreateControllerProvider =
    StateNotifierProvider<PurchaseCreateController, AsyncValue<String?>>((ref) {
  return PurchaseCreateController(ref.watch(purchaseRepositoryProvider));
});

class PurchaseCreateController extends StateNotifier<AsyncValue<String?>> {
  final PurchaseRepository _repo;

  PurchaseCreateController(this._repo) : super(const AsyncValue.data(null));

  Future<void> create({
    required String companyId,
    required String createdBy,
    String? supplierId,
    required DateTime orderDate,
    String? poNumber,
    required List<PurchaseOrderCreateItem> items,
    String? notes,
    String? clientRequestId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final id = await _repo.createPurchaseOrder(
        companyId: companyId,
        createdBy: createdBy,
        supplierId: supplierId,
        orderDate: orderDate,
        poNumber: poNumber,
        items: items,
        notes: notes,
        clientRequestId: clientRequestId,
      );
      return id;
    });
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

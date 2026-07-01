import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/inventory/stock_movement_model.dart';
import '../../../../data/repositories/stock_movement_repository.dart';
import '../../auth/providers/auth_provider.dart';

final purchaseReceivedMovementsProvider =
    FutureProvider.family<List<StockMovementModel>, String>(
        (ref, purchaseOrderId) async {
  final companyId = ref.watch(authProvider).companyId;
  return ref.watch(stockMovementRepositoryProvider).listStockMovements(
        companyId: companyId,
        movementType: 'PURCHASE',
        referenceType: 'PURCHASE_ORDER',
        referenceId: purchaseOrderId,
        limit: 200,
      );
});

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/inventory/stock_movement_model.dart';
import '../../../../data/repositories/stock_movement_repository.dart';
import '../../auth/providers/auth_provider.dart';

class StockMovementsQuery extends Equatable {
  final String? warehouseId;
  final String? movementType;
  final String? createdBy;
  final DateTime? from;
  final DateTime? to;
  final int limit;

  const StockMovementsQuery({
    this.warehouseId,
    this.movementType,
    this.createdBy,
    this.from,
    this.to,
    this.limit = 200,
  });

  @override
  List<Object?> get props =>
      [warehouseId, movementType, createdBy, from, to, limit];
}

final stockMovementsProvider =
    FutureProvider.family<List<StockMovementModel>, StockMovementsQuery>(
  (ref, query) async {
    final companyId = ref.watch(authProvider).companyId;
    return ref.watch(stockMovementRepositoryProvider).listStockMovements(
          companyId: companyId,
          warehouseId: query.warehouseId,
          movementType: query.movementType,
          createdBy: query.createdBy,
          from: query.from,
          to: query.to,
          limit: query.limit,
        );
  },
);

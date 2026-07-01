import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/warehouse/warehouse_model.dart';
import '../../../../data/repositories/warehouse_repository.dart';
import '../../auth/providers/auth_provider.dart';

final warehousesProvider = FutureProvider<List<WarehouseModel>>((ref) async {
  final companyId = ref.watch(authProvider).companyId;
  if (companyId == null) return <WarehouseModel>[];
  return ref
      .watch(warehouseRepositoryProvider)
      .listWarehouses(companyId: companyId);
});

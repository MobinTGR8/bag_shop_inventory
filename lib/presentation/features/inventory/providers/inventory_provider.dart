import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/inventory/inventory_model.dart';
import '../../../../data/repositories/inventory_repository.dart';
import '../../auth/providers/auth_provider.dart';

final inventoryListProvider = FutureProvider<List<InventoryModel>>((ref) async {
  final companyId = ref.watch(authProvider).companyId;
  return ref
      .watch(inventoryRepositoryProvider)
      .listInventory(companyId: companyId);
});

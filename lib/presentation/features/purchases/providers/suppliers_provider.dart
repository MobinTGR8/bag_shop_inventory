import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/purchases/supplier_model.dart';
import '../../../../data/repositories/purchase_repository.dart';
import '../../auth/providers/auth_provider.dart';

final suppliersProvider = FutureProvider<List<SupplierModel>>((ref) async {
  final companyId = ref.watch(authProvider).companyId;
  if (companyId == null) return <SupplierModel>[];
  return ref
      .watch(purchaseRepositoryProvider)
      .listSuppliers(companyId: companyId);
});

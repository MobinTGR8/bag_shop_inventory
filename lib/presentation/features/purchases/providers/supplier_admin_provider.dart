import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/purchases/supplier_model.dart';
import '../../../../data/repositories/supplier_repository.dart';
import '../../auth/providers/auth_provider.dart';

final suppliersAdminProvider = FutureProvider<List<SupplierModel>>((ref) async {
  final companyId = ref.watch(authProvider).companyId;
  return ref
      .watch(supplierRepositoryProvider)
      .listSuppliers(companyId: companyId);
});

final supplierByIdProvider =
    FutureProvider.family<SupplierModel?, String>((ref, id) async {
  return ref.watch(supplierRepositoryProvider).getSupplierById(supplierId: id);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/sales/customer_model.dart';
import '../../../../data/repositories/customer_repository.dart';
import '../../auth/providers/auth_provider.dart';

final customersProvider = FutureProvider<List<CustomerModel>>((ref) async {
  final companyId = ref.watch(authProvider).companyId;
  if (companyId == null) return <CustomerModel>[];
  return ref
      .watch(customerRepositoryProvider)
      .listCustomers(companyId: companyId);
});

final customerByIdProvider =
    FutureProvider.family<CustomerModel?, String>((ref, id) async {
  return ref.watch(customerRepositoryProvider).getCustomerById(customerId: id);
});

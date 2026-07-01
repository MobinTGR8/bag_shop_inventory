import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/sales/sales_order_model.dart';
import '../../../../data/repositories/sales_repository.dart';
import '../../auth/providers/auth_provider.dart';

final salesOrdersProvider = StreamProvider<List<SalesOrderModel>>((ref) {
  final companyId = ref.watch(authProvider).companyId;
  return ref
      .watch(salesRepositoryProvider)
      .watchSalesOrders(companyId: companyId);
});

final recentSalesProvider = StreamProvider<List<SalesOrderModel>>((ref) {
  final companyId = ref.watch(authProvider).companyId;
  if (companyId == null) return const Stream<List<SalesOrderModel>>.empty();

  return ref
      .watch(salesRepositoryProvider)
      .watchSalesOrders(companyId: companyId)
      .map(
        (sales) => sales.take(5).toList(),
      );
});

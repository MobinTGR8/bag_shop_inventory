import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/reports_repository.dart';
import '../../auth/providers/auth_provider.dart';

final salesReportLastDaysProvider = StateProvider<int>((ref) => 30);
final profitReportLastDaysProvider = StateProvider<int>((ref) => 30);
final supplierPerformanceLastDaysProvider = StateProvider<int>((ref) => 90);

final salesReportProvider = FutureProvider<SalesReportData>((ref) async {
  final companyId = ref.watch(authProvider).companyId;
  if (companyId == null) {
    throw Exception('Missing companyId');
  }
  final lastDays = ref.watch(salesReportLastDaysProvider);
  return ref
      .watch(reportsRepositoryProvider)
      .getSalesReport(companyId: companyId, lastDays: lastDays);
});

final stockReportProvider = FutureProvider<List<StockReportLine>>((ref) async {
  final companyId = ref.watch(authProvider).companyId;
  if (companyId == null) {
    throw Exception('Missing companyId');
  }
  return ref
      .watch(reportsRepositoryProvider)
      .getStockReport(companyId: companyId);
});

final profitReportProvider = FutureProvider<ProfitReportData>((ref) async {
  final companyId = ref.watch(authProvider).companyId;
  if (companyId == null) {
    throw Exception('Missing companyId');
  }
  final lastDays = ref.watch(profitReportLastDaysProvider);
  return ref.watch(reportsRepositoryProvider).getProfitReport(
        companyId: companyId,
        lastDays: lastDays,
      );
});

final inventoryValuationProvider =
    FutureProvider<InventoryValuationReportData>((ref) async {
  final companyId = ref.watch(authProvider).companyId;
  if (companyId == null) {
    throw Exception('Missing companyId');
  }
  return ref.watch(reportsRepositoryProvider).getInventoryValuation(
        companyId: companyId,
      );
});

final supplierPerformanceProvider =
    FutureProvider<SupplierPerformanceReportData>((ref) async {
  final companyId = ref.watch(authProvider).companyId;
  if (companyId == null) {
    throw Exception('Missing companyId');
  }
  final lastDays = ref.watch(supplierPerformanceLastDaysProvider);
  return ref.watch(reportsRepositoryProvider).getSupplierPerformance(
        companyId: companyId,
        lastDays: lastDays,
      );
});

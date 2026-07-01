import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/reports_repository.dart';
import '../../auth/providers/auth_provider.dart';

final lowStockProvider = FutureProvider<List<StockReportLine>>((ref) async {
  final companyId = ref.watch(authProvider).companyId;
  if (companyId == null) return <StockReportLine>[];

  final lines = await ref.watch(reportsRepositoryProvider).getStockReport(
        companyId: companyId,
      );

  return lines.where((l) => l.isLowStock).toList();
});

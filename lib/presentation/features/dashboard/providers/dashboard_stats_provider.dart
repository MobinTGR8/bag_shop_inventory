import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/dashboard_repository.dart';
import '../../../../data/repositories/sales_repository.dart';
import '../../../../data/repositories/reports_repository.dart';
import '../../auth/providers/auth_provider.dart';

class DashboardStats extends Equatable {
  final int totalProducts;
  final int lowStockCount;
  final double todaySales;
  final double monthRevenue;
  final List<SalesDailyTotal> weeklySales;

  const DashboardStats({
    required this.totalProducts,
    required this.lowStockCount,
    required this.todaySales,
    required this.monthRevenue,
    required this.weeklySales,
  });

  @override
  List<Object?> get props =>
      [totalProducts, lowStockCount, todaySales, monthRevenue, weeklySales];
}

bool _isSameDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

bool _isSameMonth(DateTime left, DateTime right) {
  return left.year == right.year && left.month == right.month;
}

final dashboardStatsProvider = StreamProvider<DashboardStats>((ref) async* {
  final companyId = ref.watch(authProvider).companyId;

  if (companyId == null) {
    yield const DashboardStats(
      totalProducts: 0,
      lowStockCount: 0,
      todaySales: 0,
      monthRevenue: 0,
      weeklySales: [],
    );
    return;
  }

  final salesRepo = ref.watch(salesRepositoryProvider);
  final dashboardRepo = ref.watch(dashboardRepositoryProvider);
  final reportsRepo = ref.watch(reportsRepositoryProvider);
  final salesStream = salesRepo.watchSalesOrders(companyId: companyId);

  await for (final sales in salesStream) {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));

    final totalProducts = await dashboardRepo.countProducts(
      companyId: companyId,
    );

    final stockLines = await reportsRepo.getStockReport(
      companyId: companyId,
    );
    final lowStockCount = stockLines.where((l) => l.isLowStock).length;

    final todaySales = sales
        .where((sale) => _isSameDay(sale.saleDate, now))
        .fold<double>(0, (sum, sale) => sum + sale.totalAmount);

    final monthRevenue = sales
        .where((sale) => _isSameMonth(sale.saleDate, now))
        .fold<double>(0, (sum, sale) => sum + sale.totalAmount);

    final totalsByDay = <DateTime, double>{};
    for (final sale in sales) {
      final day =
          DateTime(sale.saleDate.year, sale.saleDate.month, sale.saleDate.day);
      if (day.isBefore(weekStart)) continue;
      totalsByDay.update(day, (value) => value + sale.totalAmount,
          ifAbsent: () => sale.totalAmount);
    }

    final weeklySales = List.generate(7, (index) {
      final day = weekStart.add(Duration(days: index));
      return SalesDailyTotal(date: day, total: totalsByDay[day] ?? 0);
    });

    yield DashboardStats(
      totalProducts: totalProducts,
      lowStockCount: lowStockCount,
      todaySales: todaySales,
      monthRevenue: monthRevenue,
      weeklySales: weeklySales,
    );
  }
});

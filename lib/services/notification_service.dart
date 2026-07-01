import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/reports_repository.dart';
import '../data/repositories/stock_movement_repository.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    reports: ref.watch(reportsRepositoryProvider),
    stockMovements: ref.watch(stockMovementRepositoryProvider),
  );
});

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final IconData icon;
  final String? route;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.icon,
    required this.route,
  });
}

class NotificationService {
  final ReportsRepository reports;
  final StockMovementRepository stockMovements;

  NotificationService({
    required this.reports,
    required this.stockMovements,
  });

  Future<List<AppNotification>> getInAppNotifications({
    required String companyId,
  }) async {
    final now = DateTime.now();
    final notifications = <AppNotification>[];

    // Low stock summary (computed from current inventory)
    final stock = await reports.getStockReport(companyId: companyId);
    final low = stock.where((l) => l.isLowStock).toList();
    if (low.isNotEmpty) {
      notifications.add(
        AppNotification(
          id: 'low_stock',
          title: 'Low stock',
          message: '${low.length} products need attention.',
          createdAt: now,
          icon: Icons.warning_amber_outlined,
          route: '/inventory',
        ),
      );
    }

    // Recent movements (quick link)
    final recent = await stockMovements.listStockMovements(
      companyId: companyId,
      limit: 1,
    );
    if (recent.isNotEmpty) {
      notifications.add(
        AppNotification(
          id: 'recent_movements',
          title: 'Stock movements',
          message: 'Review recent inventory changes.',
          createdAt: recent.first.createdAt,
          icon: Icons.swap_vert_outlined,
          route: '/inventory/movements',
        ),
      );
    }

    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notifications;
  }
}

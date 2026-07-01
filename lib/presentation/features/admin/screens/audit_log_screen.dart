import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../auth/providers/permission_provider.dart';
import '../../inventory/providers/stock_movements_provider.dart';
import '../providers/admin_staff_provider.dart';

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManage = ref.watch(canAccessAdminProvider);
    if (!canManage) {
      return Scaffold(
        appBar: AppBar(title: const Text('Audit Log')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have access to Admin tools.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final movementsAsync = ref.watch(
      stockMovementsProvider(const StockMovementsQuery(limit: 250)),
    );
    final staffAsync = ref.watch(staffListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Log'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(
                stockMovementsProvider(const StockMovementsQuery(limit: 250))),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: staffAsync.when(
        loading: () => const AppBody(child: LoadingIndicator()),
        error: (e, _) => AppBody(
          child: ErrorState(
            title: 'Failed to load staff map',
            message: e.toString(),
            onRetry: () => ref.invalidate(staffListProvider),
          ),
        ),
        data: (staff) {
          final staffNameById = <String, String>{
            for (final member in staff) member.id: member.name,
          };

          return movementsAsync.when(
            loading: () => const AppBody(child: LoadingIndicator()),
            error: (e, _) => AppBody(
              child: ErrorState(
                title: 'Failed to load audit log',
                message: e.toString(),
                onRetry: () => ref.invalidate(
                  stockMovementsProvider(const StockMovementsQuery(limit: 250)),
                ),
              ),
            ),
            data: (movements) {
              if (movements.isEmpty) {
                return const AppBody(
                  child: EmptyState(
                    title: 'No audit entries',
                    message: 'Stock movement events will appear here.',
                    icon: Icons.rule_folder_outlined,
                  ),
                );
              }

              return AppBody(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: movements.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final movement = movements[index];
                    final actor = movement.createdBy == null
                        ? 'System'
                        : (staffNameById[movement.createdBy!] ??
                            movement.createdBy!);
                    final when = movement.createdAt
                        .toLocal()
                        .toString()
                        .split('.')
                        .first;
                    final change = movement.quantityChange >= 0
                        ? '+${movement.quantityChange}'
                        : movement.quantityChange.toString();

                    return ListTile(
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: Text(
                          '${movement.movementType} • ${movement.productName ?? movement.productId}'),
                      subtitle: Text(
                        'By: $actor\nWarehouse: ${movement.warehouseName ?? movement.warehouseId}\n$when',
                      ),
                      trailing: Text(change),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

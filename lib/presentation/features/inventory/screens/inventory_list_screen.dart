import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../theme/app_theme.dart';
import '../../auth/providers/permission_provider.dart';
import '../providers/inventory_provider.dart';

class InventoryListScreen extends ConsumerWidget {
  const InventoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canView = ref.watch(canViewInventoryProvider);
    if (!canView) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inventory')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have access to Inventory.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final inventoryAsync = ref.watch(inventoryListProvider);
    final canEdit = ref.watch(canEditInventoryProvider);
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          if (canEdit)
            IconButton(onPressed: () => context.go('/inventory/adjust'), icon: const Icon(Icons.tune_outlined), tooltip: 'Adjust stock'),
          if (canEdit)
            IconButton(onPressed: () => context.go('/inventory/stock-take'), icon: const Icon(Icons.fact_check_outlined), tooltip: 'Stock take'),
          if (canEdit)
            IconButton(onPressed: () => context.go('/inventory/transfer'), icon: const Icon(Icons.swap_horiz_outlined), tooltip: 'Transfer stock'),
          IconButton(onPressed: () => context.go('/inventory/low-stock'), icon: const Icon(Icons.warning_amber_outlined), tooltip: 'Low stock'),
          IconButton(onPressed: () => context.go('/inventory/movements'), icon: const Icon(Icons.swap_vert_outlined), tooltip: 'Stock movements'),
          IconButton(onPressed: () => ref.invalidate(inventoryListProvider), icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(inventoryListProvider);
          await ref.read(inventoryListProvider.future);
        },
        child: inventoryAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return AppBody(
                child: ListView(
                  padding: EdgeInsets.zero,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [SizedBox(height: 80),
                    EmptyState(
                      title: 'No inventory records',
                      message: 'Inventory will appear here once products have stock.',
                      icon: Icons.inventory_2_outlined,
                    ),
                  ],
                ),
              );
            }

            return AppBody(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final title = item.productName?.isNotEmpty == true
                      ? item.productName!
                      : item.productSku?.isNotEmpty == true
                          ? item.productSku!
                          : item.productId;
                  final qty = item.quantity;
                  final isLow = item.availableQuantity != null && item.availableQuantity! < 5;
                  
                  return StaggeredFadeIn.build(
                    index: index,
                    child: Container(
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isLow ? AppTheme.warningColor.withOpacity(0.3) : scheme.outline.withOpacity(0.6)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isLow ? AppTheme.warningColor.withOpacity(0.12) : scheme.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isLow ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
                                color: isLow ? AppTheme.warningColor : scheme.primary, size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (item.warehouseName?.isNotEmpty == true) ...[
                                        Text(item.warehouseName!, style: tt.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.5))),
                                        Text(' • ', style: tt.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.3))),
                                      ],
                                      Text('Qty: $qty', style: tt.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.5))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$qty',
                                  style: tt.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: isLow ? AppTheme.warningColor : scheme.onSurface,
                                  ),
                                ),
                                Text(
                                  'in stock',
                                  style: tt.bodySmall?.copyWith(
                                    color: isLow ? AppTheme.warningColor : scheme.onSurface.withOpacity(0.5),
                                    fontWeight: isLow ? FontWeight.w700 : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const AppBody(child: LoadingIndicator()),
          error: (err, _) => AppBody(
            child: ErrorState(title: 'Failed to load inventory', message: err.toString(), onRetry: () => ref.invalidate(inventoryListProvider)),
          ),
        ),
      ),
    );
  }
}

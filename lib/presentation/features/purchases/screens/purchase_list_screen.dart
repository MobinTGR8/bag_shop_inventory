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
import '../providers/purchase_provider.dart';

class PurchaseListScreen extends ConsumerWidget {
  const PurchaseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canView = ref.watch(canViewPurchasesProvider);
    final canEdit = ref.watch(canEditPurchasesProvider);
    if (!canView) {
      return Scaffold(
        appBar: AppBar(title: const Text('Purchases')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have access to Purchases.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final purchasesAsync = ref.watch(purchaseOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchases'),
        actions: [
          IconButton(
            tooltip: 'Suppliers',
            onPressed: () => context.go('/purchases/suppliers'),
            icon: const Icon(Icons.local_shipping_outlined),
          ),
          if (canEdit)
            IconButton(
              onPressed: () => context.go('/purchases/add'),
              icon: const Icon(Icons.add),
              tooltip: 'Add Purchase',
            ),
          IconButton(
            onPressed: () => ref.invalidate(purchaseOrdersProvider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(purchaseOrdersProvider);
          await ref.read(purchaseOrdersProvider.future);
        },
        child: purchasesAsync.when(
          data: (orders) {
            if (orders.isEmpty) {
              return AppBody(
                child: ListView(
                  padding: EdgeInsets.zero,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 80),
                    EmptyState(
                      title: 'No purchase orders',
                      message:
                          'Create a purchase order to record incoming stock.',
                      icon: Icons.shopping_cart_outlined,
                      action: FilledButton.icon(
                        onPressed:
                            canEdit ? () => context.go('/purchases/add') : null,
                        icon: const Icon(Icons.add),
                        label: const Text('Add purchase'),
                      ),
                    ),
                  ],
                ),
              );
            }

            final tt = Theme.of(context).textTheme;
            final scheme = Theme.of(context).colorScheme;
            return AppBody(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final o = orders[index];
                  final date = '${o.orderDate.year.toString().padLeft(4, '0')}-${o.orderDate.month.toString().padLeft(2, '0')}-${o.orderDate.day.toString().padLeft(2, '0')}';
                  final title = o.poNumber.isNotEmpty ? o.poNumber : o.id;
                  final isOpen = o.status == 'OPEN' || o.status == 'PENDING';
                  
                  return StaggeredFadeIn.build(
                    index: index,
                    child: Container(
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: scheme.outline.withOpacity(0.6)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => context.go('/purchases/${o.id}'),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (isOpen ? AppTheme.infoColor : AppTheme.successColor).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isOpen ? Icons.shopping_cart_outlined : Icons.check_circle_outline,
                                    color: isOpen ? AppTheme.infoColor : AppTheme.successColor,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 4),
                                      Text(date, style: tt.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.5))),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Tk ${o.totalAmount.toStringAsFixed(0)}',
                                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: scheme.onSurface),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: (isOpen ? AppTheme.warningColor : AppTheme.successColor).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        o.status,
                                        style: tt.bodySmall?.copyWith(
                                          color: isOpen ? AppTheme.warningColor : AppTheme.successColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.chevron_right, size: 18, color: scheme.onSurface.withOpacity(0.3)),
                              ],
                            ),
                          ),
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
            child: ErrorState(
              title: 'Failed to load purchases',
              message: err.toString(),
              onRetry: () => ref.invalidate(purchaseOrdersProvider),
            ),
          ),
        ),
      ),
    );
  }
}

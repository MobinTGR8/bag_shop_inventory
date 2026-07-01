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
import '../providers/low_stock_provider.dart';

class LowStockScreen extends ConsumerWidget {
  const LowStockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canView = ref.watch(canViewInventoryProvider);
    if (!canView) {
      return Scaffold(
        appBar: AppBar(title: const Text('Low stock')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have access to Inventory.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final lowAsync = ref.watch(lowStockProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Low stock'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(lowStockProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: lowAsync.when(
        loading: () => const AppBody(child: LoadingIndicator()),
        error: (e, _) => AppBody(
          child: ErrorState(
            title: 'Failed to load low stock',
            message: e.toString(),
            onRetry: () => ref.invalidate(lowStockProvider),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return AppBody(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  EmptyState(
                    title: 'No low stock items',
                    message: 'Everything is above minimum stock.',
                    icon: Icons.check_circle_outline,
                  ),
                ],
              ),
            );
          }

          final tt = Theme.of(context).textTheme;
          final scheme = Theme.of(context).colorScheme;
          
          // Summary stats
          final critical = items.where((i) => i.currentStock < 3).length;
          
          return Column(
            children: [
              // Summary header
              FadeInSlide(
                child: Row(
                  children: [
                    _summaryCard(context, '${items.length}', 'Low Items', AppTheme.warningColor),
                    const SizedBox(width: 8),
                    _summaryCard(context, '$critical', 'Critical', AppTheme.dangerColor),
                    const SizedBox(width: 8),
                    _summaryCard(context, '${items.fold<int>(0, (s, i) => s + i.currentStock)}', 'Total Units', AppTheme.infoColor),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final l = items[index];
                    final isCritical = l.currentStock < 3;
                    final accent = isCritical ? AppTheme.dangerColor : AppTheme.warningColor;

                    return StaggeredFadeIn.build(
                      index: index,
                      child: Container(
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: accent.withOpacity(0.3)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => context.go('/products/${l.productId}'),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: accent.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isCritical ? Icons.error_outline : Icons.warning_amber_rounded,
                                      color: accent, size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(l.name, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 4),
                                        Text(l.sku, style: tt.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.5))),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${l.currentStock}',
                                        style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: accent),
                                      ),
                                      Text(
                                        'Min: ${l.minStock}',
                                        style: tt.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.5)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCard(BuildContext context, String value, String label, Color color) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withOpacity(0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

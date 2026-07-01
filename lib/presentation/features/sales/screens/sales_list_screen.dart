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
import '../providers/sales_provider.dart';

class SalesListScreen extends ConsumerWidget {
  const SalesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canView = ref.watch(canViewSalesProvider);
    if (!canView) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sales')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have access to Sales.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final salesAsync = ref.watch(salesOrdersProvider);
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
        actions: [
          IconButton(onPressed: () => context.go('/sales/add'), icon: const Icon(Icons.add), tooltip: 'Add Sale'),
          IconButton(onPressed: () => ref.invalidate(salesOrdersProvider), icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(salesOrdersProvider);
          await ref.read(salesOrdersProvider.future);
        },
        child: salesAsync.when(
          data: (orders) {
            if (orders.isEmpty) {
              return AppBody(
                child: ListView(
                  padding: EdgeInsets.zero,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 80),
                    EmptyState(
                      title: 'No sales yet',
                      message: 'Create a sale to generate invoices and track revenue.',
                      icon: Icons.receipt_long_outlined,
                      action: FilledButton.icon(
                        onPressed: () => context.go('/sales/add'),
                        icon: const Icon(Icons.add),
                        label: const Text('Add sale'),
                      ),
                    ),
                  ],
                ),
              );
            }

            return AppBody(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final o = orders[index];
                  final isPaid = o.paymentStatus == 'PAID';
                  final date = '${o.saleDate.year}-${o.saleDate.month.toString().padLeft(2, '0')}-${o.saleDate.day.toString().padLeft(2, '0')}';

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
                          onTap: o.id == null ? null : () => context.go('/sales/${o.id}'),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (isPaid ? AppTheme.successColor : AppTheme.warningColor).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.receipt_long_outlined,
                                    color: isPaid ? AppTheme.successColor : AppTheme.warningColor,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        o.invoiceNumber.isEmpty ? '(No invoice)' : o.invoiceNumber,
                                        style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (o.customerName?.trim().isNotEmpty == true) ...[
                                            Flexible(
                                              child: Text(
                                                o.customerName!,
                                                style: tt.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.6)),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(' • ', style: tt.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.3))),
                                          ],
                                          Text(date, style: tt.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.5))),
                                        ],
                                      ),
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
                                        color: (isPaid ? AppTheme.successColor : AppTheme.warningColor).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        o.paymentStatus,
                                        style: tt.bodySmall?.copyWith(
                                          color: isPaid ? AppTheme.successColor : AppTheme.warningColor,
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
            child: ErrorState(title: 'Failed to load sales', message: err.toString(), onRetry: () => ref.invalidate(salesOrdersProvider)),
          ),
        ),
      ),
    );
  }
}

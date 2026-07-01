import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../theme/app_theme.dart';
import '../../auth/providers/permission_provider.dart';
import '../providers/purchase_detail_provider.dart';
import '../providers/purchase_received_movements_provider.dart';

class PurchaseDetailScreen extends ConsumerWidget {
  final String purchaseOrderId;

  const PurchaseDetailScreen({super.key, required this.purchaseOrderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canView = ref.watch(canViewPurchasesProvider);
    if (!canView) {
      return Scaffold(
        appBar: AppBar(title: const Text('Purchase Order')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have access to Purchases.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final canEdit = ref.watch(canEditPurchasesProvider);
    final detailAsync = ref.watch(purchaseOrderDetailProvider(purchaseOrderId));
    final receivedAsync =
        ref.watch(purchaseReceivedMovementsProvider(purchaseOrderId));

  String fmtDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Widget infoChip(ColorScheme scheme, TextTheme tt, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onSurface.withOpacity(0.6)),
          const SizedBox(width: 6),
          Text(
            text,
            style: tt.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

    String fmtDateTime(DateTime d) {
      final local = d.toLocal();
      return '${fmtDate(local)} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Order'),
        actions: [
          IconButton(
            onPressed: () =>
                ref.invalidate(purchaseOrderDetailProvider(purchaseOrderId)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const AppBody(child: LoadingIndicator()),
        error: (e, _) => AppBody(
          child: ErrorState(
            title: 'Failed to load purchase order',
            message: e.toString(),
            onRetry: () =>
                ref.invalidate(purchaseOrderDetailProvider(purchaseOrderId)),
          ),
        ),
        data: (d) {
          final scheme = Theme.of(context).colorScheme;
          final tt = Theme.of(context).textTheme;
          final fullyReceived = d.isFullyReceived;

          final date =
              '${d.order.orderDate.year.toString().padLeft(4, '0')}-${d.order.orderDate.month.toString().padLeft(2, '0')}-${d.order.orderDate.day.toString().padLeft(2, '0')}';

          return AppBody(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Hero header
                FadeInSlide(
                  duration: const Duration(milliseconds: 500),
                  offset: 15,
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: fullyReceived
                            ? [AppTheme.successColor, const Color(0xFF2E7D32)]
                            : [AppTheme.infoColor, const Color(0xFF1565C0)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (fullyReceived ? AppTheme.successColor : AppTheme.infoColor).withOpacity(0.25),
                          blurRadius: 30,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                fullyReceived ? Iconsax.tick_circle : Iconsax.box_add,
                                color: Colors.white, size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.order.poNumber.isEmpty ? d.order.id : d.order.poNumber,
                                    style: tt.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    date,
                                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Total Amount', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tk ${d.order.totalAmount.toStringAsFixed(0)}',
                                    style: tt.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: (fullyReceived ? AppTheme.successColor : AppTheme.warningColor).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: (fullyReceived ? AppTheme.successColor : AppTheme.warningColor).withOpacity(0.3)),
                              ),
                              child: Text(
                                d.order.status,
                                style: TextStyle(
                                  color: fullyReceived ? AppTheme.successColor : AppTheme.warningColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Info chips
                FadeInSlide(
                  duration: const Duration(milliseconds: 600),
                  offset: 10,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (d.supplierName?.trim().isNotEmpty == true)
                        infoChip(scheme, tt, Iconsax.shop, d.supplierName!),
                      if (d.order.expectedDelivery != null)
                        infoChip(scheme, tt, Iconsax.calendar, 'Expected: ${fmtDate(d.order.expectedDelivery!)}'),
                      if (d.order.actualDelivery != null)
                        infoChip(scheme, tt, Iconsax.tick_circle, 'Delivered: ${fmtDate(d.order.actualDelivery!)}'),
                    ],
                  ),
                ),

                if (d.order.notes?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  FadeInSlide(
                    duration: const Duration(milliseconds: 650),
                    offset: 10,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Iconsax.note, size: 18, color: scheme.onSurface.withOpacity(0.5)),
                          const SizedBox(width: 10),
                          Expanded(child: Text(d.order.notes!, style: tt.bodySmall)),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Items section
                FadeInSlide(
                  duration: const Duration(milliseconds: 700),
                  offset: 10,
                  child: Row(
                    children: [
                      Icon(Iconsax.box, size: 20, color: scheme.primary),
                      const SizedBox(width: 8),
                      Text('Items (${d.items.length})',
                          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const Spacer(),
                      if (canEdit)
                        FilledButton.tonalIcon(
                          onPressed: fullyReceived
                              ? null
                              : () => context.go('/purchases/${d.order.id}/receive'),
                          icon: const Icon(Iconsax.import, size: 16),
                          label: const Text('Receive', style: TextStyle(fontSize: 13)),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                if (d.items.isEmpty)
                  const FadeInSlide(child: EmptyState(title: 'No items', message: 'This PO has no items.', icon: Iconsax.box))
                else
                  for (int i = 0; i < d.items.length; i++) ...[
                    Padding(
                      padding: EdgeInsets.only(bottom: i < d.items.length - 1 ? 8 : 0),
                      child: StaggeredFadeIn.build(
                        index: i,
                        child: Container(
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: scheme.outline.withOpacity(0.5)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: (d.items[i].remainingQuantity <= 0 ? AppTheme.successColor : AppTheme.infoColor).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      d.items[i].remainingQuantity <= 0 ? Iconsax.tick_circle : Iconsax.clock,
                                      size: 20,
                                      color: d.items[i].remainingQuantity <= 0 ? AppTheme.successColor : AppTheme.infoColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        d.items[i].productName ?? d.items[i].productSku ?? d.items[i].productId,
                                        style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Qty: ${d.items[i].quantity} • Recv: ${d.items[i].receivedQuantity} • Rem: ${d.items[i].remainingQuantity}',
                                        style: tt.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.5)),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 70,
                                  child: LinearProgressIndicator(
                                    value: d.items[i].quantity > 0
                                        ? (d.items[i].receivedQuantity / d.items[i].quantity).clamp(0.0, 1.0)
                                        : 0,
                                    borderRadius: BorderRadius.circular(4),
                                    minHeight: 6,
                                    color: d.items[i].remainingQuantity <= 0 ? AppTheme.successColor : AppTheme.infoColor,
                                    backgroundColor: scheme.surfaceContainerHighest,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                const SizedBox(height: 20),

                // Received history section
                FadeInSlide(
                  duration: const Duration(milliseconds: 800),
                  offset: 10,
                  child: Row(
                    children: [
                      Icon(Iconsax.import_1, size: 20, color: scheme.primary),
                      const SizedBox(width: 8),
                      Text('Received History',
                          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.go('/inventory/movements'),
                        child: const Text('View all'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                receivedAsync.when(
                  loading: () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Loading received history…'),
                        ],
                      ),
                    ),
                  ),
                  error: (e, _) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.error_outline),
                      title: const Text('Failed to load received history'),
                      subtitle: Text(e.toString()),
                      trailing: IconButton(
                        tooltip: 'Retry',
                        onPressed: () => ref.invalidate(
                          purchaseReceivedMovementsProvider(purchaseOrderId),
                        ),
                        icon: const Icon(Icons.refresh),
                      ),
                    ),
                  ),
                  data: (rows) {
                    if (rows.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: EmptyState(
                            title: 'No receipts yet',
                            message:
                                'Nothing has been received for this purchase order.',
                            icon: Icons.inventory_2_outlined,
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        for (final m in rows)
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.move_to_inbox_outlined),
                              title: Text(
                                m.productName?.isNotEmpty == true
                                    ? m.productName!
                                    : m.productSku?.isNotEmpty == true
                                        ? m.productSku!
                                        : m.productId,
                              ),
                              subtitle: Text(
                                [
                                  if (m.warehouseName?.isNotEmpty == true)
                                    m.warehouseName!,
                                  fmtDateTime(m.createdAt),
                                  if (m.batchNumber?.isNotEmpty == true)
                                    'Batch: ${m.batchNumber}',
                                  if (m.notes?.isNotEmpty == true)
                                    'Notes: ${m.notes}',
                                ].join(' • '),
                              ),
                              trailing: Text(
                                '+${m.quantityChange}',
                                style: tt.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../data/repositories/company_repository.dart';
import '../../../theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/permission_provider.dart';
import '../providers/sales_detail_provider.dart';
import '../../../../services/invoice_pdf.dart';

class SalesDetailScreen extends ConsumerWidget {
  final String salesOrderId;

  const SalesDetailScreen({super.key, required this.salesOrderId});

  Widget _statusBadge(String status, String paymentStatus) {
    final isPaid = paymentStatus == 'PAID';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isPaid ? AppTheme.successColor : AppTheme.warningColor).withOpacity(0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: (isPaid ? AppTheme.successColor : AppTheme.warningColor).withOpacity(0.3)),
      ),
      child: Text(
        paymentStatus,
        style: TextStyle(
          color: isPaid ? AppTheme.successColor : AppTheme.warningColor,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _infoChip(ColorScheme scheme, TextTheme tt, IconData icon, String text) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canView = ref.watch(canViewSalesProvider);
    if (!canView) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sale')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have access to Sales.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final detailAsync = ref.watch(salesOrderDetailProvider(salesOrderId));
    final auth = ref.watch(authProvider);
    final detail = detailAsync.asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale'),
        actions: [
          if (detail != null)
            IconButton(
              tooltip: 'Print invoice',
              icon: const Icon(Icons.print_outlined),
              onPressed: () async {
                try {
                  final company = await ref
                      .read(companyRepositoryProvider)
                      .getCompanyById(companyId: auth.companyId);
                  final bytes = await InvoicePdf.buildSaleInvoice(
                    detail: detail,
                    company: company,
                  );
                  await Printing.layoutPdf(
                    onLayout: (_) async => bytes,
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
            ),
          if (detail != null)
            IconButton(
              tooltip: 'Share invoice PDF',
              icon: const Icon(Icons.share_outlined),
              onPressed: () async {
                try {
                  final company = await ref
                      .read(companyRepositoryProvider)
                      .getCompanyById(companyId: auth.companyId);
                  final bytes = await InvoicePdf.buildSaleInvoice(
                    detail: detail,
                    company: company,
                  );
                  final filename = detail.order.invoiceNumber.isNotEmpty
                      ? 'invoice_${detail.order.invoiceNumber}.pdf'
                      : 'invoice_$salesOrderId.pdf';
                  await Printing.sharePdf(bytes: bytes, filename: filename);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
            ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () =>
                ref.invalidate(salesOrderDetailProvider(salesOrderId)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const AppBody(child: LoadingIndicator()),
        error: (e, _) => AppBody(
          child: ErrorState(
            title: 'Failed to load sale',
            message: e.toString(),
            onRetry: () =>
                ref.invalidate(salesOrderDetailProvider(salesOrderId)),
          ),
        ),
        data: (d) {
          final scheme = Theme.of(context).colorScheme;
          final tt = Theme.of(context).textTheme;
          final isPaid = d.order.paymentStatus == 'PAID';
          final date =
              '${d.order.saleDate.year.toString().padLeft(4, '0')}-${d.order.saleDate.month.toString().padLeft(2, '0')}-${d.order.saleDate.day.toString().padLeft(2, '0')}';

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
                        colors: isPaid
                            ? [AppTheme.successColor, const Color(0xFF2E7D32)]
                            : [scheme.primary, const Color(0xFF2E5A8F)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isPaid ? AppTheme.successColor : scheme.primary).withOpacity(0.25),
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
                              child: const Icon(Iconsax.receipt_2, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.order.invoiceNumber.isEmpty ? salesOrderId : d.order.invoiceNumber,
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
                            _statusBadge(d.order.status, d.order.paymentStatus),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Info chips row
                FadeInSlide(
                  duration: const Duration(milliseconds: 600),
                  offset: 10,
                  child: Row(
                    children: [
                      _infoChip(scheme, tt, Iconsax.profile_2user, d.order.customerName?.trim().isNotEmpty == true ? d.order.customerName! : 'Walk-in'),
                      const SizedBox(width: 8),
                      _infoChip(scheme, tt, Iconsax.status, d.order.status),
                      if (d.order.paymentMethod?.isNotEmpty == true) ...[
                        const SizedBox(width: 8),
                        _infoChip(scheme, tt, Iconsax.card, d.order.paymentMethod!),
                      ],
                    ],
                  ),
                ),
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
                      FilledButton.tonalIcon(
                        onPressed: auth.companyId == null
                            ? null
                            : () => context.go('/sales/$salesOrderId/return'),
                        icon: const Icon(Iconsax.undo, size: 16),
                        label: const Text('Return', style: TextStyle(fontSize: 13)),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                if (d.items.isEmpty)
                  const FadeInSlide(child: EmptyState(title: 'No items', message: 'This sale has no items.', icon: Iconsax.box))
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
                                    color: scheme.primaryContainer.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Icon(Iconsax.box_1, size: 20, color: scheme.primary),
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
                                        'Qty: ${d.items[i].quantity} • ${d.items[i].warehouseName ?? d.items[i].warehouseId ?? '-'}',
                                        style: tt.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.5)),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'Tk ${d.items[i].unitPrice.toStringAsFixed(0)}',
                                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

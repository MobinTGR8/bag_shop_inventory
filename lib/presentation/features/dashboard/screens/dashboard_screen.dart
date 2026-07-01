import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:iconsax/iconsax.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/constants/user_roles.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/permission_provider.dart';
import '../../../../services/sync_service.dart';
import '../../../../services/pdf_export_service.dart';
import '../../../../services/report_pdf.dart';
import '../providers/dashboard_stats_provider.dart';
import '../../sales/providers/sales_provider.dart';
import '../../inventory/providers/low_stock_provider.dart';
import '../../../theme/app_theme.dart';
import '../providers/company_provider.dart';
import '../../reports/widgets/report_charts.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _formatBdt(double value) {
    final f = NumberFormat.currency(
      locale: 'en_US',
      symbol: 'Tk ',
      decimalDigits: 0,
    );
    return f.format(value);
  }

  Future<void> _downloadDashboardPdf() async {
    try {
      final stats = await ref.read(dashboardStatsProvider.future);
      final recentSales = await ref.read(recentSalesProvider.future);
      final lowStock = await ref.read(lowStockProvider.future);

      await PdfExportService.present(
        filename: 'dashboard_summary.pdf',
        build: () => ReportPdf.buildDashboardSummary(
          stats: stats,
          recentSales: recentSales,
          lowStock: lowStock,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF export failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPos = ref.watch(canAccessPosProvider);
    final canReports = ref.watch(canAccessReportsProvider);
    final canSales = ref.watch(canViewSalesProvider);
    final canPurchases = ref.watch(canViewPurchasesProvider);
    final canEditProducts = ref.watch(canEditProductsProvider);
    final canViewCustomers = ref.watch(canViewCustomersProvider);
    final dashboardStatsAsync = ref.watch(dashboardStatsProvider);
    final dashboardStats = dashboardStatsAsync.asData?.value;
    final recentSalesAsync = ref.watch(recentSalesProvider);
    final lowStockAsync = ref.watch(lowStockProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brand = Theme.of(context).extension<AppBrandColors>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final role = ref.watch(authProvider).role;
              if (role == null || !role.isAdmin) return const SizedBox.shrink();
              return IconButton(
                onPressed: () => context.go('/admin'),
                icon: const Icon(Icons.admin_panel_settings_outlined),
                tooltip: 'Admin Panel',
              );
            },
          ),
          IconButton(
            onPressed: () => context.go('/notifications'),
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
          ),
          IconButton(
            onPressed: () => context.go('/debug/backend-health'),
            icon: const Icon(Icons.health_and_safety_outlined),
            tooltip: 'Backend Health',
          ),
          IconButton(
            onPressed: () => context.go('/debug/sync-queue'),
            icon: const Icon(Icons.cloud_queue_outlined),
            tooltip: 'Sync Queue',
          ),
          Consumer(
            builder: (context, ref, _) {
              final pendingAsync = ref.watch(pendingOutboxCountProvider);
              return pendingAsync.when(
                loading: () => IconButton(
                  onPressed: () async {
                    final res =
                        await ref.read(syncServiceProvider).syncOutbox();
                    ref.invalidate(pendingOutboxCountProvider);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Sync done. Sent: ${res.processed}, remaining: ${res.remaining}'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.sync),
                  tooltip: 'Sync',
                ),
                error: (_, __) => IconButton(
                  onPressed: () async {
                    final res =
                        await ref.read(syncServiceProvider).syncOutbox();
                    ref.invalidate(pendingOutboxCountProvider);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Sync done. Sent: ${res.processed}, remaining: ${res.remaining}'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.sync),
                  tooltip: 'Sync',
                ),
                data: (count) {
                  return IconButton(
                    onPressed: () async {
                      final res =
                          await ref.read(syncServiceProvider).syncOutbox();
                      ref.invalidate(pendingOutboxCountProvider);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Sync done. Sent: ${res.processed}, remaining: ${res.remaining}'),
                        ),
                      );
                    },
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.sync),
                        if (count > 0)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                count > 99 ? '99+' : count.toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.onError,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    tooltip: count == 0 ? 'Sync' : 'Sync ($count queued)',
                  );
                },
              );
            },
          ),
          IconButton(
            onPressed: () => context.go('/debug/supabase'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Supabase Test',
          ),
          IconButton(
            onPressed: dashboardStats == null ? null : _downloadDashboardPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Download PDF',
          ),
          IconButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: AppBody(
        scroll: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Welcome Hero Header ───
            FadeInSlide(
              duration: const Duration(milliseconds: 600),
              offset: 15,
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: brand?.heroGradient ??
                      LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [scheme.primary, scheme.secondary],
                      ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        scheme.brightness == Brightness.dark ? 0.35 : 0.15,
                      ),
                      blurRadius: 30,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Welcome back 👋',
                            style: textTheme.headlineSmall?.copyWith(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(8),
                    Text(
                      'Track stock, process sales, and keep your shop running smoothly.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimary.withOpacity(0.86),
                        height: 1.5,
                      ),
                    ),
                    const Gap(16),
                    Consumer(
                      builder: (context, ref, _) {
                        final companyAsync = ref.watch(companyProvider);
                        return companyAsync.when(
                          loading: () => _buildCompanyChip(
                            context, scheme, '🏪', 'Loading company…', ''
                          ),
                          error: (_, __) => _buildCompanyChip(
                            context, scheme, '🏪', 'Your Shop', 'Store'
                          ),
                          data: (company) {
                            final title = (company?.shopName.trim().isNotEmpty ?? false)
                                ? company!.shopName.trim()
                                : (company?.name.trim().isNotEmpty ?? false)
                                    ? company!.name.trim()
                                    : 'Your Shop';
                            final subtitle =
                                (company?.name.trim().isNotEmpty ?? false) &&
                                        (company?.shopName.trim().isNotEmpty ?? false) &&
                                        company!.name.trim() != company.shopName.trim()
                                    ? company.name.trim()
                                    : '';
                            return _buildCompanyChip(context, scheme, '🏪', title, subtitle);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Gap(24),

            // ─── Weekly Sales Trend ───
            FadeInSlide(
              duration: const Duration(milliseconds: 700),
              offset: 15,
              child: dashboardStats != null
                  ? ChartCard(
                      title: 'Weekly sales trend',
                      subtitle: 'Live sales totals over the last 7 days',
                      child: SimpleLineChart(
                        points: [
                          for (final point in dashboardStats.weeklySales)
                            ChartPoint(
                              label: DateFormat('E').format(point.date),
                              value: point.total,
                            ),
                        ],
                      ),
                    )
                  : const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: SizedBox(
                          height: 220,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                    ),
            ),
            const Gap(24),

            // ─── Quick Stats ───
            const AppSectionTitle('Quick Stats'),
            const Gap(16),

            LayoutBuilder(
              builder: (context, constraints) {
                final cols = AppBreakpoints.gridColumns(
                  constraints.maxWidth,
                  compactColumns: 2,
                  mediumColumns: 3,
                  expandedColumns: 4,
                );
                final aspect = cols >= 4 ? 1.6 : (cols == 3 ? 1.35 : 1.2);

                return ref.watch(dashboardStatsProvider).when(
                  loading: () => GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: aspect,
                    ),
                    children: const [
                      _StatCardSkeleton(), _StatCardSkeleton(),
                      _StatCardSkeleton(), _StatCardSkeleton(),
                    ],
                  ),
                  error: (_, __) => GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: aspect,
                    ),
                    children: [
                      _buildStatCard(title: 'Total Products', value: '—', icon: Iconsax.box, color: AppTheme.successColor, trend: 'N/A'),
                      _buildStatCard(title: 'Low Stock', value: '—', icon: Iconsax.warning_2, color: AppTheme.warningColor, trend: 'N/A'),
                      _buildStatCard(title: 'Today Sales', value: '—', icon: Iconsax.receipt_2, color: AppTheme.infoColor, trend: 'N/A'),
                      _buildStatCard(title: 'Monthly Revenue', value: '—', icon: Iconsax.chart_2, color: AppTheme.primaryColor, trend: 'N/A'),
                    ],
                  ),
                  data: (s) => GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: aspect,
                    ),
                    children: [
                      _buildStatCard(title: 'Total Products', value: s.totalProducts.toString(), icon: Iconsax.box, color: AppTheme.successColor, trend: 'Live'),
                      _buildStatCard(title: 'Low Stock', value: s.lowStockCount.toString(), icon: Iconsax.warning_2, color: AppTheme.warningColor, trend: s.lowStockCount == 0 ? 'All good' : 'Needs attention'),
                      _buildStatCard(title: 'Today Sales', value: _formatBdt(s.todaySales), icon: Iconsax.receipt_2, color: AppTheme.infoColor, trend: 'Today'),
                      _buildStatCard(title: 'Monthly Revenue', value: _formatBdt(s.monthRevenue), icon: Iconsax.chart_2, color: AppTheme.primaryColor, trend: 'This month'),
                    ],
                  ),
                );
              },
            ),

            const Gap(24),

            // ─── Quick Actions ───
            const AppSectionTitle('Quick Actions'),
            const Gap(16),

            LayoutBuilder(
              builder: (context, constraints) {
                final cols = AppBreakpoints.gridColumns(
                  constraints.maxWidth,
                  compactColumns: 3,
                  mediumColumns: 4,
                  expandedColumns: 6,
                );
                final aspect = cols >= 6 ? 1.05 : 0.9;

                return GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: aspect,
                  ),
                  children: [
                    _buildActionButton(icon: MdiIcons.barcodeScan, label: 'Scan', color: AppTheme.primaryColor, onTap: () => context.go('/scanner')),
                    if (canEditProducts)
                      _buildActionButton(icon: Iconsax.add_square, label: 'Add Product', color: AppTheme.successColor, onTap: () => context.go('/products/add'))
                    else
                      _buildActionButton(icon: Iconsax.box, label: 'Products', color: AppTheme.successColor, onTap: () => context.go('/products')),
                    if (canPos) _buildActionButton(icon: Iconsax.shopping_cart, label: 'POS', color: AppTheme.secondaryColor, onTap: () => context.go('/pos')),
                    if (canSales) _buildActionButton(icon: Iconsax.receipt_item, label: 'Sales', color: AppTheme.infoColor, onTap: () => context.go('/sales')),
                    if (canViewCustomers) _buildActionButton(icon: Iconsax.profile_2user, label: 'Customers', color: AppTheme.infoColor, onTap: () => context.go('/customers')),
                    if (canPurchases) _buildActionButton(icon: Iconsax.box_add, label: 'Purchase', color: AppTheme.warningColor, onTap: () => context.go('/purchases/add')),
                    if (canReports) _buildActionButton(icon: Iconsax.chart, label: 'Reports', color: AppTheme.dangerColor, onTap: () => context.go('/reports')),
                    _buildActionButton(icon: Iconsax.chart_2, label: 'Analytics', color: AppTheme.infoColor, onTap: () => context.go('/inventory/analytics')),
                  ],
                );
              },
            ),

            const Gap(24),

            // ─── Recent Sales ───
            FadeInSlide(
              duration: const Duration(milliseconds: 800),
              offset: 15,
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outline.withOpacity(0.6)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSectionTitle(
                        'Recent Sales',
                        trailing: TextButton(
                          onPressed: () => context.go('/sales'),
                          child: const Text('View All →'),
                        ),
                      ),
                      const Gap(12),
                      recentSalesAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, _) => Text(
                          'Unable to load recent sales: $e',
                          style: textTheme.bodyMedium?.copyWith(color: scheme.error),
                        ),
                        data: (sales) {
                          if (sales.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  Icon(Icons.receipt_long_outlined, size: 20, color: scheme.onSurface.withOpacity(0.3)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'No sales yet. Create your first sale from POS.',
                                    style: textTheme.bodyMedium?.copyWith(color: scheme.onSurface.withOpacity(0.5)),
                                  ),
                                ],
                              ),
                            );
                          }
                          return Column(
                            children: [
                              for (final sale in sales.take(3))
                                _buildSaleItem(
                                  invoice: sale.invoiceNumber.isEmpty ? (sale.id ?? 'Sale') : sale.invoiceNumber,
                                  customer: sale.customerName?.trim().isNotEmpty == true ? sale.customerName! : (sale.customerId ?? 'Walk-in'),
                                  amount: _formatBdt(sale.totalAmount),
                                  paymentStatus: sale.paymentStatus,
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Gap(24),

            // ─── Low Stock Alerts ───
            FadeInSlide(
              duration: const Duration(milliseconds: 900),
              offset: 15,
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: lowStockAsync.when(
                      data: (items) => items.isNotEmpty ? scheme.error.withOpacity(0.3) : scheme.outline.withOpacity(0.6),
                      error: (_, __) => scheme.outline.withOpacity(0.6),
                      loading: () => scheme.outline.withOpacity(0.6),
                    ),
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Low Stock Alerts', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                          ),
                          lowStockAsync.when(
                            loading: () => const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                            error: (e, _) => Text(e.toString(), style: textTheme.bodySmall?.copyWith(color: scheme.error)),
                            data: (items) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: (items.isNotEmpty ? scheme.error : scheme.primary).withOpacity(0.10),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: (items.isNotEmpty ? scheme.error : scheme.primary).withOpacity(0.2)),
                              ),
                              child: Text(
                                '${items.length} items',
                                style: textTheme.labelLarge?.copyWith(
                                  color: items.isNotEmpty ? scheme.error : scheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(12),
                      lowStockAsync.when(
                        loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Center(child: CircularProgressIndicator())),
                        error: (e, _) => Text('Unable to load: $e', style: textTheme.bodyMedium?.copyWith(color: scheme.error)),
                        data: (items) {
                          if (items.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline, size: 20, color: AppTheme.successColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    'All inventory is above minimum stock.',
                                    style: textTheme.bodyMedium?.copyWith(color: AppTheme.successColor, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            );
                          }
                          return Column(
                            children: [
                              for (final item in items.take(3))
                                _buildLowStockItem(
                                  product: item.name,
                                  sku: item.sku,
                                  stock: item.currentStock,
                                  minStock: item.minStock,
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Gap(32),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Iconsax.home),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Iconsax.box),
            label: 'Products',
          ),
          if (canPos)
            const BottomNavigationBarItem(
              icon: Icon(Iconsax.shopping_cart),
              label: 'POS',
            ),
          if (canSales)
            const BottomNavigationBarItem(
              icon: Icon(Iconsax.receipt_item),
              label: 'Sales',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Iconsax.user),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          final routes = <String?>[
            '/',
            '/products',
            if (canPos) '/pos',
            if (canSales) '/sales',
            '/profile',
          ];

          final route = routes[index];
          if (route != null) {
            context.go(route);
          }
        },
      ),
      floatingActionButton: canPos
          ? FloatingActionButton(
              onPressed: () => context.go('/pos'),
              backgroundColor: scheme.primary,
              child: Icon(Iconsax.add, color: scheme.onPrimary),
            )
          : null,
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? trend,
  }) {
    return Builder(
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final tt = Theme.of(context).textTheme;

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (trend?.hashCode ?? 0) % 200),
          curve: Curves.easeOutBack,
          tween: Tween(begin: 0.95, end: 1.0),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {}, // subtle feedback
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(
                              scheme.brightness == Brightness.dark ? 0.16 : 0.12,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: color.withOpacity(
                                scheme.brightness == Brightness.dark ? 0.22 : 0.18,
                              ),
                            ),
                          ),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        if (trend != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withOpacity(scheme.brightness == Brightness.dark ? 0.16 : 0.10),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: color.withOpacity(scheme.brightness == Brightness.dark ? 0.22 : 0.14)),
                            ),
                            child: Text(
                              trend,
                              style: tt.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700, letterSpacing: -0.2),
                            ),
                          ),
                      ],
                    ),
                    const Gap(12),
                    Text(
                      value,
                      style: tt.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      title,
                      style: tt.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final tt = Theme.of(context).textTheme;

        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(
                        scheme.brightness == Brightness.dark ? 0.18 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: color.withOpacity(
                          scheme.brightness == Brightness.dark ? 0.22 : 0.14,
                        ),
                      ),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const Gap(10),
                  Text(
                    label,
                    style: tt.labelLarge?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompanyChip(BuildContext context, ColorScheme scheme, String emoji, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.onPrimary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.onPrimary.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onPrimary.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleItem({
    required String invoice,
    required String customer,
    required String amount,
    required String paymentStatus,
  }) {
    return Builder(
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final tt = Theme.of(context).textTheme;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(
                      scheme.brightness == Brightness.dark ? 0.18 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: scheme.primary.withOpacity(
                        scheme.brightness == Brightness.dark ? 0.22 : 0.12,
                      ),
                    ),
                  ),
                  child: Icon(
                    Iconsax.receipt_2,
                    color: scheme.primary,
                    size: 20,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        customer,
                        style: tt.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (paymentStatus == 'PAID' ? AppTheme.successColor : AppTheme.warningColor).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          paymentStatus,
                          style: tt.bodySmall?.copyWith(
                            color: paymentStatus == 'PAID' ? AppTheme.successColor : AppTheme.warningColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amount,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLowStockItem({
    required String product,
    required String sku,
    required int stock,
    required int minStock,
  }) {
    return Builder(
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final tt = Theme.of(context).textTheme;

        final isCritical = stock < 3;
        final accent = isCritical ? scheme.error : scheme.tertiary;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: accent.withOpacity(
              scheme.brightness == Brightness.dark ? 0.12 : 0.08,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accent.withOpacity(
                scheme.brightness == Brightness.dark ? 0.22 : 0.18,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withOpacity(
                    scheme.brightness == Brightness.dark ? 0.16 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accent.withOpacity(
                      scheme.brightness == Brightness.dark ? 0.22 : 0.14,
                    ),
                  ),
                ),
                child: Icon(
                  Iconsax.warning_2,
                  color: accent,
                  size: 20,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      sku,
                      style: tt.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$stock left',
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                      color: accent,
                    ),
                  ),
                  Text(
                    'Min: $minStock',
                    style: tt.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Gap(8),
              IconButton(
                onPressed: () => context.go('/purchases/add'),
                icon: Icon(Iconsax.add, size: 20, color: scheme.primary),
                style: IconButton.styleFrom(
                  backgroundColor: scheme.primary.withOpacity(
                    scheme.brightness == Brightness.dark ? 0.18 : 0.10,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCardSkeleton extends StatelessWidget {
  const _StatCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                Container(
                  height: 22,
                  width: 70,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
            const Gap(12),
            Container(
              height: 28,
              width: 120,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Container(
              height: 16,
              width: 100,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

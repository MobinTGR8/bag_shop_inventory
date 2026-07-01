import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../theme/app_theme.dart';
import '../../auth/providers/permission_provider.dart';

class ReportsHomeScreen extends ConsumerWidget {
  const ReportsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canReports = ref.watch(canAccessReportsProvider);
    if (!canReports) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reports')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have access to Reports.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final tt = Theme.of(context).textTheme;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: AppBody(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            FadeInSlide(
              child: Text('Analytics & Insights', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final columns = width >= 1100 ? 3 : (width >= 700 ? 2 : 1);

                final items = [
                  _ReportTileData(title: 'Sales report', subtitle: 'Revenue and top products', icon: Icons.receipt_long, color: AppTheme.successColor, onTap: () => context.go('/reports/sales')),
                  _ReportTileData(title: 'Stock report', subtitle: 'Low stock items', icon: Icons.inventory_2_outlined, color: AppTheme.primaryColor, onTap: () => context.go('/reports/stock')),
                  _ReportTileData(title: 'Profit report', subtitle: 'Revenue minus COGS', icon: Icons.trending_up_outlined, color: AppTheme.secondaryColor, onTap: () => context.go('/reports/profit')),
                  _ReportTileData(title: 'Inventory valuation', subtitle: 'Stock value at cost', icon: Icons.account_balance_wallet_outlined, color: AppTheme.infoColor, onTap: () => context.go('/reports/valuation')),
                  _ReportTileData(title: 'Supplier performance', subtitle: 'Orders received by supplier', icon: Icons.local_shipping_outlined, color: AppTheme.warningColor, onTap: () => context.go('/reports/suppliers')),
                ];

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: columns == 1 ? 2.5 : 1.5,
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return FadeInSlide(
                      duration: Duration(milliseconds: 400 + index * 100),
                      offset: 15,
                      child: _tile(context, item),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, _ReportTileData data) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
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
          onTap: data.onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: data.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(data.icon, color: data.color, size: 22),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, color: scheme.onSurface.withOpacity(0.3), size: 20),
                  ],
                ),
                const SizedBox(height: 16),
                Text(data.title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(data.subtitle, style: tt.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.6))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportTileData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ReportTileData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gap/gap.dart';

import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../data/models/inventory/inventory_model.dart';
import '../../../theme/app_theme.dart';
import '../../reports/providers/report_provider.dart';
import '../../auth/providers/permission_provider.dart';
import '../providers/inventory_provider.dart';

/// Advanced inventory analytics screen with KPIs, aging, and distribution charts.
class InventoryAnalyticsScreen extends ConsumerWidget {
  const InventoryAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canView = ref.watch(canViewInventoryProvider);
    if (!canView) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inventory Analytics')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have access to Inventory.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final inventoryAsync = ref.watch(inventoryListProvider);
    final valuationAsync = ref.watch(inventoryValuationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Analytics'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(inventoryListProvider);
              ref.invalidate(inventoryValuationProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: inventoryAsync.when(
        loading: () => _buildLoading(),
        error: (e, _) => AppBody(
          child: ErrorState(
            title: 'Failed to load inventory',
            message: e.toString(),
            onRetry: () => ref.invalidate(inventoryListProvider),
          ),
        ),
        data: (inventory) {
          return AppBody(
            scroll: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Summary KPIs
                _buildKpiRow(context, inventory),
                const Gap(24),

                // Stock Distribution by Condition
                _buildConditionChart(context, inventory),

                const Gap(24),

                // Inventory Aging
                _buildAgingSection(context, inventory),

                const Gap(24),

                // Stock by Warehouse
                _buildWarehouseDistribution(context, inventory),

                const Gap(24),

                // Valuation summary
                valuationAsync.when(
                  loading: () => const ShimmerCard(height: 100),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (valuation) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Inventory Valuation',
                            style: tt.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const Gap(8),
                          Text(
                            'Total Stock Value',
                            style: tt.bodyMedium?.copyWith(
                              color: scheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          Text(
                            'Tk ${valuation.totalValue.toStringAsFixed(2)}',
                            style: tt.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: scheme.primary,
                            ),
                          ),
                          const Gap(4),
                          Text(
                            'Based on ${valuation.lines.length} unique products',
                            style: tt.bodySmall?.copyWith(
                              color: scheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Gap(32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return AppBody(
      child: ListView(
        padding: EdgeInsets.zero,
        children: const [
          ShimmerStatCard(),
          SizedBox(height: 12),
          ShimmerChart(),
          SizedBox(height: 12),
          ShimmerCard(height: 200),
          SizedBox(height: 12),
          ShimmerCard(height: 100),
        ],
      ),
    );
  }

  Widget _buildKpiRow(BuildContext context, List<InventoryModel> inventory) {
    final totalQty = inventory.fold<int>(0, (s, i) => s + i.quantity);
    final totalReserved = inventory.fold<int>(0, (s, i) => s + i.reservedQuantity);
    final itemsWithExpiry =
        inventory.where((i) => i.expiryDate != null).length;
    final expiredCount = inventory.where((i) {
      final expiry = i.expiryDate;
      return expiry != null && expiry.isBefore(DateTime.now());
    }).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 700 ? 4 : 2;
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          children: [
            _kpiTile(
              context,
              icon: Icons.inventory_2_outlined,
              label: 'Total Qty',
              value: totalQty.toString(),
              color: AppTheme.primaryColor,
            ),
            _kpiTile(
              context,
              icon: Icons.bookmark_outlined,
              label: 'Reserved',
              value: totalReserved.toString(),
              color: AppTheme.infoColor,
            ),
            _kpiTile(
              context,
              icon: Icons.date_range_outlined,
              label: 'Expiry tracked',
              value: itemsWithExpiry.toString(),
              color: AppTheme.warningColor,
            ),
            _kpiTile(
              context,
              icon: Icons.warning_amber_outlined,
              label: 'Expired',
              value: expiredCount.toString(),
              color: expiredCount > 0 ? AppTheme.dangerColor : AppTheme.successColor,
            ),
          ],
        );
      },
    );
  }

  Widget _kpiTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Text(
              value,
              style: tt.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              label,
              style: tt.bodySmall?.copyWith(
                color: scheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionChart(BuildContext context, List<InventoryModel> inventory) {
    final tt = Theme.of(context).textTheme;

    final conditions = <String, int>{};
    for (final item in inventory) {
      conditions.update(item.condition, (v) => v + item.quantity,
          ifAbsent: () => item.quantity);
    }

    if (conditions.isEmpty) return const SizedBox.shrink();

    final colors = [
      AppTheme.successColor,
      AppTheme.warningColor,
      AppTheme.dangerColor,
      AppTheme.infoColor,
      AppTheme.primaryColor,
    ];

    final total = conditions.values.fold<int>(0, (s, v) => s + v);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stock Condition Distribution',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Gap(16),
            SizedBox(
              height: 160,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: conditions.entries.toList().asMap().entries.map(
                          (entry) {
                            final idx = entry.key;
                            final qty = entry.value.value;
                            final pct = (qty / total) * 100;
                            return PieChartSectionData(
                              value: qty.toDouble(),
                              title: '${pct.toStringAsFixed(0)}%',
                              color: colors[idx % colors.length],
                              radius: 50,
                              titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            );
                          },
                        ).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: conditions.entries.toList().asMap().entries.map(
                      (entry) {
                        final idx = entry.key;
                        final condition = entry.value.key;
                        final qty = entry.value.value;
                        final pct = (qty / total) * 100;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: colors[idx % colors.length],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$condition (${pct.toStringAsFixed(0)}%)',
                                style: tt.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgingSection(BuildContext context, List<InventoryModel> inventory) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final now = DateTime.now();
    final aged = <String, int>{
      '0-30 days': 0,
      '31-60 days': 0,
      '61-90 days': 0,
      '90+ days': 0,
    };

    for (final item in inventory) {
      final days = now.difference(item.lastUpdated).inDays;
      if (days <= 30) {
        aged['0-30 days'] = (aged['0-30 days'] ?? 0) + item.quantity;
      } else if (days <= 60) {
        aged['31-60 days'] = (aged['31-60 days'] ?? 0) + item.quantity;
      } else if (days <= 90) {
        aged['61-90 days'] = (aged['61-90 days'] ?? 0) + item.quantity;
      } else {
        aged['90+ days'] = (aged['90+ days'] ?? 0) + item.quantity;
      }
    }

    final slowMoving = (aged['61-90 days'] ?? 0) + (aged['90+ days'] ?? 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Inventory Aging',
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: slowMoving > 0
                        ? AppTheme.warningColor.withOpacity(0.12)
                        : AppTheme.successColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$slowMoving slow-moving',
                    style: tt.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color:
                          slowMoving > 0 ? AppTheme.warningColor : AppTheme.successColor,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(16),
            ...aged.entries.map((entry) {
              final maxVal = aged.values.fold<int>(0, (s, v) => v > s ? v : s);
              final pct = maxVal > 0 ? entry.value / maxVal : 0.0;
              final isSlow = entry.key == '61-90 days' || entry.key == '90+ days';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          entry.key,
                          style: tt.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSlow
                                ? AppTheme.warningColor
                                : scheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${entry.value} units',
                          style: tt.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isSlow
                                ? AppTheme.warningColor
                                : scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0),
                        backgroundColor:
                            isSlow ? AppTheme.warningColor.withOpacity(0.1) : null,
                        color: isSlow ? AppTheme.warningColor : scheme.primary,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildWarehouseDistribution(
      BuildContext context, List<InventoryModel> inventory) {
    final tt = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final byWarehouse = <String, int>{};
    for (final item in inventory) {
      final name = item.warehouseName ?? item.warehouseId;
      byWarehouse.update(name, (v) => v + item.quantity,
          ifAbsent: () => item.quantity);
    }

    if (byWarehouse.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stock by Warehouse',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Gap(12),
            ...byWarehouse.entries.map((entry) {
              final total = byWarehouse.values.fold<int>(0, (s, v) => s + v);
              final pct = total > 0 ? entry.value / total : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: tt.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          '${entry.value}',
                          style: tt.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0),
                        backgroundColor: scheme.primary.withOpacity(0.1),
                        color: scheme.primary,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

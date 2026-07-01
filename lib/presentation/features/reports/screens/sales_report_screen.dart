import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../services/pdf_export_service.dart';
import '../../../../services/report_pdf.dart';
import '../../auth/providers/permission_provider.dart';
import '../providers/report_provider.dart';
import '../widgets/report_charts.dart';

class SalesReportScreen extends ConsumerWidget {
  const SalesReportScreen({super.key});

  static const _ranges = <int, String>{
    7: 'Last 7 days',
    30: 'Last 30 days',
    90: 'Last 90 days',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canReports = ref.watch(canAccessReportsProvider);
    if (!canReports) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sales Report')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have access to Reports.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final reportAsync = ref.watch(salesReportProvider);
    final selectedDays = ref.watch(salesReportLastDaysProvider);
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Report'),
        actions: [
          IconButton(
            tooltip: 'Download PDF',
            onPressed: reportAsync.asData?.value == null
                ? null
                : () async {
                    try {
                      final report = await ref.read(salesReportProvider.future);
                      await PdfExportService.present(
                        filename: 'sales_report.pdf',
                        build: () => ReportPdf.buildSalesReport(report: report),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('PDF export failed: $e')),
                      );
                    }
                  },
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
          PopupMenuButton<int>(
            initialValue: selectedDays,
            tooltip: 'Select range',
            onSelected: (value) {
              ref.read(salesReportLastDaysProvider.notifier).state = value;
              ref.invalidate(salesReportProvider);
            },
            itemBuilder: (context) => _ranges.entries
                .map(
                  (e) => PopupMenuItem<int>(
                    value: e.key,
                    child: Text(e.value),
                  ),
                )
                .toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Text(
                    _ranges[selectedDays] ?? 'Range',
                    style: tt.labelLarge,
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.expand_more),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => ref.invalidate(salesReportProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: reportAsync.when(
        loading: () => const AppBody(child: LoadingIndicator()),
        error: (e, _) => AppBody(
          child: ErrorState(
            title: 'Failed to load sales report',
            message: e.toString(),
            onRetry: () => ref.invalidate(salesReportProvider),
          ),
        ),
        data: (r) {
          final from =
              '${r.from.year}-${r.from.month.toString().padLeft(2, '0')}-${r.from.day.toString().padLeft(2, '0')}';
          final to =
              '${r.to.year}-${r.to.month.toString().padLeft(2, '0')}-${r.to.day.toString().padLeft(2, '0')}';

          return AppBody(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ChartCard(
                  title: 'Sales trend',
                  subtitle: 'Daily revenue across the selected range',
                  child: SimpleLineChart(
                    points: [
                      for (final day in r.dailyTotals)
                        ChartPoint(
                          label: '${day.date.month}/${day.date.day}',
                          value: day.total,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Range: $from → $to', style: tt.titleMedium),
                        const SizedBox(height: 12),
                        Text(
                          'Orders: ${r.ordersCount}',
                          style: tt.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Revenue: ${r.revenue.toStringAsFixed(2)}',
                          style: tt.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const AppSectionTitle('Daily totals'),
                const SizedBox(height: 8),
                if (r.dailyTotals.isEmpty)
                  const EmptyState(
                    title: 'No sales in this range',
                    message: 'Try selecting a longer date range.',
                    icon: Icons.insights_outlined,
                  ),
                for (final d in r.dailyTotals)
                  ListTile(
                    dense: true,
                    title: Text(
                      '${d.date.year}-${d.date.month.toString().padLeft(2, '0')}-${d.date.day.toString().padLeft(2, '0')}',
                    ),
                    trailing: Text(d.total.toStringAsFixed(2)),
                  ),
                const SizedBox(height: 16),
                ChartCard(
                  title: 'Top products',
                  subtitle: 'Highest revenue items in this range',
                  child: SimpleBarChart(
                    points: [
                      for (final product in r.topProducts.take(8))
                        ChartPoint(
                          label: _shortLabel(product.name),
                          value: product.revenue,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const AppSectionTitle('Top products'),
                const SizedBox(height: 8),
                if (r.topProducts.isEmpty)
                  const EmptyState(
                    title: 'No item-level data',
                    message: 'No per-product breakdown was returned.',
                    icon: Icons.inventory_2_outlined,
                  ),
                for (final p in r.topProducts)
                  ListTile(
                    title: Text(p.name),
                    subtitle:
                        (p.sku == null || p.sku!.isEmpty) ? null : Text(p.sku!),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Qty: ${p.quantity}'),
                        Text(
                          p.revenue.toStringAsFixed(2),
                          style: tt.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _shortLabel(String value) {
    final trimmed = value.trim();
    if (trimmed.length <= 10) return trimmed;
    return '${trimmed.substring(0, 9)}…';
  }
}

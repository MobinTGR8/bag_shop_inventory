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

class SupplierPerformanceScreen extends ConsumerWidget {
  const SupplierPerformanceScreen({super.key});

  static const _ranges = <int, String>{
    30: 'Last 30 days',
    90: 'Last 90 days',
    180: 'Last 180 days'
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canReports = ref.watch(canAccessReportsProvider);
    if (!canReports) {
      return Scaffold(
        appBar: AppBar(title: const Text('Supplier Performance')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have access to Reports.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final reportAsync = ref.watch(supplierPerformanceProvider);
    final selectedDays = ref.watch(supplierPerformanceLastDaysProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Performance'),
        actions: [
          IconButton(
            tooltip: 'Download PDF',
            onPressed: reportAsync.asData?.value == null
                ? null
                : () async {
                    try {
                      final report =
                          await ref.read(supplierPerformanceProvider.future);
                      await PdfExportService.present(
                        filename: 'supplier_performance.pdf',
                        build: () => ReportPdf.buildSupplierPerformance(
                          report: report,
                        ),
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
            onSelected: (value) {
              ref.read(supplierPerformanceLastDaysProvider.notifier).state =
                  value;
              ref.invalidate(supplierPerformanceProvider);
            },
            itemBuilder: (context) => _ranges.entries
                .map((e) =>
                    PopupMenuItem<int>(value: e.key, child: Text(e.value)))
                .toList(),
          ),
          IconButton(
            onPressed: () => ref.invalidate(supplierPerformanceProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: reportAsync.when(
        loading: () => const AppBody(child: LoadingIndicator()),
        error: (e, _) => AppBody(
          child: ErrorState(
            title: 'Failed to load supplier performance',
            message: e.toString(),
            onRetry: () => ref.invalidate(supplierPerformanceProvider),
          ),
        ),
        data: (r) {
          return AppBody(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ChartCard(
                  title: 'Supplier ordering',
                  subtitle: 'Ordered versus received amount',
                  child: DualBarChart(
                    points: [
                      for (final line in r.lines.take(8))
                        DualBarChartPoint(
                          label: _shortLabel(line.name),
                          primary: line.totalOrdered,
                          secondary: line.receivedAmount,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    title: const Text('Summary'),
                    subtitle: Text('${r.lines.length} supplier(s) in range'),
                  ),
                ),
                const SizedBox(height: 12),
                for (final line in r.lines)
                  Card(
                    child: ListTile(
                      title: Text(line.name),
                      subtitle: Text(
                          'Orders: ${line.purchaseCount} • Received: ${line.receivedCount}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(line.totalOrdered.toStringAsFixed(2)),
                          Text(
                              'Recv ${line.receivedAmount.toStringAsFixed(2)}'),
                        ],
                      ),
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

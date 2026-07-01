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

class StockReportScreen extends ConsumerWidget {
  const StockReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canReports = ref.watch(canAccessReportsProvider);
    if (!canReports) {
      return Scaffold(
        appBar: AppBar(title: const Text('Stock Report')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have access to Reports.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final reportAsync = ref.watch(stockReportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Report'),
        actions: [
          IconButton(
            tooltip: 'Download PDF',
            onPressed: reportAsync.asData?.value == null
                ? null
                : () async {
                    try {
                      final lines = await ref.read(stockReportProvider.future);
                      await PdfExportService.present(
                        filename: 'stock_report.pdf',
                        build: () => ReportPdf.buildStockReport(lines: lines),
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
          IconButton(
            onPressed: () => ref.invalidate(stockReportProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: reportAsync.when(
        loading: () => const AppBody(child: LoadingIndicator()),
        error: (e, _) => AppBody(
          child: ErrorState(
            title: 'Failed to load stock report',
            message: e.toString(),
            onRetry: () => ref.invalidate(stockReportProvider),
          ),
        ),
        data: (lines) {
          if (lines.isEmpty) {
            return const AppBody(
              child: EmptyState(
                title: 'No stock data',
                message: 'No stock report lines were returned.',
                icon: Icons.inventory_2_outlined,
              ),
            );
          }

          final scheme = Theme.of(context).colorScheme;
          final tt = Theme.of(context).textTheme;

          return AppBody(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: lines.length + 2,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ChartCard(
                    title: 'Stock health',
                    subtitle: 'Current stock for low-stock items',
                    child: SimpleBarChart(
                      points: [
                        for (final line in lines.take(10))
                          ChartPoint(
                            label: _shortLabel(line.name),
                            value: line.currentStock.toDouble(),
                          ),
                      ],
                      barColor: scheme.error,
                    ),
                  );
                }
                if (index == 1) {
                  return const SizedBox(height: 8);
                }

                final l = lines[index - 2];
                final statusColor = l.isLowStock
                    ? scheme.error
                    : scheme.primary.withOpacity(0.9);
                final statusText = l.isLowStock ? 'LOW' : 'OK';

                return Card(
                  child: ListTile(
                    title: Text(l.name),
                    subtitle: Text('${l.sku} • Min: ${l.minStock}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Stock: ${l.currentStock}',
                          style: tt.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusText,
                          style: tt.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
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

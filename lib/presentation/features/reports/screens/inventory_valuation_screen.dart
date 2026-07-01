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

class InventoryValuationScreen extends ConsumerWidget {
  const InventoryValuationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canReports = ref.watch(canAccessReportsProvider);
    if (!canReports) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inventory Valuation')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have access to Reports.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final reportAsync = ref.watch(inventoryValuationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Valuation'),
        actions: [
          IconButton(
            tooltip: 'Download PDF',
            onPressed: reportAsync.asData?.value == null
                ? null
                : () async {
                    try {
                      final report =
                          await ref.read(inventoryValuationProvider.future);
                      await PdfExportService.present(
                        filename: 'inventory_valuation.pdf',
                        build: () => ReportPdf.buildInventoryValuation(
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
          IconButton(
            onPressed: () => ref.invalidate(inventoryValuationProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: reportAsync.when(
        loading: () => const AppBody(child: LoadingIndicator()),
        error: (e, _) => AppBody(
          child: ErrorState(
            title: 'Failed to load valuation',
            message: e.toString(),
            onRetry: () => ref.invalidate(inventoryValuationProvider),
          ),
        ),
        data: (r) {
          return AppBody(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ChartCard(
                  title: 'Valuation by product',
                  subtitle: 'Highest value inventory items at cost',
                  child: SimpleBarChart(
                    points: [
                      for (final line in r.lines.take(8))
                        ChartPoint(
                          label: _shortLabel(line.name),
                          value: line.value,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    title: const Text('Total stock value'),
                    trailing: Text(r.totalValue.toStringAsFixed(2)),
                  ),
                ),
                const SizedBox(height: 12),
                for (final line in r.lines.take(25))
                  Card(
                    child: ListTile(
                      title: Text(line.name),
                      subtitle: Text(
                          '${line.sku} • Qty: ${line.quantity} • Cost: ${line.unitCost.toStringAsFixed(2)}'),
                      trailing: Text(line.value.toStringAsFixed(2)),
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

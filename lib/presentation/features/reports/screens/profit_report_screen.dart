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

class ProfitReportScreen extends ConsumerWidget {
  const ProfitReportScreen({super.key});

  static const _ranges = <int, String>{
    7: 'Last 7 days',
    30: 'Last 30 days',
    90: 'Last 90 days'
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canReports = ref.watch(canAccessReportsProvider);
    if (!canReports) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profit Report')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have access to Reports.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final reportAsync = ref.watch(profitReportProvider);
    final selectedDays = ref.watch(profitReportLastDaysProvider);
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profit Report'),
        actions: [
          IconButton(
            tooltip: 'Download PDF',
            onPressed: reportAsync.asData?.value == null
                ? null
                : () async {
                    try {
                      final report =
                          await ref.read(profitReportProvider.future);
                      await PdfExportService.present(
                        filename: 'profit_report.pdf',
                        build: () =>
                            ReportPdf.buildProfitReport(report: report),
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
              ref.read(profitReportLastDaysProvider.notifier).state = value;
              ref.invalidate(profitReportProvider);
            },
            itemBuilder: (context) => _ranges.entries
                .map((e) =>
                    PopupMenuItem<int>(value: e.key, child: Text(e.value)))
                .toList(),
          ),
          IconButton(
            onPressed: () => ref.invalidate(profitReportProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: reportAsync.when(
        loading: () => const AppBody(child: LoadingIndicator()),
        error: (e, _) => AppBody(
          child: ErrorState(
            title: 'Failed to load profit report',
            message: e.toString(),
            onRetry: () => ref.invalidate(profitReportProvider),
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
                  title: 'Profit breakdown',
                  subtitle: 'Revenue, cost of goods sold and gross profit',
                  child: SimpleBarChart(
                    points: [
                      ChartPoint(label: 'Revenue', value: r.revenue),
                      ChartPoint(label: 'COGS', value: r.cogs),
                      ChartPoint(label: 'Profit', value: r.grossProfit),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    title: Text('Range: $from → $to'),
                    subtitle: const Text('Revenue, COGS and gross profit'),
                  ),
                ),
                const SizedBox(height: 12),
                _metric(context, 'Revenue', r.revenue, tt),
                _metric(context, 'COGS', r.cogs, tt),
                _metric(context, 'Gross profit', r.grossProfit, tt),
                _metric(context, 'Margin', r.marginPercent, tt, suffix: '%'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _metric(BuildContext context, String label, double value, TextTheme tt,
      {String suffix = ''}) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(
          suffix == '%'
              ? '${value.toStringAsFixed(1)}$suffix'
              : value.toStringAsFixed(2),
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

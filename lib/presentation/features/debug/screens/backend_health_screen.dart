import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../services/backend_health_service.dart';

class BackendHealthScreen extends ConsumerWidget {
  const BackendHealthScreen({super.key});

  IconData _iconFor(BackendCheckStatus status) {
    switch (status) {
      case BackendCheckStatus.ok:
        return Icons.check_circle_outline;
      case BackendCheckStatus.warning:
        return Icons.info_outline;
      case BackendCheckStatus.error:
        return Icons.error_outline;
    }
  }

  Color _colorFor(BuildContext context, BackendCheckStatus status) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case BackendCheckStatus.ok:
        return scheme.primary;
      case BackendCheckStatus.warning:
        return scheme.tertiary;
      case BackendCheckStatus.error:
        return scheme.error;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(backendHealthReportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Health'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(backendHealthReportProvider),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Supabase Test',
            onPressed: () => context.go('/debug/supabase'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: reportAsync.when(
        loading: () => const AppBody(child: LoadingIndicator()),
        error: (e, _) => AppBody(
          child: ErrorState(
            title: 'Failed to load backend health',
            message: e.toString(),
            onRetry: () => ref.invalidate(backendHealthReportProvider),
          ),
        ),
        data: (report) {
          if (report.checks.isEmpty) {
            return const AppBody(
              child: EmptyState(
                title: 'No checks available',
                message: 'Health checks could not be built.',
                icon: Icons.health_and_safety_outlined,
              ),
            );
          }

          final errors = report.checks
              .where((check) => check.status == BackendCheckStatus.error)
              .length;
          final warnings = report.checks
              .where((check) => check.status == BackendCheckStatus.warning)
              .length;

          return AppBody(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Card(
                  child: ListTile(
                    leading: Icon(
                      report.isHealthy ? Icons.check_circle : Icons.warning,
                      color: report.isHealthy
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                    ),
                    title: Text(report.isHealthy
                        ? 'Backend ready'
                        : 'Backend needs attention'),
                    subtitle: Text(
                      '$errors error(s), $warnings warning(s) across schema and policy checks.',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (final check in report.checks)
                  Card(
                    child: ListTile(
                      leading: Icon(
                        _iconFor(check.status),
                        color: _colorFor(context, check.status),
                      ),
                      title: Text(check.title),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('${check.detail}\n${check.remediation}'),
                      ),
                      isThreeLine: true,
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => context.go('/debug/supabase'),
                  icon: const Icon(Icons.play_arrow_outlined),
                  label: const Text('Open live Supabase test'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

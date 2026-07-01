import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/exceptions/error_handler.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/app_body.dart';
import '../../../../services/backend_health_service.dart';
import '../../../../services/sync_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../providers/admin_staff_provider.dart';
import '../../dashboard/providers/company_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(companyProvider);
    final staffAsync = ref.watch(staffListProvider);
    final queueAsync = ref.watch(pendingOutboxCountProvider);
    final healthAsync = ref.watch(backendHealthReportProvider);

    final staffCount = staffAsync.asData?.value.length;
    final queueCount = queueAsync.asData?.value;

    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.canPop() ? context.pop() : context.go('/profile'),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
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
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Hero card
            FadeInSlide(
              duration: const Duration(milliseconds: 500),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [scheme.primary, const Color(0xFF2E5A8F)],
                  ),
                  boxShadow: [BoxShadow(color: scheme.primary.withOpacity(0.25), blurRadius: 30, offset: const Offset(0, 16))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Operations Hub',
                            style: tt.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    companyAsync.when(
                      loading: () => const Text('Loading company…', style: TextStyle(color: Colors.white70)),
                      error: (e, _) => Text(ErrorHandler.handle(e), style: const TextStyle(color: Colors.white70)),
                      data: (company) {
                        final companyName = company?.shopName.trim().isNotEmpty == true
                            ? company!.shopName.trim()
                            : company?.name.trim().isNotEmpty == true
                                ? company!.name.trim()
                                : 'No company linked';
                        return Row(
                          children: [
                            const Icon(Icons.store_outlined, color: Colors.white70, size: 18),
                            const SizedBox(width: 8),
                            Text(companyName, style: tt.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _metricChip(context, label: 'Staff', value: staffCount == null ? '…' : '$staffCount', icon: Icons.people_outline, dark: true),
                        const SizedBox(width: 8),
                        _metricChip(context, label: 'Queue', value: queueCount == null ? '…' : '$queueCount', icon: Icons.cloud_queue_outlined, dark: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Menu items
            FadeInSlide(
              duration: const Duration(milliseconds: 600),
              child: _buildMenuItem(
                context, icon: Icons.people_outline, title: 'Staff management',
                subtitle: const Text('Add, edit roles & manage team members'),
                onTap: () => context.go('/admin/staff'),
              ),
            ),
            const SizedBox(height: 8),
            FadeInSlide(
              duration: const Duration(milliseconds: 650),
              child: _buildMenuItem(
                context, icon: Icons.file_upload_outlined, title: 'Bulk import / export',
                subtitle: const Text('Move products, suppliers, and customers with CSV tools'),
                onTap: () => context.go('/admin/data-tools'),
              ),
            ),
            const SizedBox(height: 8),
            FadeInSlide(
              duration: const Duration(milliseconds: 700),
              child: _buildMenuItem(
                context, icon: Icons.health_and_safety_outlined, title: 'Backend health',
                subtitle: healthAsync.when(
                  loading: () => const Text('Checking schema and policies…', style: TextStyle(fontSize: 13)),
                  error: (e, _) => Text(ErrorHandler.handle(e), style: const TextStyle(fontSize: 13)),
                  data: (report) {
                    final errors = report.checks.where((c) => c.status == BackendCheckStatus.error).length;
                    final warnings = report.checks.where((c) => c.status == BackendCheckStatus.warning).length;
                    return Text('$errors error(s), $warnings warning(s)', style: const TextStyle(fontSize: 13));
                  },
                ),
                onTap: () => context.go('/debug/backend-health'),
              ),
            ),
            const SizedBox(height: 8),
            FadeInSlide(
              duration: const Duration(milliseconds: 750),
              child: _buildMenuItem(
                context, icon: Icons.cloud_queue_outlined, title: 'Sync queue',
                subtitle: Text(queueCount == null ? 'Loading pending actions…' : '$queueCount action(s) waiting to sync', style: const TextStyle(fontSize: 13)),
                onTap: () => context.go('/debug/sync-queue'),
              ),
            ),
            const SizedBox(height: 8),
            FadeInSlide(
              duration: const Duration(milliseconds: 800),
              child: _buildMenuItem(
                context, icon: Icons.notifications_outlined, title: 'Live notifications',
                subtitle: const Text('Open alerts and inventory reminders', style: TextStyle(fontSize: 13)),
                onTap: () => context.go('/notifications'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricChip(BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    bool dark = false,
  }) {
    final labelStyle = Theme.of(context).textTheme.labelLarge;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withOpacity(0.12) : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: dark ? Colors.white : Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: (labelStyle ?? const TextStyle(fontSize: 12)).copyWith(
              fontWeight: FontWeight.w700,
              color: dark ? Colors.white : null,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {
    required IconData icon,
    required String title,
    required Widget subtitle,
    required VoidCallback onTap,
  }) {
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: scheme.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      DefaultTextStyle(
                        style: (tt.bodySmall ?? const TextStyle()).copyWith(color: scheme.onSurface.withOpacity(0.6)),
                        child: subtitle,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: scheme.onSurface.withOpacity(0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

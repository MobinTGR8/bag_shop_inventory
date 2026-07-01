import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/constants/user_roles.dart';
import '../../../theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/permission_provider.dart';
import '../../dashboard/providers/company_provider.dart';
import '../../dashboard/providers/dashboard_stats_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final permissions = ref.watch(permissionsProvider);
    final tt = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    if (auth.user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const AppBody(
          child: EmptyState(
            title: 'Not signed in',
            message: 'Please sign in to view your profile.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final companyAsync = ref.watch(companyProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.go('/notifications'),
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            tooltip: 'Sync queue',
            onPressed: () => context.go('/debug/sync-queue'),
            icon: const Icon(Icons.cloud_queue_outlined),
          ),
        ],
      ),
      body: AppBody(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // --- User avatar & info card ---
            FadeInSlide(
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: scheme.primaryContainer,
                        child: Text(
                          ((auth.user?.email ?? 'U').trim().isNotEmpty)
                              ? (auth.user?.email ?? 'U')[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.user?.email ?? 'User',
                              style: tt.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Role: ${auth.role?.toDb() ?? 'unknown'}',
                              style: tt.bodySmall?.copyWith(
                                color: scheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            Text(
                              'Staff ID: ${auth.staffId ?? '—'}',
                              style: tt.bodySmall?.copyWith(
                                color: scheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // --- Company card ---
            companyAsync.when(
              loading: () => FadeInSlide(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 14),
                      Text('Loading company…'),
                    ],
                  ),
                ),
              ),
              error: (e, _) => FadeInSlide(
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.dangerColor.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.store_outlined, color: AppTheme.dangerColor),
                    ),
                    title: const Text('Company'),
                    subtitle: Text(e.toString()),
                  ),
                ),
              ),
              data: (company) {
                final title = company?.shopName.trim().isNotEmpty == true
                    ? company!.shopName.trim()
                    : company?.name.trim().isNotEmpty == true
                        ? company!.name.trim()
                        : 'No company linked';

                return FadeInSlide(
                  child: Container(
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.store_outlined, color: scheme.primary),
                      ),
                      title: Text(title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      subtitle: Text(company?.email ?? 'Live company profile'),
                      trailing: FilledButton.tonal(
                        onPressed: () => context.go('/admin'),
                        child: const Text('Admin'),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // --- Stats row ---
            statsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (stats) {
                return FadeInSlide(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Today Sales', style: tt.labelSmall?.copyWith(color: scheme.onSurface.withOpacity(0.6))),
                              const SizedBox(height: 4),
                              Text(
                                '\$${stats.todaySales.toStringAsFixed(2)}',
                                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: scheme.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Low Stock', style: tt.labelSmall?.copyWith(color: scheme.onSurface.withOpacity(0.6))),
                              const SizedBox(height: 4),
                              Text(
                                '${stats.lowStockCount}',
                                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: AppTheme.warningColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // --- Permissions card ---
            FadeInSlide(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield_outlined, size: 20, color: scheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Permissions',
                          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: permissions
                          .map(
                            (permission) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: scheme.secondaryContainer.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                permission,
                                style: tt.labelSmall?.copyWith(color: scheme.onSecondaryContainer),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // --- Menu items card ---
            FadeInSlide(
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _menuItem(
                      context,
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'View system alerts and reminders',
                      onTap: () => context.go('/notifications'),
                    ),
                    Divider(height: 1, indent: 56, color: scheme.outline.withOpacity(0.15)),
                    _menuItem(
                      context,
                      icon: Icons.cloud_queue_outlined,
                      title: 'Sync queue',
                      subtitle: 'Review pending offline actions',
                      onTap: () => context.go('/debug/sync-queue'),
                    ),
                    Divider(height: 1, indent: 56, color: scheme.outline.withOpacity(0.15)),
                    _menuItem(
                      context,
                      icon: Icons.health_and_safety_outlined,
                      title: 'Backend health',
                      subtitle: 'Check Supabase access and schema',
                      onTap: () => context.go('/debug/backend-health'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Logout button ---
            FadeInSlide(
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (!context.mounted) return;
                    context.go('/login');
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.dangerColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: scheme.primary, size: 20),
            ),
            title: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(subtitle),
            trailing: Icon(Icons.chevron_right, color: scheme.onSurface.withOpacity(0.4)),
          ),
        ),
      ),
    );
  }
}

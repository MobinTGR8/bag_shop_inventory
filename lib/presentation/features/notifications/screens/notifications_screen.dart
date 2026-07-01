import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/permission_provider.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (auth.user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const AppBody(
          child: EmptyState(
            title: 'Not signed in',
            message: 'Please sign in to see notifications.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final canViewInventory = ref.watch(canViewInventoryProvider);
    final notificationsAsync = ref.watch(inAppNotificationsProvider);
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(inAppNotificationsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const AppBody(child: LoadingIndicator()),
        error: (e, _) => AppBody(
          child: ErrorState(
            title: 'Failed to load notifications',
            message: e.toString(),
            onRetry: () => ref.invalidate(inAppNotificationsProvider),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return AppBody(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  EmptyState(
                    title: 'No notifications',
                    message: 'You are all caught up.',
                    icon: Icons.notifications_none_outlined,
                  ),
                ],
              ),
            );
          }

          return AppBody(
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final n = items[index];
                return StaggeredFadeIn.build(
                  index: index,
                  child: Container(
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: scheme.outline.withOpacity(0.5)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 1))],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: n.route == null
                            ? null
                            : () {
                                if (!canViewInventory &&
                                    n.route!.startsWith('/inventory')) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('You do not have access to Inventory.')),
                                  );
                                  return;
                                }
                                context.go(n.route!);
                              },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: scheme.primaryContainer.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(n.icon, color: scheme.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n.title,
                                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      n.message,
                                      style: tt.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.6)),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (n.route != null)
                                Icon(Icons.chevron_right, size: 18, color: scheme.onSurface.withOpacity(0.3)),
                            ],
                          ),
                        ),
                      ),
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
}

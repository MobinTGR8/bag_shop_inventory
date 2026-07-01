import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../auth/providers/permission_provider.dart';
import '../providers/customer_provider.dart';

class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canView = ref.watch(canViewCustomersProvider);
    if (!canView) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customers')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have access to Customers.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final canEdit = ref.watch(canEditCustomersProvider);
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(customersProvider),
            icon: const Icon(Icons.refresh),
          ),
          if (canEdit)
            IconButton(
              tooltip: 'Add customer',
              onPressed: () => context.go('/customers/add'),
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      body: customersAsync.when(
        loading: () => const AppBody(child: LoadingIndicator()),
        error: (e, _) => AppBody(
          child: ErrorState(
            title: 'Failed to load customers',
            message: e.toString(),
            onRetry: () => ref.invalidate(customersProvider),
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
                    title: 'No customers',
                    message:
                        'Add customers to quickly attach them to sales and invoices.',
                    icon: Icons.people_outline,
                  ),
                ],
              ),
            );
          }

          final tt = Theme.of(context).textTheme;
          final scheme = Theme.of(context).colorScheme;
          return AppBody(
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final c = items[index];
                final initial = c.name.isNotEmpty ? c.name[0].toUpperCase() : '?';
                final subtitle = (c.phone?.trim().isNotEmpty ?? false) ? c.phone!.trim() : c.id;

                return StaggeredFadeIn.build(
                  index: index,
                  child: Container(
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
                        onTap: !canEdit ? null : () => context.go('/customers/${c.id}/edit'),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [scheme.primary, scheme.primary.withOpacity(0.7)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.name, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    Text(subtitle, style: tt.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.5))),
                                  ],
                                ),
                              ),
                              if (canEdit) ...[
                                Icon(Icons.chevron_right, size: 18, color: scheme.onSurface.withOpacity(0.3)),
                              ],
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

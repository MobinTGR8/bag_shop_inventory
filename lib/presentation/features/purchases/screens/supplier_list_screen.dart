import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../auth/providers/permission_provider.dart';
import '../providers/supplier_admin_provider.dart';

class SupplierListScreen extends ConsumerWidget {
  const SupplierListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canViewPurchases = ref.watch(canViewPurchasesProvider);
    if (!canViewPurchases) {
      return Scaffold(
        appBar: AppBar(title: const Text('Suppliers')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have access to Purchases.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final canEdit = ref.watch(canEditPurchasesProvider);
    final suppliersAsync = ref.watch(suppliersAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(suppliersAdminProvider),
            icon: const Icon(Icons.refresh),
          ),
          if (canEdit)
            IconButton(
              tooltip: 'Add supplier',
              onPressed: () => context.go('/purchases/suppliers/add'),
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      body: suppliersAsync.when(
        loading: () => const AppBody(child: LoadingIndicator()),
        error: (e, _) => AppBody(
          child: ErrorState(
            title: 'Failed to load suppliers',
            message: e.toString(),
            onRetry: () => ref.invalidate(suppliersAdminProvider),
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
                    title: 'No suppliers',
                    message:
                        'Add your first supplier to start creating purchase orders.',
                    icon: Icons.local_shipping_outlined,
                  ),
                ],
              ),
            );
          }

          return AppBody(
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final s = items[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.local_shipping_outlined),
                    title: Text(s.name),
                    subtitle: Text(s.id),
                    trailing: canEdit ? const Icon(Icons.chevron_right) : null,
                    onTap: !canEdit
                        ? null
                        : () => context.go('/purchases/suppliers/${s.id}/edit'),
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

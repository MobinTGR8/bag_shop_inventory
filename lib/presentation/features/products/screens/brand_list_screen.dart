import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../auth/providers/permission_provider.dart';
import '../providers/product_provider.dart';

class BrandListScreen extends ConsumerWidget {
  const BrandListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEdit = ref.watch(canEditProductsProvider);
    if (!canEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Brands')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have permission to manage brands.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final async = ref.watch(brandsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Brands'),
        actions: [
          IconButton(
            tooltip: 'Add',
            onPressed: () => context.go('/products/brands/add'),
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(brandsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: async.when(
        loading: () => const AppBody(child: LoadingIndicator()),
        error: (e, _) => AppBody(
          child: ErrorState(
            title: 'Failed to load brands',
            message: e.toString(),
            onRetry: () => ref.invalidate(brandsProvider),
          ),
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return AppBody(
              child: EmptyState(
                title: 'No brands',
                message: 'Create brands to organize products.',
                icon: Icons.sell_outlined,
                action: FilledButton.icon(
                  onPressed: () => context.go('/products/brands/add'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add brand'),
                ),
              ),
            );
          }

          return AppBody(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: rows.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final b = rows[index];
                return ListTile(
                  title: Text(b.name),
                  subtitle:
                      b.website?.isNotEmpty == true ? Text(b.website!) : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    if (b.id == null) return;
                    context.go('/products/brands/${b.id}/edit');
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

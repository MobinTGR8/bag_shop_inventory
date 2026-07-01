import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../auth/providers/permission_provider.dart';
import '../providers/product_provider.dart';

class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEdit = ref.watch(canEditProductsProvider);
    if (!canEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Categories')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have permission to manage categories.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final async = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            tooltip: 'Add',
            onPressed: () => context.go('/products/categories/add'),
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(categoriesProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: async.when(
        loading: () => const AppBody(child: LoadingIndicator()),
        error: (e, _) => AppBody(
          child: ErrorState(
            title: 'Failed to load categories',
            message: e.toString(),
            onRetry: () => ref.invalidate(categoriesProvider),
          ),
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return AppBody(
              child: EmptyState(
                title: 'No categories',
                message: 'Create categories to organize products.',
                icon: Icons.category_outlined,
                action: FilledButton.icon(
                  onPressed: () => context.go('/products/categories/add'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add category'),
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
                final c = rows[index];
                return ListTile(
                  title: Text(c.name),
                  subtitle: c.description?.isNotEmpty == true
                      ? Text(c.description!)
                      : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    if (c.id == null) return;
                    context.go('/products/categories/${c.id}/edit');
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

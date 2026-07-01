import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../data/models/product/category_model.dart';
import '../../../../data/repositories/product_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/permission_provider.dart';
import '../providers/product_provider.dart';

class CategoryFormScreen extends ConsumerStatefulWidget {
  final String? categoryId;

  const CategoryFormScreen({super.key, this.categoryId});

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = ref.watch(canEditProductsProvider);
    if (!canEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Category')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have permission to manage categories.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final isEdit = widget.categoryId != null;
    final companyId = ref.watch(authProvider).companyId;

    if (!isEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Category')),
        body: _buildForm(context, companyId: companyId, existing: null),
      );
    }

    final categoriesAsync = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Category'),
        actions: [
          IconButton(
            tooltip: 'Delete',
            onPressed: _saving
                ? null
                : () async {
                    final ok = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete category?'),
                            content: const Text('This cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                    if (!ok) return;

                    setState(() => _saving = true);
                    try {
                      await ref
                          .read(productRepositoryProvider)
                          .deleteCategory(widget.categoryId!);
                      ref.invalidate(categoriesProvider);
                      if (!context.mounted) return;
                      context.pop(true);
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const AppBody(child: LoadingIndicator()),
        error: (e, _) => AppBody(
          child: ErrorState(
            title: 'Failed to load categories',
            message: e.toString(),
          ),
        ),
        data: (rows) {
          final existing =
              rows.where((c) => c.id == widget.categoryId).firstOrNull;
          if (existing == null) {
            return const AppBody(
              child: EmptyState(
                title: 'Category not found',
                message: 'This category no longer exists or you lack access.',
                icon: Icons.category_outlined,
              ),
            );
          }
          return _buildForm(context, companyId: companyId, existing: existing);
        },
      ),
    );
  }

  Widget _buildForm(
    BuildContext context, {
    required String? companyId,
    required CategoryModel? existing,
  }) {
    if (existing != null) {
      if (_nameCtrl.text.isEmpty) _nameCtrl.text = existing.name;
      if (_descCtrl.text.isEmpty) _descCtrl.text = existing.description ?? '';
    }

    return AppBody(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.category_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _saving
                  ? null
                  : () async {
                      final name = _nameCtrl.text.trim();
                      final desc = _descCtrl.text.trim();

                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Name is required.')),
                        );
                        return;
                      }
                      if (existing == null && companyId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('No company found for this user.')),
                        );
                        return;
                      }

                      setState(() => _saving = true);
                      try {
                        final repo = ref.read(productRepositoryProvider);
                        if (existing == null) {
                          await repo.createCategory(
                            CategoryModel(
                              companyId: companyId,
                              name: name,
                              description: desc.isEmpty ? null : desc,
                            ),
                          );
                        } else {
                          await repo.updateCategory(
                            CategoryModel(
                              id: existing.id,
                              companyId: existing.companyId,
                              name: name,
                              description: desc.isEmpty ? null : desc,
                              icon: existing.icon,
                              color: existing.color,
                              createdAt: existing.createdAt,
                            ),
                          );
                        }

                        ref.invalidate(categoriesProvider);
                        if (!context.mounted) return;
                        context.pop(true);
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving…' : 'Save'),
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

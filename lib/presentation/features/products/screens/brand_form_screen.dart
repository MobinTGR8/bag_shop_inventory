import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../data/models/product/brand_model.dart';
import '../../../../data/repositories/product_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/permission_provider.dart';
import '../providers/product_provider.dart';

class BrandFormScreen extends ConsumerStatefulWidget {
  final String? brandId;

  const BrandFormScreen({super.key, this.brandId});

  @override
  ConsumerState<BrandFormScreen> createState() => _BrandFormScreenState();
}

class _BrandFormScreenState extends ConsumerState<BrandFormScreen> {
  final _nameCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = ref.watch(canEditProductsProvider);
    if (!canEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Brand')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have permission to manage brands.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final isEdit = widget.brandId != null;
    final companyId = ref.watch(authProvider).companyId;

    if (!isEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Brand')),
        body: _buildForm(context, companyId: companyId, existing: null),
      );
    }

    final brandsAsync = ref.watch(brandsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Brand'),
        actions: [
          IconButton(
            tooltip: 'Delete',
            onPressed: _saving
                ? null
                : () async {
                    final ok = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete brand?'),
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
                          .deleteBrand(widget.brandId!);
                      ref.invalidate(brandsProvider);
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
      body: brandsAsync.when(
        loading: () => const AppBody(child: LoadingIndicator()),
        error: (e, _) => AppBody(
          child: ErrorState(
            title: 'Failed to load brands',
            message: e.toString(),
          ),
        ),
        data: (rows) {
          final existing =
              rows.where((b) => b.id == widget.brandId).firstOrNull;
          if (existing == null) {
            return const AppBody(
              child: EmptyState(
                title: 'Brand not found',
                message: 'This brand no longer exists or you lack access.',
                icon: Icons.sell_outlined,
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
    required BrandModel? existing,
  }) {
    if (existing != null) {
      if (_nameCtrl.text.isEmpty) _nameCtrl.text = existing.name;
      if (_websiteCtrl.text.isEmpty) _websiteCtrl.text = existing.website ?? '';
    }

    return AppBody(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.sell_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _websiteCtrl,
            decoration: const InputDecoration(
              labelText: 'Website (optional)',
              prefixIcon: Icon(Icons.link_outlined),
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
                      final website = _websiteCtrl.text.trim();

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
                          await repo.createBrand(
                            BrandModel(
                              companyId: companyId,
                              name: name,
                              website: website.isEmpty ? null : website,
                            ),
                          );
                        } else {
                          await repo.updateBrand(
                            BrandModel(
                              id: existing.id,
                              companyId: existing.companyId,
                              name: name,
                              website: website.isEmpty ? null : website,
                              logoUrl: existing.logoUrl,
                              createdAt: existing.createdAt,
                            ),
                          );
                        }

                        ref.invalidate(brandsProvider);
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

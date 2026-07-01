import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../data/repositories/supplier_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/permission_provider.dart';
import '../providers/supplier_admin_provider.dart';
import '../providers/suppliers_provider.dart';

class SupplierFormScreen extends ConsumerStatefulWidget {
  final String? supplierId;

  const SupplierFormScreen({super.key, this.supplierId});

  @override
  ConsumerState<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends ConsumerState<SupplierFormScreen> {
  final _nameController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = ref.watch(canEditPurchasesProvider);
    if (!canEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Supplier')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have permission to edit suppliers.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final companyId = ref.watch(authProvider).companyId;
    final isEdit = widget.supplierId != null;

    if (isEdit) {
      final supplierAsync = ref.watch(supplierByIdProvider(widget.supplierId!));
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Supplier')),
        body: supplierAsync.when(
          loading: () => const AppBody(child: LoadingIndicator()),
          error: (e, _) => AppBody(
            child: ErrorState(
              title: 'Failed to load supplier',
              message: e.toString(),
            ),
          ),
          data: (supplier) {
            if (supplier == null) {
              return const AppBody(
                child: EmptyState(
                  title: 'Supplier not found',
                  message:
                      'This supplier no longer exists or you do not have access.',
                  icon: Icons.local_shipping_outlined,
                ),
              );
            }

            if (_nameController.text.isEmpty) {
              _nameController.text = supplier.name;
            }

            return _buildForm(context,
                companyId: companyId, supplierId: supplier.id);
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add Supplier')),
      body: _buildForm(context, companyId: companyId, supplierId: null),
    );
  }

  Widget _buildForm(
    BuildContext context, {
    required String? companyId,
    required String? supplierId,
  }) {
    return AppBody(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Supplier name',
              hintText: 'e.g. ABC Bags Wholesale',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _saving
                  ? null
                  : () async {
                      final name = _nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Supplier name is required.')),
                        );
                        return;
                      }
                      if (companyId == null && supplierId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('No company found for this user.')),
                        );
                        return;
                      }

                      setState(() => _saving = true);
                      try {
                        final repo = ref.read(supplierRepositoryProvider);
                        if (supplierId == null) {
                          await repo.createSupplier(
                              companyId: companyId!, name: name);
                        } else {
                          await repo.updateSupplier(
                              supplierId: supplierId, name: name);
                        }

                        ref.invalidate(suppliersAdminProvider);
                        ref.invalidate(suppliersProvider);
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

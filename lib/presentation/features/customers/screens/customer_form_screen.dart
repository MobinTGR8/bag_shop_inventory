import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../data/repositories/customer_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/permission_provider.dart';
import '../providers/customer_provider.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  final String? customerId;

  const CustomerFormScreen({super.key, this.customerId});

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = ref.watch(canEditCustomersProvider);
    if (!canEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have permission to edit customers.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final companyId = ref.watch(authProvider).companyId;
    final isEdit = widget.customerId != null;

    if (isEdit) {
      final customerAsync = ref.watch(customerByIdProvider(widget.customerId!));
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Customer'),
          actions: [
            IconButton(
              tooltip: 'Delete',
              onPressed: _saving
                  ? null
                  : () async {
                      final ok = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete customer?'),
                              content: const Text(
                                  'This cannot be undone. If this customer is linked to sales, deletion may fail.'),
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
                      final id = widget.customerId!;

                      setState(() => _saving = true);
                      try {
                        await ref
                            .read(customerRepositoryProvider)
                            .deleteCustomer(customerId: id);
                        ref.invalidate(customersProvider);
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
        body: customerAsync.when(
          loading: () => const AppBody(child: LoadingIndicator()),
          error: (e, _) => AppBody(
            child: ErrorState(
              title: 'Failed to load customer',
              message: e.toString(),
            ),
          ),
          data: (customer) {
            if (customer == null) {
              return const AppBody(
                child: EmptyState(
                  title: 'Customer not found',
                  message:
                      'This customer no longer exists or you do not have access.',
                  icon: Icons.people_outline,
                ),
              );
            }

            if (_nameController.text.isEmpty) {
              _nameController.text = customer.name;
            }
            if (_phoneController.text.isEmpty) {
              _phoneController.text = customer.phone ?? '';
            }

            return _buildForm(context,
                companyId: companyId, customerId: customer.id);
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add Customer')),
      body: _buildForm(context, companyId: companyId, customerId: null),
    );
  }

  Widget _buildForm(
    BuildContext context, {
    required String? companyId,
    required String? customerId,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AppBody(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header card
          FadeInSlide(
            duration: const Duration(milliseconds: 500),
            offset: 10,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [scheme.primary, const Color(0xFF2E5A8F)],
                ),
                boxShadow: [BoxShadow(color: scheme.primary.withOpacity(0.25), blurRadius: 30, offset: const Offset(0, 16))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(customerId == null ? Iconsax.user_add : Iconsax.profile_2user, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerId == null ? 'New Customer' : 'Edit Customer',
                          style: tt.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          customerId == null ? 'Add a new customer to your shop' : 'Update customer details',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Form fields
          FadeInSlide(
            duration: const Duration(milliseconds: 600),
            offset: 10,
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outline.withOpacity(0.6)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customer Information', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Customer name',
                        hintText: 'e.g. John Doe',
                        prefixIcon: const Icon(Iconsax.profile_2user, size: 20),
                        filled: true,
                        fillColor: scheme.surfaceContainerHighest.withOpacity(0.5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone (optional)',
                        hintText: 'e.g. +880 1711 111111',
                        prefixIcon: const Icon(Iconsax.call, size: 20),
                        filled: true,
                        fillColor: scheme.surfaceContainerHighest.withOpacity(0.5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Save button
          FadeInSlide(
            duration: const Duration(milliseconds: 700),
            offset: 10,
            child: SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _saving
                    ? null
                    : () async {
                        final name = _nameController.text.trim();
                        final phone = _phoneController.text.trim();

                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Customer name is required.')),
                          );
                          return;
                        }
                        if (companyId == null && customerId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No company found for this user.')),
                          );
                          return;
                        }

                        setState(() => _saving = true);
                        try {
                          final repo = ref.read(customerRepositoryProvider);
                          if (customerId == null) {
                            await repo.createCustomer(
                              companyId: companyId!,
                              name: name,
                              phone: phone.isEmpty ? null : phone,
                            );
                          } else {
                            await repo.updateCustomer(
                              customerId: customerId,
                              name: name,
                              phone: phone.isEmpty ? null : phone,
                            );
                          }

                          ref.invalidate(customersProvider);
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
                icon: const Icon(Iconsax.tick_circle, size: 20),
                label: Text(_saving ? 'Saving…' : 'Save Customer'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

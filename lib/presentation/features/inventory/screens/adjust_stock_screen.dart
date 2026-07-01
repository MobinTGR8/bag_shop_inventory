import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/product_picker_sheet.dart';
import '../../../../data/models/product/product_model.dart';
import '../../../../data/models/warehouse/warehouse_model.dart';
import '../../../../data/repositories/inventory_operations_repository.dart';
import '../../../../services/sync_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/permission_provider.dart';
import '../../products/providers/product_provider.dart';
import '../providers/warehouses_provider.dart';

class AdjustStockScreen extends ConsumerStatefulWidget {
  const AdjustStockScreen({super.key});

  @override
  ConsumerState<AdjustStockScreen> createState() => _AdjustStockScreenState();
}

class _AdjustStockScreenState extends ConsumerState<AdjustStockScreen> {
  WarehouseModel? _warehouse;
  ProductModel? _product;

  final _deltaCtrl = TextEditingController(text: '0');
  final _batchCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _deltaCtrl.dispose();
    _batchCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  int _parseInt(String s) => int.tryParse(s.trim()) ?? 0;

  Future<void> _pickProduct(
    BuildContext context, {
    required List<ProductModel> products,
  }) async {
    final selected = await showProductPickerSheet(
      context: context,
      products: products,
      title: 'Select product to adjust',
    );
    if (selected != null) setState(() => _product = selected);
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = ref.watch(canEditInventoryProvider);
    if (!canEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Adjust stock')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have permission to adjust stock.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final auth = ref.watch(authProvider);
    final companyId = auth.companyId;
    final userId = auth.user?.id;

    final warehousesAsync = ref.watch(inventoryWarehousesProvider);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Adjust stock')),
      body: warehousesAsync.when(
        loading: () =>
            const AppBody(child: Center(child: FadeInSlide(child: CircularProgressIndicator()))),
        error: (e, _) => AppBody(child: Text(e.toString())),
        data: (warehouses) {
          if (_warehouse == null && warehouses.isNotEmpty) {
            _warehouse = warehouses.firstWhere(
              (w) => w.isDefault,
              orElse: () => warehouses.first,
            );
          }

          return productsAsync.when(
            loading: () => const AppBody(
                child: Center(child: FadeInSlide(child: CircularProgressIndicator()))),
            error: (e, _) => AppBody(child: Text(e.toString())),
            data: (products) {
              return AppBody(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    FadeInSlide(
                      offset: 10,
                      child: DropdownButtonFormField<WarehouseModel>(
                      value: _warehouse,
                      items: [
                        for (final w in warehouses)
                          DropdownMenuItem(value: w, child: Text(w.name)),
                      ],
                      onChanged: _saving
                          ? null
                          : (w) => setState(() => _warehouse = w),
                      decoration: const InputDecoration(
                        labelText: 'Warehouse',
                        prefixIcon: Icon(Icons.warehouse_outlined),
                      ),
                    ),
                    ),
                    const SizedBox(height: 12),
                    FadeInSlide(
                      offset: 10,
                      child: Card(
                      child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.inventory_2_outlined, color: Theme.of(context).colorScheme.primary),
                      ),
                      title: Text(_product?.name ?? 'Select product'),
                      subtitle: _product == null ? null : Text('SKU: ${_product!.sku}'),
                      trailing: const Icon(Icons.search),
                      onTap: _saving
                          ? null
                          : () => _pickProduct(context, products: products),
                    ),
                    ),
                    ),
                    const SizedBox(height: 12),
                    FadeInSlide(
                      offset: 10,
                      child: TextField(
                      controller: _deltaCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity delta',
                        hintText: 'e.g. -2 for damaged, +10 for found stock',
                        prefixIcon: Icon(Icons.exposure_outlined),
                      ),
                      enabled: !_saving,
                    ),
                    ),
                    const SizedBox(height: 12),
                    FadeInSlide(
                      offset: 10,
                      child: TextField(
                      controller: _batchCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Batch number (optional)',
                        prefixIcon: Icon(Icons.confirmation_number_outlined),
                      ),
                      enabled: !_saving,
                    ),
                    ),
                    const SizedBox(height: 12),
                    FadeInSlide(
                      offset: 10,
                      child: TextField(
                      controller: _reasonCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Reason (optional)',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                      enabled: !_saving,
                    ),
                    ),
                    const SizedBox(height: 16),
                    FadeInSlide(
                      offset: 10,
                      child: SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _saving
                            ? null
                            : () async {
                                final w = _warehouse;
                                final p = _product;
                                final delta = _parseInt(_deltaCtrl.text);
                                final batch = _batchCtrl.text.trim();
                                final reason = _reasonCtrl.text.trim();

                                if (companyId == null || userId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Not signed in.')),
                                  );
                                  return;
                                }
                                if (w == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Select a warehouse.')),
                                  );
                                  return;
                                }
                                if (p?.id == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Select a product.')),
                                  );
                                  return;
                                }
                                if (delta == 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Delta cannot be 0.')),
                                  );
                                  return;
                                }

                                setState(() => _saving = true);
                                try {
                                  await ref
                                      .read(
                                          inventoryOperationsRepositoryProvider)
                                      .adjustStock(
                                        companyId: companyId,
                                        createdBy: userId,
                                        productId: p!.id!,
                                        warehouseId: w.id,
                                        quantityDelta: delta,
                                        batchNumber:
                                            batch.isEmpty ? null : batch,
                                        reason: reason.isEmpty ? null : reason,
                                      );

                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Stock adjusted.')),
                                  );
                                  Navigator.of(context).pop(true);
                                } catch (e) {
                                  if (!mounted) return;
                                  if (e is QueuedForSyncException) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'No connection. Adjustment queued for sync.'),
                                      ),
                                    );
                                    Navigator.of(context).pop(true);
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );
                                } finally {
                                  if (mounted) setState(() => _saving = false);
                                }
                              },
                        icon: const Icon(Icons.save_outlined),
                        label: Text(_saving ? 'Saving…' : 'Save adjustment'),
                      ),
                    ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

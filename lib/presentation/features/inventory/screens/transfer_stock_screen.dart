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

class TransferStockScreen extends ConsumerStatefulWidget {
  const TransferStockScreen({super.key});

  @override
  ConsumerState<TransferStockScreen> createState() =>
      _TransferStockScreenState();
}

class _TransferStockScreenState extends ConsumerState<TransferStockScreen> {
  WarehouseModel? _from;
  WarehouseModel? _to;
  ProductModel? _product;

  final _qtyCtrl = TextEditingController(text: '1');
  final _batchCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _batchCtrl.dispose();
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
      title: 'Select product to transfer',
    );
    if (selected != null) setState(() => _product = selected);
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = ref.watch(canEditInventoryProvider);
    if (!canEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transfer stock')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have permission to transfer stock.',
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
      appBar: AppBar(title: const Text('Transfer stock')),
      body: warehousesAsync.when(
        loading: () =>
            const AppBody(child: Center(child: FadeInSlide(child: CircularProgressIndicator()))),
        error: (e, _) => AppBody(child: Text(e.toString())),
        data: (warehouses) {
          if (_from == null && warehouses.isNotEmpty) {
            _from = warehouses.firstWhere(
              (w) => w.isDefault,
              orElse: () => warehouses.first,
            );
          }
          if (_to == null && warehouses.length >= 2) {
            _to = warehouses.firstWhere(
              (w) => w.id != _from?.id,
              orElse: () => warehouses.last,
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
                      value: _from,
                      items: [
                        for (final w in warehouses)
                          DropdownMenuItem(value: w, child: Text(w.name)),
                      ],
                      onChanged:
                          _saving ? null : (w) => setState(() => _from = w),
                      decoration: const InputDecoration(
                        labelText: 'From warehouse',
                        prefixIcon: Icon(Icons.warehouse_outlined),
                      ),
                    ),
                    ),
                    const SizedBox(height: 12),
                    FadeInSlide(
                      offset: 10,
                      child: DropdownButtonFormField<WarehouseModel>(
                      value: _to,
                      items: [
                        for (final w in warehouses)
                          DropdownMenuItem(value: w, child: Text(w.name)),
                      ],
                      onChanged:
                          _saving ? null : (w) => setState(() => _to = w),
                      decoration: const InputDecoration(
                        labelText: 'To warehouse',
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
                        child: Icon(Icons.swap_horiz_outlined, color: Theme.of(context).colorScheme.primary),
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
                      controller: _qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        prefixIcon: Icon(Icons.numbers_outlined),
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
                    const SizedBox(height: 16),
                    FadeInSlide(
                      offset: 10,
                      child: SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _saving
                            ? null
                            : () async {
                                final from = _from;
                                final to = _to;
                                final p = _product;
                                final qty = _parseInt(_qtyCtrl.text);
                                final batch = _batchCtrl.text.trim();

                                if (companyId == null || userId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Not signed in.')),
                                  );
                                  return;
                                }
                                if (from == null || to == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Select both warehouses.')),
                                  );
                                  return;
                                }
                                if (from.id == to.id) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Warehouses must be different.')),
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
                                if (qty <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Quantity must be > 0.')),
                                  );
                                  return;
                                }

                                setState(() => _saving = true);
                                try {
                                  await ref
                                      .read(
                                          inventoryOperationsRepositoryProvider)
                                      .transferStock(
                                        companyId: companyId,
                                        createdBy: userId,
                                        productId: p!.id!,
                                        fromWarehouseId: from.id,
                                        toWarehouseId: to.id,
                                        quantity: qty,
                                        batchNumber:
                                            batch.isEmpty ? null : batch,
                                      );

                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Stock transferred.')),
                                  );
                                  Navigator.of(context).pop(true);
                                } catch (e) {
                                  if (!mounted) return;
                                  if (e is QueuedForSyncException) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'No connection. Transfer queued for sync.'),
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
                        icon: const Icon(Icons.swap_horiz_outlined),
                        label: Text(_saving ? 'Saving…' : 'Transfer'),
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

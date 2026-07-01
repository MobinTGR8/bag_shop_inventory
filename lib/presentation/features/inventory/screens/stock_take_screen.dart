import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../data/models/product/product_model.dart';
import '../../../../data/models/warehouse/warehouse_model.dart';
import '../../../../data/repositories/inventory_operations_repository.dart';
import '../../../theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/permission_provider.dart';
import '../../products/providers/product_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/warehouses_provider.dart';

class StockTakeScreen extends ConsumerStatefulWidget {
  const StockTakeScreen({super.key});

  @override
  ConsumerState<StockTakeScreen> createState() => _StockTakeScreenState();
}

class _StockTakeScreenState extends ConsumerState<StockTakeScreen> {
  WarehouseModel? _warehouse;
  final Map<String, int> _counted = <String, int>{};
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};

  bool _saving = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  int _parseInt(String s) => int.tryParse(s.trim()) ?? 0;

  Future<void> _pickProduct(
    BuildContext context, {
    required List<ProductModel> products,
  }) async {
    final selected = await showModalBottomSheet<ProductModel>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final searchCtrl = TextEditingController();
        return StatefulBuilder(
          builder: (context, setState) {
            final q = searchCtrl.text.trim().toLowerCase();
            final filtered = q.isEmpty
                ? products
                : products.where((p) {
                    final hay =
                        '${p.name} ${p.sku} ${p.barcode ?? ''}'.toLowerCase();
                    return hay.contains(q);
                  }).toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Search products',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final p = filtered[index];
                          return ListTile(
                            title: Text(p.name),
                            subtitle: Text(p.sku),
                            onTap: () => Navigator.of(context).pop(p),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selected == null || selected.id == null) return;

    final productId = selected.id!;
    if (_counted.containsKey(productId)) return;

    setState(() {
      _counted[productId] = 0;
      _controllers[productId] = TextEditingController(text: '0');
    });
  }

  void _removeProduct(String productId) {
    setState(() {
      _counted.remove(productId);
      _controllers.remove(productId)?.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = ref.watch(canEditInventoryProvider);
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (!canEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Stock take')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have permission to perform stock takes.',
            icon: Iconsax.lock,
          ),
        ),
      );
    }

    final auth = ref.watch(authProvider);
    final companyId = auth.companyId;
    final userId = auth.user?.id;

    final warehousesAsync = ref.watch(inventoryWarehousesProvider);
    final productsAsync = ref.watch(productsProvider);
    final inventoryAsync = ref.watch(inventoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock take'),
        actions: [
          IconButton(
            tooltip: 'Reset',
            onPressed: _saving
                ? null
                : () {
                    for (final c in _controllers.values) {
                      c.dispose();
                    }
                    setState(() {
                      _counted.clear();
                      _controllers.clear();
                    });
                  },
            icon: const Icon(Icons.restart_alt_outlined),
          ),
        ],
      ),
      body: warehousesAsync.when(
        loading: () =>
            const AppBody(child: Center(child: CircularProgressIndicator())),
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
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) => AppBody(child: Text(e.toString())),
            data: (products) {
              return inventoryAsync.when(
                loading: () => const AppBody(
                    child: Center(child: CircularProgressIndicator())),
                error: (e, _) => AppBody(child: Text(e.toString())),
                data: (inventory) {
                  final warehouse = _warehouse;
                  final warehouseId = warehouse?.id;
                  final invForWarehouse = warehouseId == null
                      ? const <String, int>{}
                      : {
                          for (final row in inventory)
                            if (row.warehouseId == warehouseId)
                              row.productId: row.quantity,
                        };

                  // Ensure counted map is synced with controllers.
                  for (final entry in _controllers.entries) {
                    _counted[entry.key] = _parseInt(entry.value.text);
                  }

                  final lines = <Widget>[
                    DropdownButtonFormField<WarehouseModel>(
                      value: warehouse,
                      items: [
                        for (final w in warehouses)
                          DropdownMenuItem(value: w, child: Text(w.name)),
                      ],
                      onChanged: _saving
                          ? null
                          : (w) {
                              setState(() {
                                _warehouse = w;
                                // Keep list, but reset counts for clarity.
                                for (final c in _controllers.values) {
                                  c.text = '0';
                                }
                              });
                            },
                      decoration: const InputDecoration(
                        labelText: 'Warehouse',
                        prefixIcon: Icon(Icons.warehouse_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: _saving
                            ? null
                            : () => _pickProduct(context, products: products),
                        icon: const Icon(Icons.add_outlined),
                        label: const Text('Add product to count'),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ];

                  if (_controllers.isEmpty) {
                    lines.add(
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: EmptyState(
                          title: 'No items',
                          message:
                              'Add products you want to count, then submit the stock take.',
                          icon: Icons.fact_check_outlined,
                        ),
                      ),
                    );
                  } else {
                    final productById = {
                      for (final p in products)
                        if (p.id != null) p.id!: p,
                    };

                    for (final entry in _controllers.entries) {
                      final productId = entry.key;
                      final p = productById[productId];
                      final before = invForWarehouse[productId] ?? 0;

                      // Prefill with current quantity if still zero and user hasn't edited.
                      if (entry.value.text.trim() == '0' && before != 0) {
                        entry.value.text = before.toString();
                        _counted[productId] = before;
                      }

                      lines.add(StaggeredFadeIn.build(
                        index: _controllers.keys.toList().indexOf(productId),
                        child: Container(
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: scheme.outline.withOpacity(0.5)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(
                                        color: scheme.primaryContainer.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Icon(Iconsax.box, size: 20, color: scheme.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        p?.name ?? p?.sku ?? productId,
                                        style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Remove',
                                      onPressed: _saving ? null : () => _removeProduct(productId),
                                      icon: const Icon(Iconsax.close_circle, size: 18, color: AppTheme.dangerColor),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: before > 0 ? AppTheme.infoColor.withOpacity(0.1) : scheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Current: $before',
                                        style: tt.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: before > 0 ? AppTheme.infoColor : scheme.onSurface.withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: entry.value,
                                  enabled: !_saving,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Counted quantity',
                                    prefixIcon: const Icon(Iconsax.note, size: 20),
                                    filled: true,
                                    fillColor: scheme.surfaceContainerHighest.withOpacity(0.5),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onChanged: (v) {
                                    _counted[productId] = _parseInt(v);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ));
                    }

                    lines.add(const SizedBox(height: 12));
                    lines.add(
                      FadeInSlide(
                        duration: const Duration(milliseconds: 500),
                        offset: 10,
                        child: SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: _saving
                                ? null
                                : () async {
                                    if (companyId == null || userId == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Not signed in.')),
                                      );
                                      return;
                                    }
                                    if (warehouseId == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Select a warehouse.')),
                                      );
                                      return;
                                    }

                                    final stockTakeLines = <StockTakeLine>[];
                                    for (final e in _counted.entries) {
                                      final before = invForWarehouse[e.key] ?? 0;
                                      stockTakeLines.add(
                                        StockTakeLine(
                                          productId: e.key,
                                          countedQuantity: e.value,
                                          quantityBefore: before,
                                        ),
                                      );
                                    }

                                    setState(() => _saving = true);
                                    try {
                                      await ref
                                          .read(inventoryOperationsRepositoryProvider)
                                          .stockTake(
                                            companyId: companyId,
                                            createdBy: userId,
                                            warehouseId: warehouseId,
                                            lines: stockTakeLines,
                                          );

                                      ref.invalidate(inventoryListProvider);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Stock take recorded.')),
                                      );
                                      Navigator.of(context).pop();
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    } finally {
                                      if (mounted) setState(() => _saving = false);
                                    }
                                  },
                            icon: const Icon(Iconsax.tick_circle, size: 20),
                            label: Text(_saving ? 'Saving…' : 'Submit stock take'),
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return AppBody(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: lines,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

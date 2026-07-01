import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../data/models/product/product_model.dart';
import '../../../../data/models/purchases/purchase_order_create_item.dart';
import '../../../../data/models/warehouse/warehouse_model.dart';
import '../../../../services/stable_fingerprint.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/permission_provider.dart';
import '../../products/providers/product_provider.dart';
import '../providers/purchase_create_controller.dart';
import '../providers/purchase_provider.dart';
import '../providers/suppliers_provider.dart';
import '../providers/warehouses_provider.dart';

class AddPurchaseScreen extends ConsumerStatefulWidget {
  const AddPurchaseScreen({super.key});

  @override
  ConsumerState<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends ConsumerState<AddPurchaseScreen> {
  final _poNumberCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _orderDate = DateTime.now();
  String? _supplierId;

  final Map<String, _LineItemState> _itemsByProductId = {};

  @override
  void dispose() {
    _poNumberCtrl.dispose();
    _notesCtrl.dispose();
    for (final i in _itemsByProductId.values) {
      i.dispose();
    }
    super.dispose();
  }

  double _parseMoney(String raw) {
    final v = double.tryParse(raw.trim());
    return v ?? 0;
  }

  int _parseInt(String raw) {
    final v = int.tryParse(raw.trim());
    return v ?? 0;
  }

  List<PurchaseOrderCreateItem> _buildItemsOrNull() {
    final items = <PurchaseOrderCreateItem>[];
    for (final entry in _itemsByProductId.entries) {
      final state = entry.value;
      final qty = _parseInt(state.qtyCtrl.text);
      final cost = _parseMoney(state.unitCostCtrl.text);
      final batch = state.batchCtrl.text.trim();
      if (qty <= 0) continue;

      items.add(
        PurchaseOrderCreateItem(
          productId: entry.key,
          quantity: qty,
          unitCost: cost,
          warehouseId: state.warehouseId,
          batchNumber: batch.isEmpty ? null : batch,
        ),
      );
    }
    return items;
  }

  String _buildCreateRequestId(List<PurchaseOrderCreateItem> items) {
    return StableFingerprint.of({
      'supplierId': _supplierId,
      'orderDate': _orderDate.toIso8601String().split('T').first,
      'poNumber': _poNumberCtrl.text.trim(),
      'notes': _notesCtrl.text.trim(),
      'items': [
        for (final item in items)
          {
            'productId': item.productId,
            'quantity': item.quantity,
            'unitCost': item.unitCost,
            'warehouseId': item.warehouseId,
            'batchNumber': item.batchNumber,
          }
      ],
    });
  }

  double _computeSubtotal() {
    double subtotal = 0;
    for (final i in _itemsByProductId.values) {
      final qty = _parseInt(i.qtyCtrl.text);
      final cost = _parseMoney(i.unitCostCtrl.text);
      if (qty > 0) subtotal += qty * cost;
    }
    return subtotal;
  }

  Future<void> _pickOrderDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _orderDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _orderDate = picked);
    }
  }

  Future<void> _openProductPicker(
    BuildContext context, {
    required List<ProductModel> products,
    required List<WarehouseModel> warehouses,
  }) async {
    final selected = await showModalBottomSheet<ProductModel>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final searchCtrl = TextEditingController();
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                      onChanged: (_) => setModalState(() {}),
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
                            trailing: const Icon(Icons.add),
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

    if (selected == null) return;
    final id = selected.id;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid product (missing id).')),
      );
      return;
    }

    setState(() {
      final defaultWarehouseId = warehouses.isEmpty
          ? null
          : warehouses
              .firstWhere(
                (w) => w.isDefault,
                orElse: () => warehouses.first,
              )
              .id;

      _itemsByProductId.putIfAbsent(
        id,
        () => _LineItemState(
          product: selected,
          qtyCtrl: TextEditingController(text: '1'),
          unitCostCtrl:
              TextEditingController(text: selected.unitCost.toStringAsFixed(2)),
          batchCtrl: TextEditingController(),
          warehouseId: defaultWarehouseId,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = ref.watch(canEditPurchasesProvider);
    if (!canEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Purchase')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have permission to create purchases.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final auth = ref.watch(authProvider);
    final companyId = auth.companyId;
    final userId = auth.user?.id;

    final productsAsync = ref.watch(productsProvider);
    final suppliersAsync = ref.watch(suppliersProvider);
    final warehousesAsync = ref.watch(warehousesProvider);
    final createState = ref.watch(purchaseCreateControllerProvider);

    ref.listen<AsyncValue<String?>>(purchaseCreateControllerProvider,
        (prev, next) {
      next.whenOrNull(
        data: (id) {
          if (prev?.isLoading == true && id != null) {
            ref.invalidate(purchaseOrdersProvider);
            ref.read(purchaseCreateControllerProvider.notifier).reset();
            context.go('/purchases/$id');
          }
        },
        error: (e, _) {
          if (prev?.isLoading == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Create purchase failed: $e')),
            );
          }
        },
      );
    });

    if (companyId == null || userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Purchase')),
        body: const AppBody(
          child: EmptyState(
            title: 'Missing context',
            message: 'Company/user context is missing.',
            icon: Icons.error_outline,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Purchase'),
        actions: [
          IconButton(
            tooltip: 'Reset',
            onPressed: createState.isLoading
                ? null
                : () {
                    setState(() {
                      _poNumberCtrl.clear();
                      _notesCtrl.clear();
                      _supplierId = null;
                      _orderDate = DateTime.now();
                      for (final i in _itemsByProductId.values) {
                        i.dispose();
                      }
                      _itemsByProductId.clear();
                    });
                  },
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const AppBody(child: LoadingIndicator()),
        error: (e, _) => AppBody(
          child: ErrorState(
            title: 'Failed to load products',
            message: e.toString(),
            onRetry: () => ref.invalidate(productsProvider),
          ),
        ),
        data: (products) {
          return suppliersAsync.when(
            loading: () => const AppBody(child: LoadingIndicator()),
            error: (e, _) => AppBody(
              child: ErrorState(
                title: 'Failed to load suppliers',
                message: e.toString(),
                onRetry: () => ref.invalidate(suppliersProvider),
              ),
            ),
            data: (suppliers) {
              return warehousesAsync.when(
                loading: () => const AppBody(child: LoadingIndicator()),
                error: (e, _) => AppBody(
                  child: ErrorState(
                    title: 'Failed to load warehouses',
                    message: e.toString(),
                    onRetry: () => ref.invalidate(warehousesProvider),
                  ),
                ),
                data: (warehouses) {
                  final subtotal = _computeSubtotal();
                  final date =
                      '${_orderDate.year.toString().padLeft(4, '0')}-${_orderDate.month.toString().padLeft(2, '0')}-${_orderDate.day.toString().padLeft(2, '0')}';

                  return AppBody(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _poNumberCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'PO number (optional)',
                                    prefixIcon: Icon(Icons.tag_outlined),
                                  ),
                                  enabled: !createState.isLoading,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String?>(
                                        value: _supplierId,
                                        decoration: const InputDecoration(
                                          labelText: 'Supplier (optional)',
                                          prefixIcon:
                                              Icon(Icons.storefront_outlined),
                                        ),
                                        items: [
                                          const DropdownMenuItem<String?>(
                                            value: null,
                                            child: Text('— No supplier —'),
                                          ),
                                          for (final s in suppliers)
                                            DropdownMenuItem<String?>(
                                              value: s.id,
                                              child: Text(s.name),
                                            ),
                                        ],
                                        onChanged: createState.isLoading
                                            ? null
                                            : (v) =>
                                                setState(() => _supplierId = v),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      tooltip: 'Manage suppliers',
                                      onPressed: createState.isLoading
                                          ? null
                                          : () async {
                                              await context
                                                  .push('/purchases/suppliers');
                                              if (!mounted) return;
                                              ref.invalidate(suppliersProvider);
                                            },
                                      icon: const Icon(
                                          Icons.local_shipping_outlined),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Order date'),
                                  subtitle: Text(date),
                                  trailing:
                                      const Icon(Icons.date_range_outlined),
                                  onTap: createState.isLoading
                                      ? null
                                      : () => _pickOrderDate(context),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _notesCtrl,
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    labelText: 'Notes (optional)',
                                    prefixIcon: Icon(Icons.notes_outlined),
                                  ),
                                  enabled: !createState.isLoading,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Items',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: createState.isLoading
                                  ? null
                                  : () => _openProductPicker(
                                        context,
                                        products: products,
                                        warehouses: warehouses,
                                      ),
                              icon: const Icon(Icons.add),
                              label: const Text('Add product'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_itemsByProductId.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: EmptyState(
                                title: 'No items yet',
                                message: 'Add at least one product.',
                                icon: Icons.inventory_2_outlined,
                              ),
                            ),
                          )
                        else
                          for (final entry in _itemsByProductId.entries)
                            _LineItemCard(
                              item: entry.value,
                              warehouses: warehouses,
                              enabled: !createState.isLoading,
                              onRemove: () {
                                setState(() {
                                  final removed =
                                      _itemsByProductId.remove(entry.key);
                                  removed?.dispose();
                                });
                              },
                              onChanged: () => setState(() {}),
                            ),
                        const SizedBox(height: 12),
                        Card(
                          child: ListTile(
                            title: const Text('Subtotal'),
                            trailing: Text(
                              subtotal.toStringAsFixed(2),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: createState.isLoading
                                ? null
                                : () async {
                                    final items = _buildItemsOrNull();
                                    if (items.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Add at least one item.')),
                                      );
                                      return;
                                    }

                                    await ref
                                        .read(purchaseCreateControllerProvider
                                            .notifier)
                                        .create(
                                          companyId: companyId,
                                          createdBy: userId,
                                          supplierId: _supplierId,
                                          orderDate: _orderDate,
                                          poNumber: _poNumberCtrl.text,
                                          items: items,
                                          notes: _notesCtrl.text,
                                          clientRequestId:
                                              _buildCreateRequestId(items),
                                        );
                                  },
                            icon: createState.isLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.check),
                            label: const Text('Create purchase order'),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
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

class _LineItemState {
  final ProductModel product;
  final TextEditingController qtyCtrl;
  final TextEditingController unitCostCtrl;
  final TextEditingController batchCtrl;
  String? warehouseId;

  _LineItemState({
    required this.product,
    required this.qtyCtrl,
    required this.unitCostCtrl,
    required this.batchCtrl,
    required this.warehouseId,
  });

  void dispose() {
    qtyCtrl.dispose();
    unitCostCtrl.dispose();
    batchCtrl.dispose();
  }
}

class _LineItemCard extends StatelessWidget {
  final _LineItemState item;
  final List<WarehouseModel> warehouses;
  final bool enabled;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _LineItemCard({
    required this.item,
    required this.warehouses,
    required this.enabled,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.product.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: enabled ? onRemove : null,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: item.qtyCtrl,
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      prefixIcon: Icon(Icons.numbers_outlined),
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: item.unitCostCtrl,
                    enabled: enabled,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Unit cost',
                      prefixIcon: Icon(Icons.currency_rupee_outlined),
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: item.warehouseId,
              decoration: const InputDecoration(
                labelText: 'Warehouse (optional)',
                prefixIcon: Icon(Icons.warehouse_outlined),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('— Not set —'),
                ),
                for (final w in warehouses)
                  DropdownMenuItem<String?>(
                    value: w.id,
                    child: Text(w.isDefault ? '${w.name} (default)' : w.name),
                  ),
              ],
              onChanged: enabled
                  ? (value) {
                      item.warehouseId = value;
                      onChanged();
                    }
                  : null,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: item.batchCtrl,
              enabled: enabled,
              decoration: const InputDecoration(
                labelText: 'Batch number (optional)',
                prefixIcon: Icon(Icons.qr_code_2_outlined),
              ),
              onChanged: (_) => onChanged(),
            ),
            const SizedBox(height: 8),
            Text(
              'SKU: ${item.product.sku}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../data/models/purchases/purchase_order_item_model.dart';
import '../../../../data/repositories/warehouse_repository.dart';
import '../../../../services/sync_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/permission_provider.dart';
import '../providers/purchase_detail_provider.dart';
import '../providers/purchase_receive_controller.dart';
import '../providers/warehouses_provider.dart';

class ReceivePurchaseScreen extends ConsumerStatefulWidget {
  final String purchaseOrderId;

  const ReceivePurchaseScreen({super.key, required this.purchaseOrderId});

  @override
  ConsumerState<ReceivePurchaseScreen> createState() =>
      _ReceivePurchaseScreenState();
}

class _ReceivePurchaseScreenState extends ConsumerState<ReceivePurchaseScreen> {
  final Map<String, TextEditingController> _qtyCtrls = {};
  final Map<String, String?> _itemWarehouseIds = {};
  String? _warehouseId;
  String? _loadedDraftForPurchaseId;

  @override
  void dispose() {
    for (final c in _qtyCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _ensureControllers(List<PurchaseOrderItemModel> items) {
    for (final item in items) {
      _qtyCtrls.putIfAbsent(
        item.id,
        () => TextEditingController(text: item.remainingQuantity.toString()),
      );
      _itemWarehouseIds.putIfAbsent(item.id, () => item.warehouseId);
    }
  }

  Future<void> _restoreDraft(List<PurchaseOrderItemModel> items) async {
    if (_loadedDraftForPurchaseId == widget.purchaseOrderId) return;
    _loadedDraftForPurchaseId = widget.purchaseOrderId;

    final prefs = await SharedPreferences.getInstance();
    final raw =
        prefs.getString('purchase_receive_draft_${widget.purchaseOrderId}');
    if (raw == null || raw.isEmpty) return;

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    if (!mounted) return;

    setState(() {
      _warehouseId = decoded['warehouseId'] as String? ?? _warehouseId;
      final qtys =
          (decoded['quantities'] as Map?)?.cast<String, dynamic>() ?? {};
      final warehouses =
          (decoded['warehouses'] as Map?)?.cast<String, dynamic>() ?? {};
      for (final item in items) {
        final qty = qtys[item.id];
        if (qty != null) {
          _qtyCtrls[item.id]?.text = qty.toString();
        }
        if (warehouses.containsKey(item.id)) {
          _itemWarehouseIds[item.id] = warehouses[item.id] as String?;
        }
      }
    });
  }

  Future<void> _saveDraft(List<PurchaseOrderItemModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'warehouseId': _warehouseId,
      'quantities': {
        for (final item in items) item.id: _parseQty(item.id),
      },
      'warehouses': {
        for (final item in items) item.id: _itemWarehouseIds[item.id],
      },
    };
    await prefs.setString(
      'purchase_receive_draft_${widget.purchaseOrderId}',
      jsonEncode(payload),
    );
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('purchase_receive_draft_${widget.purchaseOrderId}');
  }

  int _parseQty(String itemId) {
    final raw = _qtyCtrls[itemId]?.text.trim() ?? '';
    final v = int.tryParse(raw);
    return v ?? 0;
  }

  Map<String, int> _buildReceiveMap(List<PurchaseOrderItemModel> items) {
    final receive = <String, int>{};
    for (final item in items) {
      final qty = _parseQty(item.id);
      if (qty > 0) {
        receive[item.id] = qty;
      }
    }
    return receive;
  }

  Map<String, String?> _buildWarehouseMap(List<PurchaseOrderItemModel> items) {
    return {
      for (final item in items)
        if (_parseQty(item.id) > 0)
          item.id:
              _itemWarehouseIds[item.id] ?? item.warehouseId ?? _warehouseId,
    };
  }

  String? _validate(List<PurchaseOrderItemModel> items) {
    if (_warehouseId == null || _warehouseId!.isEmpty) {
      return 'Select a warehouse';
    }

    bool any = false;
    for (final item in items) {
      final qty = _parseQty(item.id);
      if (qty < 0) {
        return 'Invalid receive qty for ${item.productSku ?? item.productName ?? item.productId}';
      }
      if (qty > item.remainingQuantity) {
        return 'Receive qty exceeds remaining for ${item.productSku ?? item.productName ?? item.productId}';
      }
      if (qty > 0) any = true;
    }

    if (!any) return 'Enter at least one quantity to receive';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = ref.watch(canEditPurchasesProvider);
    if (!canEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Receive Purchase')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have permission to receive purchases.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final auth = ref.watch(authProvider);
    final companyId = auth.companyId;
    final userId = auth.user?.id;

    final detailAsync =
        ref.watch(purchaseOrderDetailProvider(widget.purchaseOrderId));
    final warehousesAsync = ref.watch(warehousesProvider);

    ref.listen<AsyncValue<void>>(purchaseReceiveControllerProvider,
        (prev, next) {
      next.whenOrNull(
        data: (_) {
          if (prev?.isLoading == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Purchase received successfully.')),
            );
            ref.invalidate(purchaseOrderDetailProvider(widget.purchaseOrderId));
            Navigator.of(context).pop();
          }
        },
        error: (e, _) {
          if (prev?.isLoading == true) {
            if (e is QueuedForSyncException) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
              ref.invalidate(
                  purchaseOrderDetailProvider(widget.purchaseOrderId));
              Navigator.of(context).pop();
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Receive failed: $e')),
            );
          }
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Receive Purchase')),
      body: detailAsync.when(
        loading: () => const AppBody(child: LoadingIndicator()),
        error: (e, _) => AppBody(
          child: ErrorState(
            title: 'Failed to load purchase order',
            message: e.toString(),
            onRetry: () => ref.invalidate(
                purchaseOrderDetailProvider(widget.purchaseOrderId)),
          ),
        ),
        data: (detail) {
          _ensureControllers(detail.items);
          _restoreDraft(detail.items);

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
              if (companyId == null || userId == null) {
                return const AppBody(
                  child: EmptyState(
                    title: 'Missing context',
                    message: 'Company/user context is missing.',
                    icon: Icons.error_outline,
                  ),
                );
              }

              if (warehouses.isEmpty) {
                return const AppBody(
                  child: EmptyState(
                    title: 'No warehouses',
                    message:
                        'Create a warehouse (or ensure default warehouse exists).',
                    icon: Icons.warehouse_outlined,
                  ),
                );
              }

              // Set default warehouse once.
              if (_warehouseId == null) {
                final defaultWh = warehouses.firstWhere(
                  (w) => w.isDefault,
                  orElse: () => warehouses.first,
                );
                _warehouseId = defaultWh.id;

                // Best-effort: ensure it matches backend default, if any.
                ref
                    .read(warehouseRepositoryProvider)
                    .getDefaultWarehouseId(companyId: companyId)
                    .then((id) {
                  if (!mounted) return;
                  if (id != null && id != _warehouseId) {
                    setState(() => _warehouseId = id);
                  }
                });
              }

              final receiveState = ref.watch(purchaseReceiveControllerProvider);

              final remainingItems =
                  detail.items.where((i) => i.remainingQuantity > 0).toList();

              if (remainingItems.isEmpty) {
                return const AppBody(
                  child: EmptyState(
                    title: 'Nothing to receive',
                    message:
                        'All items on this purchase order are fully received.',
                    icon: Icons.check_circle_outline,
                  ),
                );
              }

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
                            Text(
                              detail.order.poNumber.isEmpty
                                  ? detail.order.id
                                  : detail.order.poNumber,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _warehouseId,
                              decoration: const InputDecoration(
                                labelText: 'Receive into warehouse',
                                prefixIcon: Icon(Icons.warehouse_outlined),
                              ),
                              items: [
                                for (final w in warehouses)
                                  DropdownMenuItem(
                                    value: w.id,
                                    child: Text(w.isDefault
                                        ? '${w.name} (default)'
                                        : w.name),
                                  ),
                              ],
                              onChanged: receiveState.isLoading
                                  ? null
                                  : (value) =>
                                      setState(() => _warehouseId = value),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Enter received quantities for remaining items.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final item in remainingItems)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName ??
                                  item.productSku ??
                                  item.productId),
                              const SizedBox(height: 6),
                              Text(
                                'Ordered: ${item.quantity} • Received: ${item.receivedQuantity} • Remaining: ${item.remainingQuantity}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _qtyCtrls[item.id],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Receive quantity',
                                  prefixIcon: Icon(Icons.add_circle_outline),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                value:
                                    _itemWarehouseIds[item.id] ?? _warehouseId,
                                decoration: const InputDecoration(
                                  labelText: 'Warehouse override',
                                  prefixIcon: Icon(Icons.warehouse_outlined),
                                ),
                                items: [
                                  for (final w in warehouses)
                                    DropdownMenuItem(
                                      value: w.id,
                                      child: Text(w.isDefault
                                          ? '${w.name} (default)'
                                          : w.name),
                                    ),
                                ],
                                onChanged: receiveState.isLoading
                                    ? null
                                    : (value) => setState(() =>
                                        _itemWarehouseIds[item.id] = value),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: receiveState.isLoading
                                ? null
                                : () async {
                                    await _saveDraft(remainingItems);
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Draft saved')),
                                    );
                                  },
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('Save draft'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: FilledButton.icon(
                              onPressed: receiveState.isLoading
                                  ? null
                                  : () async {
                                      final error = _validate(remainingItems);
                                      if (error != null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(content: Text(error)),
                                        );
                                        return;
                                      }

                                      final receiveByItemId =
                                          _buildReceiveMap(remainingItems);
                                      final warehouseByItemId =
                                          _buildWarehouseMap(remainingItems);

                                      await ref
                                          .read(
                                              purchaseReceiveControllerProvider
                                                  .notifier)
                                          .receive(
                                            purchaseOrderId:
                                                widget.purchaseOrderId,
                                            companyId: companyId,
                                            receivedBy: userId,
                                            fallbackWarehouseId: _warehouseId!,
                                            receiveByItemId: receiveByItemId,
                                            warehouseByItemId:
                                                warehouseByItemId,
                                          );

                                      await _clearDraft();
                                    },
                              icon: receiveState.isLoading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.check),
                              label: const Text('Confirm receive'),
                            ),
                          ),
                        ),
                      ],
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

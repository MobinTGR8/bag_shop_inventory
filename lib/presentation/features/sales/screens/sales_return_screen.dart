import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../data/repositories/sales_repository.dart';
import '../../../../services/sync_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/permission_provider.dart';
import '../providers/sales_detail_provider.dart';

class SalesReturnScreen extends ConsumerStatefulWidget {
  final String salesOrderId;

  const SalesReturnScreen({super.key, required this.salesOrderId});

  @override
  ConsumerState<SalesReturnScreen> createState() => _SalesReturnScreenState();
}

class _SalesReturnScreenState extends ConsumerState<SalesReturnScreen> {
  final Map<String, TextEditingController> _ctrlByItemId = {};
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _ctrlByItemId.values) {
      c.dispose();
    }
    super.dispose();
  }

  int _parseInt(String s) => int.tryParse(s.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final canView = ref.watch(canViewSalesProvider);
    if (!canView) {
      return Scaffold(
        appBar: AppBar(title: const Text('Return')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have access to Sales.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final auth = ref.watch(authProvider);
    final companyId = auth.companyId;
    final userId = auth.user?.id;

    final detailAsync =
        ref.watch(salesOrderDetailProvider(widget.salesOrderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Return items')),
      body: detailAsync.when(
        loading: () => const AppBody(child: LoadingIndicator()),
        error: (e, _) => AppBody(
          child: ErrorState(
            title: 'Failed to load sale',
            message: e.toString(),
          ),
        ),
        data: (d) {
          if (d.items.isEmpty) {
            return const AppBody(
              child: EmptyState(
                title: 'No items',
                message: 'This sale has no items.',
                icon: Icons.inventory_2_outlined,
              ),
            );
          }

          for (final item in d.items) {
            _ctrlByItemId.putIfAbsent(
                item.id, () => TextEditingController(text: '0'));
          }

          return AppBody(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Enter quantities to return (max per line = sold quantity).',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (final item in d.items)
                  Card(
                    child: ListTile(
                      title: Text(item.productName ??
                          item.productSku ??
                          item.productId),
                      subtitle: Text(
                          'Sold: ${item.quantity} • Warehouse: ${item.warehouseName ?? item.warehouseId ?? '-'}'),
                      trailing: SizedBox(
                        width: 90,
                        child: TextField(
                          controller: _ctrlByItemId[item.id],
                          enabled: !_saving,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Return',
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
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

                            final rows = <({
                              String itemId,
                              String productId,
                              String warehouseId,
                              int quantity
                            })>[];
                            for (final item in d.items) {
                              final qty =
                                  _parseInt(_ctrlByItemId[item.id]!.text);
                              if (qty <= 0) continue;
                              if (qty > item.quantity) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Return qty exceeds sold for ${item.productSku ?? item.productId}')),
                                );
                                return;
                              }
                              if (item.warehouseId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Missing warehouse on sale line.')),
                                );
                                return;
                              }
                              rows.add((
                                itemId: item.id,
                                productId: item.productId,
                                warehouseId: item.warehouseId!,
                                quantity: qty,
                              ));
                            }

                            if (rows.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Nothing to return.')),
                              );
                              return;
                            }

                            setState(() => _saving = true);
                            try {
                              await ref
                                  .read(salesRepositoryProvider)
                                  .returnSaleItems(
                                    companyId: companyId,
                                    createdBy: userId,
                                    salesOrderId: widget.salesOrderId,
                                    items: rows,
                                  );

                              ref.invalidate(salesOrderDetailProvider(
                                  widget.salesOrderId));
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Return recorded.')),
                              );
                              Navigator.of(context).pop(true);
                            } catch (e) {
                              if (!mounted) return;
                              if (e is QueuedForSyncException) {
                                ref.invalidate(salesOrderDetailProvider(
                                    widget.salesOrderId));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'No connection. Return queued for sync.'),
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
                    icon: const Icon(Icons.undo_outlined),
                    label: Text(_saving ? 'Saving…' : 'Record return'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

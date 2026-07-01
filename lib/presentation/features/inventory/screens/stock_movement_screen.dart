import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../theme/app_theme.dart';
import '../../auth/providers/permission_provider.dart';
import '../providers/stock_movements_provider.dart';
import '../providers/warehouses_provider.dart';

class StockMovementScreen extends ConsumerStatefulWidget {
  const StockMovementScreen({super.key});

  @override
  ConsumerState<StockMovementScreen> createState() =>
      _StockMovementScreenState();
}

class _StockMovementScreenState extends ConsumerState<StockMovementScreen> {
  String? _warehouseId;
  String? _movementType;
  DateTimeRange? _range;

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final initial = _range ??
        DateTimeRange(
          start: DateTime(now.year, now.month, now.day - 7),
          end: DateTime(now.year, now.month, now.day),
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDateRange: initial,
    );

    if (picked != null) {
      setState(() => _range = picked);
    }
  }

  String _fmtDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final canView = ref.watch(canViewInventoryProvider);
    if (!canView) {
      return Scaffold(
        appBar: AppBar(title: const Text('Stock Movements')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have access to Inventory.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final warehousesAsync = ref.watch(inventoryWarehousesProvider);

    final from = _range?.start;
    // make end exclusive (+1 day) to include the selected end date
    final to = _range == null
        ? null
        : DateTime(
            _range!.end.year,
            _range!.end.month,
            _range!.end.day + 1,
          );

    final query = StockMovementsQuery(
      warehouseId: _warehouseId,
      movementType: _movementType,
      from: from,
      to: to,
      limit: 250,
    );

    final movementsAsync = ref.watch(stockMovementsProvider(query));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Movements'),
        actions: [
          IconButton(
            tooltip: 'Reset filters',
            onPressed: () {
              setState(() {
                _warehouseId = null;
                _movementType = null;
                _range = null;
              });
            },
            icon: const Icon(Icons.filter_alt_off_outlined),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(stockMovementsProvider(query)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: warehousesAsync.when(
        loading: () => const AppBody(child: LoadingIndicator()),
        error: (e, _) => AppBody(
          child: ErrorState(
            title: 'Failed to load warehouses',
            message: e.toString(),
            onRetry: () => ref.invalidate(inventoryWarehousesProvider),
          ),
        ),
        data: (warehouses) {
          final filterChips = <Widget>[
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: _warehouseId,
                decoration: const InputDecoration(
                  labelText: 'Warehouse',
                  prefixIcon: Icon(Icons.warehouse_outlined),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All'),
                  ),
                  for (final w in warehouses)
                    DropdownMenuItem<String?>(
                      value: w.id,
                      child: Text(w.isDefault ? '${w.name} (default)' : w.name),
                    ),
                ],
                onChanged: (v) => setState(() => _warehouseId = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: _movementType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  prefixIcon: Icon(Icons.swap_vert_outlined),
                ),
                items: const [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'PURCHASE',
                    child: Text('PURCHASE'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'SALE',
                    child: Text('SALE'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'ADJUSTMENT',
                    child: Text('ADJUSTMENT'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'TRANSFER',
                    child: Text('TRANSFER'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'RETURN',
                    child: Text('RETURN'),
                  ),
                ],
                onChanged: (v) => setState(() => _movementType = v),
              ),
            ),
          ];

          final rangeLabel = _range == null
              ? 'Any date'
              : '${_fmtDate(_range!.start)} → ${_fmtDate(_range!.end)}';

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    Row(children: filterChips),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: () => _pickRange(context),
                        icon: const Icon(Icons.date_range_outlined),
                        label: Text(rangeLabel),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(stockMovementsProvider(query));
                    await ref.read(stockMovementsProvider(query).future);
                  },
                  child: movementsAsync.when(
                    loading: () => const AppBody(child: LoadingIndicator()),
                    error: (e, _) => AppBody(
                      child: ErrorState(
                        title: 'Failed to load movements',
                        message: e.toString(),
                        onRetry: () =>
                            ref.invalidate(stockMovementsProvider(query)),
                      ),
                    ),
                    data: (rows) {
                      if (rows.isEmpty) {
                        return AppBody(
                          child: ListView(
                            padding: EdgeInsets.zero,
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 80),
                              EmptyState(
                                title: 'No movements',
                                message: 'No stock movements match the current filters.',
                                icon: Icons.swap_vert_outlined,
                              ),
                            ],
                          ),
                        );
                      }

                      final tt = Theme.of(context).textTheme;
                      final scheme = Theme.of(context).colorScheme;
                      return AppBody(
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: rows.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final m = rows[index];
                            final title = m.productName?.isNotEmpty == true
                                ? m.productName!
                                : m.productSku?.isNotEmpty == true
                                    ? m.productSku!
                                    : m.productId;
                            final when = '${_fmtDate(m.createdAt.toLocal())} ${m.createdAt.toLocal().hour.toString().padLeft(2, '0')}:${m.createdAt.toLocal().minute.toString().padLeft(2, '0')}';
                            final isIn = m.quantityChange >= 0;
                            final qtyColor = isIn ? AppTheme.successColor : AppTheme.dangerColor;
                            final typeIcon = isIn ? Icons.arrow_downward : Icons.arrow_upward;
                            final typeColor = isIn ? AppTheme.successColor : AppTheme.dangerColor;

                            return StaggeredFadeIn.build(
                              index: index,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: scheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: scheme.outline.withOpacity(0.6)),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: typeColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(typeIcon, color: typeColor, size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: typeColor.withOpacity(0.10),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    m.movementType,
                                                    style: tt.bodySmall?.copyWith(color: typeColor, fontWeight: FontWeight.w700, fontSize: 10),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                if (m.warehouseName?.isNotEmpty == true)
                                                  Flexible(
                                                    child: Text(m.warehouseName!, style: tt.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.5)), overflow: TextOverflow.ellipsis),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(when, style: tt.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.4), fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            isIn ? '+${m.quantityChange}' : '${m.quantityChange}',
                                            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: qtyColor),
                                          ),
                                          if (m.quantityBefore != null)
                                            Text(
                                              'Before: ${m.quantityBefore}',
                                              style: tt.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.5)),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../data/models/product/product_model.dart';
import '../../../../data/repositories/sales_repository.dart';
import '../../../../data/repositories/warehouse_repository.dart';
import '../../../../services/barcode_service.dart';
import '../../../../services/stable_fingerprint.dart';
import '../../../../services/sync_service.dart';
import '../../../theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/permission_provider.dart';
import '../../products/providers/product_provider.dart';
import '../widgets/payment_simulation_sheet.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchCtrl = TextEditingController();
  final _cashCtrl = TextEditingController();
  final _cardCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  final Map<String, int> _cart = {};
  bool _isCheckingOut = false;
  String _paymentMode = 'CASH';

  Future<void> _scanToSearch() async {
    final code = await BarcodeService.scanBarcode(context);
    if (!mounted) return;
    if (code == null || code.trim().isEmpty) return;
    setState(() {
      _searchCtrl.text = code.trim();
      _searchCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchCtrl.text.length),
      );
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _cashCtrl.dispose();
    _cardCtrl.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }

  void _addToCart(ProductModel product) {
    final id = product.id;
    if (id == null) return;
    setState(() {
      _cart.update(id, (v) => v + 1, ifAbsent: () => 1);
    });
  }

  void _removeFromCart(String productId) {
    setState(() {
      final current = _cart[productId] ?? 0;
      if (current <= 1) {
        _cart.remove(productId);
      } else {
        _cart[productId] = current - 1;
      }
    });
  }

  double _cartTotal(Map<String, ProductModel> productsById) {
    double total = 0;
    _cart.forEach((productId, qty) {
      final p = productsById[productId];
      if (p == null) return;
      total += p.sellingPrice * qty;
    });
    return total;
  }

  double _parseAmount(TextEditingController controller) {
    return double.tryParse(controller.text.trim()) ?? 0;
  }

  String _buildCheckoutRequestId({
    required String companyId,
    required String createdBy,
    required String warehouseId,
    required List<({String productId, int quantity, double unitPrice})> items,
    required String paymentMode,
    required Map<String, dynamic>? paymentSplit,
    required double taxAmount,
    required double discountAmount,
    required double shippingCharge,
  }) {
    return StableFingerprint.of({
      'companyId': companyId,
      'createdBy': createdBy,
      'warehouseId': warehouseId,
      'paymentMode': paymentMode,
      'items': [
        for (final item in items)
          {
            'productId': item.productId,
            'quantity': item.quantity,
            'unitPrice': item.unitPrice,
          }
      ],
      'paymentSplit': paymentSplit,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'shippingCharge': shippingCharge,
    });
  }

  Map<String, dynamic>? _buildPaymentSplit(double total) {
    if (_paymentMode != 'SPLIT') {
      return null;
    }

    final cash = _parseAmount(_cashCtrl);
    final card = _parseAmount(_cardCtrl);
    final upi = _parseAmount(_upiCtrl);
    final splitTotal = cash + card + upi;
    if ((splitTotal - total).abs() > 0.01) {
      throw Exception('Split payment must equal the cart total');
    }

    return {
      if (cash > 0) 'CASH': cash,
      if (card > 0) 'CARD': card,
      if (upi > 0) 'UPI': upi,
    };
  }

  Future<void> _checkout(Map<String, ProductModel> productsById) async {
    if (_cart.isEmpty) return;
    final auth = ref.read(authProvider);
    final companyId = auth.companyId;
    final userId = auth.user?.id;
    if (companyId == null || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing company/user context.')),
      );
      return;
    }

    setState(() => _isCheckingOut = true);
    try {
      final warehouseId = await ref
          .read(warehouseRepositoryProvider)
          .getDefaultWarehouseId(companyId: companyId);
      if (warehouseId == null) {
        throw Exception('No warehouse found for this company');
      }

      final items = <({String productId, int quantity, double unitPrice})>[];
      for (final entry in _cart.entries) {
        final p = productsById[entry.key];
        if (p == null) continue;
        items.add((
          productId: entry.key,
          quantity: entry.value,
          unitPrice: p.sellingPrice,
        ));
      }

      final total = _cartTotal(productsById);
      final paymentSplit = _buildPaymentSplit(total);

      // --- Show payment simulation before creating the sale ---
      final simResult = await showPaymentSimulation(
        context: context,
        totalAmount: total,
        paymentMode: _paymentMode,
        paymentSplit: paymentSplit,
      );

      if (!mounted) return;

      // If simulation failed, abort checkout
      if (!simResult.success) {
        setState(() => _isCheckingOut = false);
        return;
      }

      // Simulation succeeded — now create the sale
      final requestId = _buildCheckoutRequestId(
        companyId: companyId,
        createdBy: userId,
        warehouseId: warehouseId,
        items: items,
        paymentMode: _paymentMode,
        paymentSplit: paymentSplit,
        taxAmount: 0,
        discountAmount: 0,
        shippingCharge: 0,
      );

      final result = await ref.read(salesRepositoryProvider).createSale(
            companyId: companyId,
            createdBy: userId,
            warehouseId: warehouseId,
            items: items,
            paymentMethod: _paymentMode,
            paymentSplit: paymentSplit,
            clientRequestId: requestId,
          );

      if (!mounted) return;
      setState(() {
        _cart.clear();
        _cashCtrl.clear();
        _cardCtrl.clear();
        _upiCtrl.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.queuedForSync
                ? 'Sale created (queued for sync): ${result.invoiceNumber}'
                : 'Sale created: ${result.invoiceNumber}',
          ),
        ),
      );
      // Refresh outbox badge if anything was queued.
      if (result.queuedForSync) {
        ref.invalidate(pendingOutboxCountProvider);
      }
      context.go('/sales');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPos = ref.watch(canAccessPosProvider);
    if (!canPos) {
      return Scaffold(
        appBar: AppBar(title: const Text('POS')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have access to POS.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final productsAsync = ref.watch(productsProvider);

    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('POS'),
        actions: [
          IconButton(
            tooltip: 'Scan barcode',
            onPressed: _scanToSearch,
            icon: const Icon(Icons.qr_code_scanner),
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
          final productsById = <String, ProductModel>{
            for (final p in products)
              if (p.id != null) p.id!: p,
          };

          final q = _searchCtrl.text.trim().toLowerCase();
          final filtered = q.isEmpty
              ? products
              : products
                  .where(
                    (p) =>
                        p.name.toLowerCase().contains(q) ||
                        p.sku.toLowerCase().contains(q) ||
                        (p.barcode?.toLowerCase().contains(q) ?? false),
                  )
                  .toList();

          final total = _cartTotal(productsById);
          final count = _cart.values.fold<int>(0, (s, v) => s + v);

          return Column(
            children: [
              // Search bar with premium styling
              FadeInSlide(
                duration: const Duration(milliseconds: 400),
                offset: 10,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search by name, SKU, or barcode...',
                      prefixIcon: const Icon(Iconsax.search_normal, size: 20),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchCtrl.text.isNotEmpty)
                            IconButton(
                              tooltip: 'Clear',
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close, size: 18),
                            ),
                        ],
                      ),
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),

              // Product list or empty state
              Expanded(
                child: filtered.isEmpty
                    ? const FadeInSlide(
                        child: Padding(
                          padding: EdgeInsets.only(top: 60),
                          child: EmptyState(
                            title: 'No matching products',
                            message:
                                'Try a different search term or scan a barcode.',
                            icon: Iconsax.search_normal_1,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final p = filtered[index];
                          final id = p.id;
                          final qty = id == null ? 0 : (_cart[id] ?? 0);
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: 8,
                              top: index == 0 ? 0 : 0,
                            ),
                            child: StaggeredFadeIn.build(
                              index: index,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: scheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: qty > 0
                                        ? scheme.primary.withOpacity(0.3)
                                        : scheme.outline.withOpacity(0.5),
                                  ),
                                  boxShadow: qty > 0
                                      ? [BoxShadow(color: scheme.primary.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]
                                      : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 1))],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    children: [
                                      // Product icon with gradient background
                                      Container(
                                        width: 44, height: 44,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              scheme.primary.withOpacity(0.7),
                                              scheme.primary.withOpacity(0.4),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Center(
                                          child: Icon(Iconsax.box, color: Colors.white, size: 20),
                                        ),
                                      ),
                                      const Gap(12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.name,
                                              style: tt.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: scheme.onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${p.sku} • ${p.sellingPrice.toStringAsFixed(0)} Tk',
                                              style: tt.bodySmall?.copyWith(
                                                color: scheme.onSurface.withOpacity(0.5),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Quantity controls
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            borderRadius: BorderRadius.circular(8),
                                            onTap: id == null || qty == 0
                                                ? null
                                                : () => _removeFromCart(id),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: qty > 0
                                                    ? AppTheme.dangerColor.withOpacity(0.1)
                                                    : Colors.transparent,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                qty > 0 ? Iconsax.minus : Iconsax.add,
                                                size: 18,
                                                color: qty > 0
                                                    ? AppTheme.dangerColor
                                                    : scheme.primary,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 36,
                                            child: Center(
                                              child: Text(
                                                qty.toString(),
                                                style: tt.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.w900,
                                                  color: qty > 0
                                                      ? scheme.primary
                                                      : scheme.onSurface,
                                                ),
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            borderRadius: BorderRadius.circular(8),
                                            onTap: id == null
                                                ? null
                                                : () => _addToCart(p),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: scheme.primary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Iconsax.add,
                                                size: 18,
                                                color: scheme.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Bottom checkout bar
              FadeInSlide(
                duration: const Duration(milliseconds: 500),
                offset: 10,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    border: Border(
                      top: BorderSide(color: scheme.outline.withOpacity(0.15)),
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -2))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Payment method chips
                      Row(
                        children: [
                          Text('Payment', style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                          const Spacer(),
                          _paymentChip('CASH', Iconsax.money, Colors.green),
                          const SizedBox(width: 6),
                          _paymentChip('CARD', Iconsax.card, Colors.blue),
                          const SizedBox(width: 6),
                          _paymentChip('UPI', Iconsax.mobile, AppTheme.infoColor),
                          const SizedBox(width: 6),
                          _paymentChip('SPLIT', Iconsax.chart, Colors.orange),
                        ],
                      ),
                      if (_paymentMode == 'SPLIT') ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _cashCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Cash',
                                  prefixIcon: const Icon(Iconsax.money, size: 18),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _cardCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Card',
                                  prefixIcon: const Icon(Iconsax.card, size: 18),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _upiCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'UPI',
                                  prefixIcon: const Icon(Iconsax.mobile, size: 18),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$count items',
                                  style: tt.bodySmall?.copyWith(
                                    color: scheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                                Text(
                                  '${total.toStringAsFixed(0)} Tk',
                                  style: tt.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 50,
                            child: FilledButton.icon(
                              onPressed: _isCheckingOut || _cart.isEmpty
                                  ? null
                                  : () => _checkout(productsById),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 28),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: _isCheckingOut
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Iconsax.tick_circle, size: 20),
                              label: Text(
                                _isCheckingOut ? 'Processing...' : 'Checkout',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _paymentChip(String mode, IconData icon, Color color) {
    final isActive = _paymentMode == mode;
    return GestureDetector(
      onTap: () => setState(() {
        _paymentMode = mode;
        if (mode != 'SPLIT') {
          _cashCtrl.clear();
          _cardCtrl.clear();
          _upiCtrl.clear();
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? color.withOpacity(0.4) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? color : null),
            const SizedBox(width: 4),
            Text(
              mode,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? color : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

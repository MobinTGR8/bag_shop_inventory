import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../auth/providers/permission_provider.dart';
import '../../../../data/models/product/product_model.dart';
import '../providers/product_provider.dart';

const _categoryColors = <String, Color>{
  'Backpacks': Color(0xFF4CAF50),
  'Handbags': Color(0xFFFF9800),
  'Tote Bags': Color(0xFF2196F3),
  'Wallets': Color(0xFF9C27B0),
  'Luggage': Color(0xFFFF5722),
  'Messenger Bags': Color(0xFF795548),
  'Duffle Bags': Color(0xFF00BCD4),
  'Clutches': Color(0xFFE91E63),
};

final _categoryIcons = <String, IconData>{
  'Backpacks': Iconsax.box,
  'Handbags': Iconsax.bag_2,
  'Tote Bags': Iconsax.bag,
  'Wallets': Iconsax.wallet,
  'Luggage': Iconsax.briefcase,
  'Messenger Bags': Iconsax.bag_tick,
  'Duffle Bags': Iconsax.bag_timer,
  'Clutches': Iconsax.bag_cross,
};

Color _bagTypeColor(String? bagType) {
  if (bagType == null) return const Color(0xFF6B7280);
  for (final entry in _categoryColors.entries) {
    if (bagType.toLowerCase().contains(entry.key.split(' ')[0].toLowerCase())) return entry.value;
  }
  return const Color(0xFF6B7280);
}

IconData _bagTypeIcon(String? bagType) {
  if (bagType == null) return Iconsax.bag;
  for (final entry in _categoryIcons.entries) {
    if (bagType.toLowerCase().contains(entry.key.split(' ')[0].toLowerCase())) return entry.value;
  }
  return Iconsax.bag;
}

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});
  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);
    final canEditProducts = ref.watch(canEditProductsProvider);
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          if (canEditProducts)
            PopupMenuButton<String>(
              tooltip: 'More',
              onSelected: (v) {
                switch (v) {
                  case 'categories': context.go('/products/categories'); return;
                  case 'brands': context.go('/products/brands'); return;
                  case 'barcode_labels':
                    ref.read(productsProvider.future).then((p) {
                      if (context.mounted) _showBarcodeLabelOptions(context, p);
                    });
                    return;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'categories', child: Text('Manage categories')),
                PopupMenuItem(value: 'brands', child: Text('Manage brands')),
                PopupMenuItem(value: 'barcode_labels', child: Text('Generate barcode labels')),
              ],
              icon: const Icon(Icons.more_vert),
            ),
          if (canEditProducts)
            IconButton(
              onPressed: () => context.go('/products/add'),
              icon: const Icon(Icons.add),
              tooltip: 'Add product',
            ),
        ],
      ),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return AppBody(
              child: EmptyState(
                title: 'No products yet',
                message: 'Add your first product to start tracking inventory.',
                icon: Icons.inventory_2_outlined,
                action: canEditProducts
                    ? FilledButton.icon(
                        onPressed: () => context.go('/products/add'),
                        icon: const Icon(Icons.add),
                        label: const Text('Add product'),
                      )
                    : null,
              ),
            );
          }
          final query = _searchController.text.trim().toLowerCase();
          final filtered = products.where((p) {
            if (_selectedCategory != null) {
              final catMatch = p.bagType?.toLowerCase().contains(_selectedCategory!.split(' ')[0].toLowerCase());
              if (catMatch != true) return false;
            }
            if (query.isEmpty) return true;
            return '${p.name} ${p.sku} ${p.bagType ?? ''} ${p.barcode ?? ''}'.toLowerCase().contains(query);
          }).toList();

          final allBagTypes = <String>{};
          for (final p in products) {
            if (p.bagType != null && p.bagType!.isNotEmpty) {
              bool matched = false;
              for (final cat in _categoryColors.keys) {
                if (p.bagType!.toLowerCase().contains(cat.split(' ')[0].toLowerCase())) {
                  allBagTypes.add(cat);
                  matched = true;
                  break;
                }
              }
              if (!matched) allBagTypes.add(p.bagType!);
            }
          }
          final sortedBagTypes = allBagTypes.toList()..sort();

          return AppBody(
            child: Column(
              children: [
                _buildSearchBar(scheme, tt),
                const SizedBox(height: 8),
                if (sortedBagTypes.isNotEmpty) _buildFilterChips(sortedBagTypes, scheme, tt),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Text('${filtered.length} product${filtered.length == 1 ? '' : 's'}',
                          style: tt.labelMedium?.copyWith(color: scheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w500)),
                      if (_selectedCategory != null) ...[const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: _bagTypeColor(_selectedCategory).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Text(_selectedCategory!, style: tt.labelSmall?.copyWith(color: _bagTypeColor(_selectedCategory), fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptySearch(scheme, tt)
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            return StaggeredFadeIn.build(
                              index: index,
                              child: _ProductCard(
                                product: filtered[index],
                                onTap: () {
                                  if (filtered[index].id == null) return;
                                  context.go('/products/${filtered[index].id}');
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
        loading: () => AppBody(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: 6,
            itemBuilder: (_, __) => const Padding(padding: EdgeInsets.only(bottom: 8), child: ShimmerListTile()),
          ),
        ),
        error: (e, _) => AppBody(
          child: ErrorState(title: 'Failed to load products', message: e.toString(), onRetry: () => ref.invalidate(productsStreamProvider)),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Iconsax.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Iconsax.box), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Iconsax.shopping_cart), label: 'POS'),
          BottomNavigationBarItem(icon: Icon(Iconsax.receipt_item), label: 'Sales'),
          BottomNavigationBarItem(icon: Icon(Iconsax.user), label: 'Profile'),
        ],
        onTap: (index) {
          final routes = ['/', '/products', '/pos', '/sales', '/profile'];
          context.go(routes[index]);
        },
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme scheme, TextTheme tt) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withOpacity(0.15)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: Icon(Icons.search, color: scheme.onSurface.withOpacity(0.4)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: 18, color: scheme.onSurface.withOpacity(0.4)),
                  onPressed: () { _searchController.clear(); setState(() {}); },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        style: tt.bodyMedium,
      ),
    );
  }

  Widget _buildFilterChips(List<String> bagTypes, ColorScheme scheme, TextTheme tt) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: bagTypes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final cat = bagTypes[index];
          final isSelected = _selectedCategory == cat;
          final color = _bagTypeColor(cat);
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = isSelected ? null : cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.12) : scheme.surfaceContainerHighest.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? color.withOpacity(0.3) : scheme.outline.withOpacity(0.1), width: isSelected ? 1.5 : 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_bagTypeIcon(cat), size: 14, color: isSelected ? color : scheme.onSurface.withOpacity(0.5)),
                  const SizedBox(width: 6),
                  Text(cat, style: tt.labelSmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? color : scheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                  )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptySearch(ColorScheme scheme, TextTheme tt) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: scheme.surfaceContainerHighest.withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Iconsax.search_normal_1, size: 36),
          ),
          const SizedBox(height: 12),
          Text('No products found', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Try adjusting your search or filter.',
              style: tt.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.6))),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bagColor = _bagTypeColor(product.bagType);
    final icon = _bagTypeIcon(product.bagType);
    final profitMargin = product.unitCost > 0
        ? ((product.sellingPrice - product.unitCost) / product.unitCost * 100).toStringAsFixed(0)
        : '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.12)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [bagColor.withOpacity(0.7), bagColor.withOpacity(0.3)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: Icon(icon, color: Colors.white, size: 24)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(product.sku, style: tt.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.4), fontWeight: FontWeight.w500, fontSize: 11)),
                          if (product.bagType != null) ...[const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(color: bagColor.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                              child: Text(product.bagType!, style: tt.labelSmall?.copyWith(color: bagColor, fontSize: 9, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [scheme.primary.withOpacity(0.9), scheme.primary.withOpacity(0.6)]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Tk ${product.sellingPrice.toStringAsFixed(0)}',
                          style: tt.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                    const SizedBox(height: 4),
                    Text('$profitMargin% margin',
                        style: tt.bodySmall?.copyWith(
                          color: double.parse(profitMargin) > 20 ? const Color(0xFF10B981) : scheme.onSurface.withOpacity(0.4),
                          fontWeight: FontWeight.w600, fontSize: 10,
                        )),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 18, color: scheme.onSurface.withOpacity(0.2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showBarcodeLabelOptions(BuildContext context, List<ProductModel> products) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final searchCtrl = TextEditingController();
      return StatefulBuilder(
        builder: (context, setState) {
          final q = searchCtrl.text.trim().toLowerCase();
          final filtered = q.isEmpty
              ? products
              : products.where((p) {
                  final hay = '${p.name} ${p.sku} ${p.barcode ?? ''}'
                      .toLowerCase();
                  return hay.contains(q);
                }).toList();

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Product Barcode Labels',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
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
                      itemCount: filtered.length.clamp(0, 20),
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx2, index) {
                        final p = filtered[index];
                        return ListTile(
                          leading: p.barcode != null && p.barcode!.isNotEmpty
                              ? QrImageView(
                                  data: p.barcode!,
                                  version: QrVersions.auto,
                                  size: 40,
                                )
                              : const Icon(Icons.inventory_2_outlined),
                          title: Text('${p.name} (${p.sku})'),
                          subtitle: Text(
                            p.barcode != null && p.barcode!.isNotEmpty
                                ? 'Barcode: ${p.barcode}'
                                : 'No barcode assigned',
                          ),
                          trailing: p.barcode != null && p.barcode!.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.share_outlined),
                                  tooltip: 'Share label',
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Barcode label for ${p.name} ready. PDF printing available in sale details.'),
                                      ),
                                    );
                                    Navigator.of(context).pop();
                                  },
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
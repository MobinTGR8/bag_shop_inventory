import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../data/repositories/product_repository.dart';
import '../../auth/providers/permission_provider.dart';
import '../providers/product_provider.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productByIdProvider(productId));
    final canEditProducts = ref.watch(canEditProductsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final brandsAsync = ref.watch(brandsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          if (canEditProducts)
            IconButton(
              tooltip: 'Edit',
              onPressed: () => context.go('/products/$productId/edit'),
              icon: const Icon(Icons.edit_outlined),
            ),
          if (canEditProducts)
            IconButton(
              tooltip: 'Delete',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete product?'),
                    content: const Text(
                        'This cannot be undone. Existing sales/purchases may prevent deletion.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirmed != true) return;

                try {
                  await ref
                      .read(productRepositoryProvider)
                      .deleteProduct(productId);
                  ref.invalidate(productsStreamProvider);
                  ref.invalidate(productByIdProvider(productId));
                  if (!context.mounted) return;
                  context.go('/products');
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: productAsync.when(
        data: (product) {
          if (product == null) {
            return const AppBody(
              child: EmptyState(
                title: 'Product not found',
                message:
                    'This product no longer exists or you do not have access.',
                icon: Icons.inventory_2_outlined,
              ),
            );
          }

          final tt = Theme.of(context).textTheme;
          final scheme = Theme.of(context).colorScheme;

          final categories = categoriesAsync.asData?.value;
          final brands = brandsAsync.asData?.value;
          final categoryName =
              (categories == null || product.categoryId == null)
                  ? null
                  : categories
                      .where((c) => c.id == product.categoryId)
                      .map((c) => c.name)
                      .cast<String?>()
                      .firstWhere((_) => true, orElse: () => null);
          final brandName = (brands == null || product.brandId == null)
              ? null
              : brands
                  .where((b) => b.id == product.brandId)
                  .map((b) => b.name)
                  .cast<String?>()
                  .firstWhere((_) => true, orElse: () => null);

          final profitMargin = product.unitCost > 0
              ? ((product.sellingPrice - product.unitCost) /
                      product.unitCost *
                      100)
                  .toStringAsFixed(1)
              : '0';

          return AppBody(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Hero header with gradient
                FadeInSlide(
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scheme.primary,
                          scheme.primary.withOpacity(0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withOpacity(0.25),
                          blurRadius: 30,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bag type badge
                        if (product.bagType != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              product.bagType!,
                              style: tt.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          product.name,
                          style: tt.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.sell_outlined,
                                size: 14, color: Colors.white70),
                            const SizedBox(width: 6),
                            Text(
                              'SKU: ${product.sku}',
                              style: tt.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.qr_code,
                                size: 14, color: Colors.white70),
                            const SizedBox(width: 6),
                            Text(
                              product.barcode ?? 'No barcode',
                              style: tt.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Price row
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selling Price',
                                  style: tt.labelSmall?.copyWith(
                                    color: Colors.white60,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tk ${product.sellingPrice.toStringAsFixed(0)}',
                                  style: tt.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 24),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Unit Cost',
                                  style: tt.labelSmall?.copyWith(
                                    color: Colors.white60,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tk ${product.unitCost.toStringAsFixed(0)}',
                                  style: tt.titleLarge?.copyWith(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 24),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Profit',
                                  style: tt.labelSmall?.copyWith(
                                    color: Colors.white60,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$profitMargin%',
                                  style: tt.titleLarge?.copyWith(
                                    color: const Color(0xFF10B981),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Image gallery
                if (product.imageUrls != null && product.imageUrls!.isNotEmpty)
                  FadeInSlide(
                    duration: const Duration(milliseconds: 550),
                    child: _ImageGallery(imageUrls: product.imageUrls!),
                  ),
                if (product.imageUrls != null && product.imageUrls!.isNotEmpty)
                  const SizedBox(height: 16),

                // Quick info cards
                FadeInSlide(
                  duration: const Duration(milliseconds: 600),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // ignore: prefer_const_constructors
                      _InfoChip(
                        icon: Icons.category_outlined,
                        label: categoryName ?? 'Uncategorized',
                        color: scheme.primary,
                      ),
                      if (brandName != null)
                        // ignore: prefer_const_constructors
                        _InfoChip(
                          icon: Icons.sell_outlined,
                          label: brandName,
                          color: const Color(0xFF7C3AED),
                        ),
                      _InfoChip(
                        icon: Icons.inventory_2_outlined,
                        label: 'Min: ${product.minStock}',
                        color: const Color(0xFF059669),
                      ),
                      if (product.maxStock != null)
                        _InfoChip(
                          icon: Icons.inventory_outlined,
                          label: 'Max: ${product.maxStock}',
                          color: const Color(0xFF2563EB),
                        ),
                      if (product.reorderPoint != null)
                        _InfoChip(
                          icon: Icons.notifications_outlined,
                          label: 'Reorder: ${product.reorderPoint}',
                          color: const Color(0xFFD97706),
                        ),
                      _InfoChip(
                        icon: Icons.check_circle_outline,
                        label: product.isActive ? 'Active' : 'Inactive',
                        color: product.isActive
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                if (product.description.trim().isNotEmpty) ...[
                  FadeInSlide(
                    duration: const Duration(milliseconds: 650),
                    child: _SectionCard(
                      title: 'Description',
                      icon: Icons.description_outlined,
                      child: Text(
                        product.description,
                        style: tt.bodyMedium?.copyWith(
                          height: 1.5,
                          color: scheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Physical details
                FadeInSlide(
                  duration: const Duration(milliseconds: 700),
                  child: _SectionCard(
                    title: 'Physical Details',
                    icon: Icons.straighten_outlined,
                    child: Column(
                      children: [
                        _DetailRow(
                            label: 'Material',
                            value: product.material ?? '-'),
                        _DetailRow(
                            label: 'Color', value: product.color ?? '-'),
                        _DetailRow(
                            label: 'Size', value: product.size ?? '-'),
                        _DetailRow(
                            label: 'Dimensions',
                            value: product.dimensions ?? '-'),
                        _DetailRow(
                            label: 'Weight',
                            value: product.weightGrams != null
                                ? '${product.weightGrams!.toStringAsFixed(0)} g'
                                : '-'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Pricing details
                FadeInSlide(
                  duration: const Duration(milliseconds: 750),
                  child: _SectionCard(
                    title: 'Pricing',
                    icon: Icons.monetization_on_outlined,
                    child: Column(
                      children: [
                        _DetailRow(
                            label: 'Unit Cost',
                            value:
                                'Tk ${product.unitCost.toStringAsFixed(2)}'),
                        _DetailRow(
                            label: 'Selling Price',
                            value:
                                'Tk ${product.sellingPrice.toStringAsFixed(2)}'),
                        if (product.wholesalePrice != null)
                          _DetailRow(
                              label: 'Wholesale Price',
                              value:
                                  'Tk ${product.wholesalePrice!.toStringAsFixed(2)}'),
                        _DetailRow(
                            label: 'Profit Margin',
                            value: '$profitMargin%',
                            valueColor: const Color(0xFF10B981)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Warranty
                FadeInSlide(
                  duration: const Duration(milliseconds: 800),
                  child: _SectionCard(
                    title: 'Warranty',
                    icon: Icons.verified_outlined,
                    child: Column(
                      children: [
                        _DetailRow(
                            label: 'Has Warranty',
                            value: product.hasWarranty ? 'Yes' : 'No'),
                        if (product.hasWarranty)
                          _DetailRow(
                              label: 'Warranty Period',
                              value:
                                  '${product.warrantyMonths} month${product.warrantyMonths == 1 ? '' : 's'}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const AppBody(child: LoadingIndicator()),
        error: (e, _) => AppBody(
          child: ErrorState(
            title: 'Failed to load product',
            message: e.toString(),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Helper widgets
// ===========================================================================

class _ImageGallery extends StatefulWidget {
  final List<String> imageUrls;

  const _ImageGallery({required this.imageUrls});

  @override
  State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  final _pageController = PageController();
  var _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image carousel
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 240,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: widget.imageUrls.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) {
                    return CachedNetworkImage(
                      imageUrl: widget.imageUrls[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, __) => Container(
                        color: scheme.surfaceContainerHighest.withOpacity(0.5),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: scheme.error.withOpacity(0.05),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.broken_image_outlined,
                                  size: 36, color: scheme.error.withOpacity(0.5)),
                              const SizedBox(height: 4),
                              Text('Failed to load',
                                  style: tt.bodySmall?.copyWith(
                                      color: scheme.error.withOpacity(0.5))),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Page counter badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentPage + 1} / ${widget.imageUrls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Navigation arrows
                if (widget.imageUrls.length > 1) ...[
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          if (_currentPage > 0) {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black26,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          if (_currentPage < widget.imageUrls.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black26,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Dot indicators
        if (widget.imageUrls.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.imageUrls.length, (i) {
                final isActive = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 24 : 8,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? scheme.primary
                        : scheme.onSurface.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? scheme.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../data/models/product/product_model.dart';
import '../../../../data/models/product/category_model.dart';
import '../../../../data/models/product/brand_model.dart';
import '../../../../data/repositories/product_repository.dart';
import '../../auth/providers/permission_provider.dart';
import '../providers/product_provider.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  final String productId;

  const EditProductScreen({super.key, required this.productId});

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  late final FormGroup form;
  bool _initialized = false;
  bool _saving = false;
  final _picker = ImagePicker();

  Future<void> _addImage(BuildContext context, ProductModel product) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop image',
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop image'),
      ],
    );

    final path = (cropped?.path ?? picked.path).toLowerCase();
    final ext = path.split('.').last;
    final bytes = cropped != null
        ? await cropped.readAsBytes()
        : await picked.readAsBytes();

    final contentType = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    try {
      await ref.read(productRepositoryProvider).uploadAndAttachProductImage(
            product: product,
            bytes: bytes,
            fileExtension: ext,
            contentType: contentType,
          );
      ref.invalidate(productByIdProvider(widget.productId));
      ref.invalidate(productsStreamProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    form = FormGroup({
      'sku': FormControl<String>(validators: [Validators.required]),
      'name': FormControl<String>(validators: [Validators.required]),
      'description': FormControl<String>(value: ''),
      'categoryId': FormControl<String?>(),
      'brandId': FormControl<String?>(),
      'bagType': FormControl<String>(),
      'material': FormControl<String>(),
      'color': FormControl<String>(),
      'size': FormControl<String>(),
      'dimensions': FormControl<String>(),
      'weightGrams': FormControl<double>(),
      'barcode': FormControl<String>(),
      'unitCost': FormControl<double>(validators: [Validators.required]),
      'sellingPrice': FormControl<double>(validators: [Validators.required]),
      'wholesalePrice': FormControl<double>(),
      'minStock': FormControl<int>(validators: [Validators.number]),
      'maxStock': FormControl<int>(validators: [Validators.number]),
      'reorderPoint': FormControl<int>(validators: [Validators.number]),
      'isActive': FormControl<bool>(value: true),
      'hasWarranty': FormControl<bool>(value: false),
      'warrantyMonths':
          FormControl<int>(value: 0, validators: [Validators.number]),
    });
  }

  void _initFromProduct(ProductModel p) {
    if (_initialized) return;
    _initialized = true;

    form.patchValue({
      'sku': p.sku,
      'name': p.name,
      'description': p.description,
      'categoryId': p.categoryId,
      'brandId': p.brandId,
      'bagType': p.bagType ?? '',
      'material': p.material ?? '',
      'color': p.color ?? '',
      'size': p.size ?? '',
      'dimensions': p.dimensions ?? '',
      'weightGrams': p.weightGrams,
      'barcode': p.barcode ?? '',
      'unitCost': p.unitCost,
      'sellingPrice': p.sellingPrice,
      'wholesalePrice': p.wholesalePrice,
      'minStock': p.minStock,
      'maxStock': p.maxStock,
      'reorderPoint': p.reorderPoint,
      'isActive': p.isActive,
      'hasWarranty': p.hasWarranty,
      'warrantyMonths': p.warrantyMonths,
    });
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = ref.watch(canEditProductsProvider);
    if (!canEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Product')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have permission to edit products.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    final productAsync = ref.watch(productByIdProvider(widget.productId));
    final categoriesAsync = ref.watch(categoriesProvider);
    final brandsAsync = ref.watch(brandsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Product')),
      body: productAsync.when(
        loading: () => const AppBody(child: LoadingIndicator()),
        error: (e, _) => AppBody(
          child: ErrorState(
            title: 'Failed to load product',
            message: e.toString(),
          ),
        ),
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

          _initFromProduct(product);

          return AppBody(
            child: ReactiveForm(
              formGroup: form,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Media',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed:
                            _saving ? null : () => _addImage(context, product),
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: const Text('Add image'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (product.imageUrls == null || product.imageUrls!.isEmpty)
                    const Text('No images yet.')
                  else
                    SizedBox(
                      height: 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: product.imageUrls!.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final url = product.imageUrls![index];
                          return InkWell(
                            onTap: () {
                              showDialog<void>(
                                context: context,
                                builder: (context) => Dialog(
                                  child: InteractiveViewer(
                                    child: CachedNetworkImage(
                                      imageUrl: url,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: CachedNetworkImage(
                                  imageUrl: url,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const Divider(height: 28),
                  ReactiveTextField<String>(
                    formControlName: 'sku',
                    decoration: const InputDecoration(
                      labelText: 'SKU',
                      hintText: 'e.g. BAG-0001',
                    ),
                    readOnly: _saving,
                  ),
                  const SizedBox(height: 12),
                  ReactiveTextField<String>(
                    formControlName: 'name',
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'e.g. Leather Handbag',
                    ),
                    readOnly: _saving,
                  ),
                  const SizedBox(height: 12),
                  ReactiveTextField<String>(
                    formControlName: 'description',
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                    ),
                    readOnly: _saving,
                  ),
                  const SizedBox(height: 12),
                  _TaxonomySelectors(
                    categoriesAsync: categoriesAsync,
                    brandsAsync: brandsAsync,
                    readOnly: _saving,
                  ),
                  const SizedBox(height: 12),
                  ReactiveTextField<String>(
                    formControlName: 'bagType',
                    decoration: const InputDecoration(
                      labelText: 'Bag type',
                      hintText: 'Backpack / Handbag / Tote ...',
                    ),
                    readOnly: _saving,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ReactiveTextField<String>(
                          formControlName: 'material',
                          decoration: const InputDecoration(
                            labelText: 'Material (optional)',
                          ),
                          readOnly: _saving,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ReactiveTextField<String>(
                          formControlName: 'color',
                          decoration: const InputDecoration(
                            labelText: 'Color (optional)',
                          ),
                          readOnly: _saving,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ReactiveTextField<String>(
                          formControlName: 'size',
                          decoration: const InputDecoration(
                            labelText: 'Size (optional)',
                          ),
                          readOnly: _saving,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ReactiveTextField<String>(
                          formControlName: 'dimensions',
                          decoration: const InputDecoration(
                            labelText: 'Dimensions (optional)',
                          ),
                          readOnly: _saving,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ReactiveTextField<double>(
                    formControlName: 'weightGrams',
                    keyboardType: TextInputType.number,
                    valueAccessor: DoubleValueAccessor(),
                    decoration: const InputDecoration(
                      labelText: 'Weight (grams, optional)',
                    ),
                    readOnly: _saving,
                  ),
                  const SizedBox(height: 12),
                  ReactiveTextField<String>(
                    formControlName: 'barcode',
                    decoration: const InputDecoration(
                      labelText: 'Barcode (optional)',
                    ),
                    readOnly: _saving,
                  ),
                  const SizedBox(height: 12),
                  ReactiveTextField<double>(
                    formControlName: 'unitCost',
                    keyboardType: TextInputType.number,
                    valueAccessor: DoubleValueAccessor(),
                    decoration: const InputDecoration(
                      labelText: 'Unit cost',
                    ),
                    readOnly: _saving,
                  ),
                  const SizedBox(height: 12),
                  ReactiveTextField<double>(
                    formControlName: 'sellingPrice',
                    keyboardType: TextInputType.number,
                    valueAccessor: DoubleValueAccessor(),
                    decoration: const InputDecoration(
                      labelText: 'Selling price',
                    ),
                    readOnly: _saving,
                  ),
                  const SizedBox(height: 12),
                  ReactiveTextField<double>(
                    formControlName: 'wholesalePrice',
                    keyboardType: TextInputType.number,
                    valueAccessor: DoubleValueAccessor(),
                    decoration: const InputDecoration(
                      labelText: 'Wholesale price (optional)',
                    ),
                    readOnly: _saving,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ReactiveTextField<int>(
                          formControlName: 'minStock',
                          keyboardType: TextInputType.number,
                          valueAccessor: IntValueAccessor(),
                          decoration: const InputDecoration(
                            labelText: 'Min stock',
                          ),
                          readOnly: _saving,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ReactiveTextField<int>(
                          formControlName: 'reorderPoint',
                          keyboardType: TextInputType.number,
                          valueAccessor: IntValueAccessor(),
                          decoration: const InputDecoration(
                            labelText: 'Reorder point (optional)',
                          ),
                          readOnly: _saving,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ReactiveTextField<int>(
                    formControlName: 'maxStock',
                    keyboardType: TextInputType.number,
                    valueAccessor: IntValueAccessor(),
                    decoration: const InputDecoration(
                      labelText: 'Max stock (optional)',
                    ),
                    readOnly: _saving,
                  ),
                  const SizedBox(height: 12),
                  ReactiveSwitchListTile(
                    formControlName: 'isActive',
                    title: const Text('Active'),
                  ),
                  const SizedBox(height: 6),
                  ReactiveSwitchListTile(
                    formControlName: 'hasWarranty',
                    title: const Text('Has warranty'),
                  ),
                  const SizedBox(height: 12),
                  ReactiveTextField<int>(
                    formControlName: 'warrantyMonths',
                    keyboardType: TextInputType.number,
                    valueAccessor: IntValueAccessor(),
                    decoration: const InputDecoration(
                      labelText: 'Warranty months',
                    ),
                    readOnly: _saving,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _saving
                          ? null
                          : () async {
                              form.markAllAsTouched();
                              if (!form.valid) return;

                              setState(() => _saving = true);
                              try {
                                final sku = form.control('sku').value as String;
                                final name =
                                    form.control('name').value as String;
                                final description = (form
                                        .control('description')
                                        .value as String?) ??
                                    '';
                                final bagType =
                                    (form.control('bagType').value as String?)
                                        ?.trim();
                                final material =
                                    (form.control('material').value as String?)
                                        ?.trim();
                                final color =
                                    (form.control('color').value as String?)
                                        ?.trim();
                                final size =
                                    (form.control('size').value as String?)
                                        ?.trim();
                                final dimensions = (form
                                        .control('dimensions')
                                        .value as String?)
                                    ?.trim();
                                final weightGrams = form
                                    .control('weightGrams')
                                    .value as double?;
                                final barcode =
                                    (form.control('barcode').value as String?)
                                        ?.trim();
                                final categoryId =
                                    form.control('categoryId').value as String?;
                                final brandId =
                                    form.control('brandId').value as String?;
                                final unitCost =
                                    form.control('unitCost').value as double;
                                final sellingPrice = form
                                    .control('sellingPrice')
                                    .value as double;
                                final wholesalePrice = form
                                    .control('wholesalePrice')
                                    .value as double?;
                                final minStock =
                                    (form.control('minStock').value as int?) ??
                                        0;
                                final maxStock =
                                    form.control('maxStock').value as int?;
                                final reorderPoint =
                                    form.control('reorderPoint').value as int?;
                                final isActive =
                                    (form.control('isActive').value as bool?) ??
                                        true;
                                final hasWarranty = (form
                                        .control('hasWarranty')
                                        .value as bool?) ??
                                    false;
                                final warrantyMonths = (form
                                        .control('warrantyMonths')
                                        .value as int?) ??
                                    0;

                                final updated = ProductModel(
                                  id: product.id,
                                  companyId: product.companyId,
                                  sku: sku,
                                  name: name,
                                  description: description,
                                  categoryId: categoryId,
                                  brandId: brandId,
                                  bagType: (bagType?.isEmpty ?? true)
                                      ? null
                                      : bagType,
                                  material: (material?.isEmpty ?? true)
                                      ? null
                                      : material,
                                  color:
                                      (color?.isEmpty ?? true) ? null : color,
                                  size: (size?.isEmpty ?? true) ? null : size,
                                  dimensions: (dimensions?.isEmpty ?? true)
                                      ? null
                                      : dimensions,
                                  weightGrams: weightGrams,
                                  barcode: (barcode?.isEmpty ?? true)
                                      ? null
                                      : barcode,
                                  qrCode: product.qrCode,
                                  unitCost: unitCost,
                                  sellingPrice: sellingPrice,
                                  wholesalePrice: wholesalePrice,
                                  minStock: minStock <= 0 ? 0 : minStock,
                                  maxStock: maxStock,
                                  reorderPoint: reorderPoint,
                                  isActive: isActive,
                                  hasWarranty: hasWarranty,
                                  warrantyMonths: hasWarranty
                                      ? (warrantyMonths <= 0
                                          ? 0
                                          : warrantyMonths)
                                      : 0,
                                  imageUrls: product.imageUrls,
                                  videoUrl: product.videoUrl,
                                  createdAt: product.createdAt,
                                  updatedAt: DateTime.now(),
                                );

                                await ref
                                    .read(productRepositoryProvider)
                                    .updateProduct(widget.productId, updated);

                                ref.invalidate(
                                    productByIdProvider(widget.productId));
                                ref.invalidate(productsStreamProvider);

                                if (!context.mounted) return;
                                context.go('/products/${widget.productId}');
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              } finally {
                                if (mounted) setState(() => _saving = false);
                              }
                            },
                      icon: const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'Saving…' : 'Save changes'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TaxonomySelectors extends StatelessWidget {
  final AsyncValue<List<CategoryModel>> categoriesAsync;
  final AsyncValue<List<BrandModel>> brandsAsync;
  final bool readOnly;

  const _TaxonomySelectors({
    required this.categoriesAsync,
    required this.brandsAsync,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    final categories = categoriesAsync.asData?.value ?? const <CategoryModel>[];
    final brands = brandsAsync.asData?.value ?? const <BrandModel>[];

    return Row(
      children: [
        Expanded(
          child: ReactiveDropdownField<String?>(
            formControlName: 'categoryId',
            decoration: const InputDecoration(
              labelText: 'Category',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('None'),
              ),
              for (final c in categories)
                DropdownMenuItem<String?>(
                  value: c.id,
                  child: Text(c.name),
                ),
            ],
            readOnly: readOnly,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ReactiveDropdownField<String?>(
            formControlName: 'brandId',
            decoration: const InputDecoration(
              labelText: 'Brand',
              prefixIcon: Icon(Icons.sell_outlined),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('None'),
              ),
              for (final b in brands)
                DropdownMenuItem<String?>(
                  value: b.id,
                  child: Text(b.name),
                ),
            ],
            readOnly: readOnly,
          ),
        ),
      ],
    );
  }
}

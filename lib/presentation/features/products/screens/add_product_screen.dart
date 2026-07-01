import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../data/models/product/product_model.dart';
import '../../../../data/models/product/category_model.dart';
import '../../../../data/models/product/brand_model.dart';
import '../../../../data/repositories/product_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/permission_provider.dart';
import '../providers/product_provider.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _PendingImage {
  final Uint8List bytes;
  final String fileExtension;
  final String contentType;

  const _PendingImage({
    required this.bytes,
    required this.fileExtension,
    required this.contentType,
  });
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  late final FormGroup form;
  final _uuid = const Uuid();
  final _picker = ImagePicker();
  final List<_PendingImage> _pendingImages = [];
  bool _uploading = false;

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
      'minStock': FormControl<int>(value: 5, validators: [Validators.number]),
      'maxStock': FormControl<int>(validators: [Validators.number]),
      'reorderPoint': FormControl<int>(validators: [Validators.number]),
      'isActive': FormControl<bool>(value: true),
      'hasWarranty': FormControl<bool>(value: false),
      'warrantyMonths':
          FormControl<int>(value: 0, validators: [Validators.number]),
    });
  }

  Future<void> _pickImage() async {
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

    if (!mounted) return;
    setState(() {
      _pendingImages.add(_PendingImage(
        bytes: bytes,
        fileExtension: ext,
        contentType: contentType,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final companyId = ref.watch(authProvider).companyId;
    final canEditProducts = ref.watch(canEditProductsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final brandsAsync = ref.watch(brandsProvider);

    if (!canEditProducts) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Product')),
        body: const AppBody(
          child: EmptyState(
            title: 'No access',
            message: 'You do not have permission to add products.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: AppBody(
        child: ReactiveForm(
          formGroup: form,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              if (companyId == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'No company found for this user. Please register as admin or use an invite code.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              // Media / images section
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
                    onPressed: _uploading ? null : _pickImage,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('Add image'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_pendingImages.isEmpty)
                const Text('No images selected.')
              else
                SizedBox(
                  height: 92,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _pendingImages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final pending = _pendingImages[index];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Image.memory(
                                pending.bytes,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: InkWell(
                              onTap: _uploading
                                  ? null
                                  : () {
                                      setState(() {
                                        _pendingImages.removeAt(index);
                                      });
                                    },
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
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
              ),
              const SizedBox(height: 12),
              ReactiveTextField<String>(
                formControlName: 'name',
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Leather Handbag',
                ),
              ),
              const SizedBox(height: 12),
              ReactiveTextField<String>(
                formControlName: 'description',
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
              const SizedBox(height: 12),
              _TaxonomySelectors(
                categoriesAsync: categoriesAsync,
                brandsAsync: brandsAsync,
              ),
              const SizedBox(height: 12),
              ReactiveTextField<String>(
                formControlName: 'bagType',
                decoration: const InputDecoration(
                  labelText: 'Bag type',
                  hintText: 'Backpack / Handbag / Tote ...',
                ),
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
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ReactiveTextField<String>(
                      formControlName: 'color',
                      decoration: const InputDecoration(
                        labelText: 'Color (optional)',
                      ),
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
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ReactiveTextField<String>(
                      formControlName: 'dimensions',
                      decoration: const InputDecoration(
                        labelText: 'Dimensions (optional)',
                      ),
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
              ),
              const SizedBox(height: 12),
              ReactiveTextField<String>(
                formControlName: 'barcode',
                decoration: const InputDecoration(
                  labelText: 'Barcode (optional)',
                ),
              ),
              const SizedBox(height: 12),
              ReactiveTextField<double>(
                formControlName: 'unitCost',
                keyboardType: TextInputType.number,
                valueAccessor: DoubleValueAccessor(),
                decoration: const InputDecoration(
                  labelText: 'Unit cost',
                ),
              ),
              const SizedBox(height: 12),
              ReactiveTextField<double>(
                formControlName: 'sellingPrice',
                keyboardType: TextInputType.number,
                valueAccessor: DoubleValueAccessor(),
                decoration: const InputDecoration(
                  labelText: 'Selling price',
                ),
              ),
              const SizedBox(height: 12),
              ReactiveTextField<double>(
                formControlName: 'wholesalePrice',
                keyboardType: TextInputType.number,
                valueAccessor: DoubleValueAccessor(),
                decoration: const InputDecoration(
                  labelText: 'Wholesale price (optional)',
                ),
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
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: companyId == null
                      ? null
                      : () async {
                          form.markAllAsTouched();
                          if (!form.valid) return;

                          final sku = form.control('sku').value as String;
                          final name = form.control('name').value as String;
                          final description =
                              (form.control('description').value as String?) ??
                                  '';
                          final bagType =
                              form.control('bagType').value as String?;
                          final material =
                              form.control('material').value as String?;
                          final color = form.control('color').value as String?;
                          final size = form.control('size').value as String?;
                          final dimensions =
                              form.control('dimensions').value as String?;
                          final weightGrams =
                              form.control('weightGrams').value as double?;
                          final barcode =
                              form.control('barcode').value as String?;
                          final categoryId =
                              form.control('categoryId').value as String?;
                          final brandId =
                              form.control('brandId').value as String?;
                          final unitCost =
                              form.control('unitCost').value as double;
                          final sellingPrice =
                              form.control('sellingPrice').value as double;
                          final wholesalePrice =
                              form.control('wholesalePrice').value as double?;
                          final minStock =
                              (form.control('minStock').value as int?) ?? 0;
                          final maxStock =
                              form.control('maxStock').value as int?;
                          final reorderPoint =
                              form.control('reorderPoint').value as int?;
                          final isActive =
                              (form.control('isActive').value as bool?) ?? true;
                          final hasWarranty =
                              (form.control('hasWarranty').value as bool?) ??
                                  false;
                          final warrantyMonths =
                              (form.control('warrantyMonths').value as int?) ??
                                  0;

                          final product = ProductModel(
                            id: _uuid.v4(),
                            companyId: companyId,
                            sku: sku,
                            name: name,
                            description: description,
                            categoryId: categoryId,
                            brandId: brandId,
                            bagType: (bagType?.trim().isEmpty ?? true)
                                ? null
                                : bagType,
                            material: (material?.trim().isEmpty ?? true)
                                ? null
                                : material,
                            color:
                                (color?.trim().isEmpty ?? true) ? null : color,
                            size: (size?.trim().isEmpty ?? true) ? null : size,
                            dimensions: (dimensions?.trim().isEmpty ?? true)
                                ? null
                                : dimensions,
                            weightGrams: weightGrams,
                            barcode: (barcode?.trim().isEmpty ?? true)
                                ? null
                                : barcode,
                            unitCost: unitCost,
                            sellingPrice: sellingPrice,
                            wholesalePrice: wholesalePrice,
                            minStock: minStock <= 0 ? 0 : minStock,
                            maxStock: maxStock,
                            reorderPoint: reorderPoint,
                            isActive: isActive,
                            hasWarranty: hasWarranty,
                            warrantyMonths: hasWarranty
                                ? (warrantyMonths <= 0 ? 0 : warrantyMonths)
                                : 0,
                          );

                          if (!mounted) return;
                          setState(() => _uploading = true);

                          try {
                            final id = await ref
                                .read(productRepositoryProvider)
                                .createProduct(product);

                            // Upload any pending images
                            if (_pendingImages.isNotEmpty) {
                              for (final pending in _pendingImages) {
                                final uploadProduct = ProductModel(
                                  id: id,
                                  companyId: companyId,
                                  sku: sku,
                                  name: name,
                                  description: description,
                                  categoryId: categoryId,
                                  brandId: brandId,
                                  bagType: (bagType?.trim().isEmpty ?? true)
                                      ? null
                                      : bagType,
                                  material: (material?.trim().isEmpty ?? true)
                                      ? null
                                      : material,
                                  color: (color?.trim().isEmpty ?? true)
                                      ? null
                                      : color,
                                  size: (size?.trim().isEmpty ?? true)
                                      ? null
                                      : size,
                                  dimensions: (dimensions?.trim().isEmpty ??
                                          true)
                                      ? null
                                      : dimensions,
                                  weightGrams: weightGrams,
                                  barcode: (barcode?.trim().isEmpty ?? true)
                                      ? null
                                      : barcode,
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
                                );

                                await ref
                                    .read(productRepositoryProvider)
                                    .uploadAndAttachProductImage(
                                      product: uploadProduct,
                                      bytes: pending.bytes,
                                      fileExtension: pending.fileExtension,
                                      contentType: pending.contentType,
                                    );
                              }
                            }

                            ref.invalidate(productsStreamProvider);

                            if (!context.mounted) return;
                            context.go('/products/$id');
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          } finally {
                            if (mounted) setState(() => _uploading = false);
                          }
                        },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaxonomySelectors extends StatelessWidget {
  final AsyncValue<List<CategoryModel>> categoriesAsync;
  final AsyncValue<List<BrandModel>> brandsAsync;

  const _TaxonomySelectors({
    required this.categoriesAsync,
    required this.brandsAsync,
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
          ),
        ),
      ],
    );
  }
}

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/product/product_model.dart';
import '../models/product/category_model.dart';
import '../models/product/brand_model.dart';
import '../../services/supabase_service.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(supabaseServiceProvider));
});

class ProductRepository {
  final SupabaseService _supabase;
  final Uuid _uuid = const Uuid();

  ProductRepository(this._supabase);

  Future<List<ProductModel>> getProducts({String? companyId}) async {
    var query = _supabase.client.from('products').select('*');

    if (companyId != null) {
      query = query.eq('company_id', companyId);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map((json) => ProductModel.fromJson(json))
        .toList();
  }

  Future<ProductModel?> getProductById(String id) async {
    final response = await _supabase.client
        .from('products')
        .select('*')
        .eq('id', id)
        .single();
    return ProductModel.fromJson(response);
  }

  Future<ProductModel?> getProductByBarcode(String barcode) async {
    final response = await _supabase.client
        .from('products')
        .select('*')
        .eq('barcode', barcode)
        .maybeSingle();

    if (response == null) return null;
    return ProductModel.fromJson(response);
  }

  Future<ProductModel?> getProductBySku(String sku) async {
    final response = await _supabase.client
        .from('products')
        .select('*')
        .eq('sku', sku)
        .maybeSingle();

    if (response == null) return null;
    return ProductModel.fromJson(response);
  }

  Future<String> createProduct(ProductModel product) async {
    final response = await _supabase.client
        .from('products')
        .insert(product.toJson())
        .select('id')
        .single();

    return response['id'];
  }

  Future<void> updateProduct(String id, ProductModel product) async {
    // For updates, include nullable fields explicitly so the UI can clear them.
    final json = Map<String, dynamic>.from(product.toJson());
    json.remove('id');
    json.remove('company_id');
    json.remove('created_at');

    json['category_id'] = product.categoryId;
    json['brand_id'] = product.brandId;
    json['bag_type'] = product.bagType;
    json['material'] = product.material;
    json['color'] = product.color;
    json['size'] = product.size;
    json['dimensions'] = product.dimensions;
    json['weight_grams'] = product.weightGrams;
    json['barcode'] = product.barcode;
    json['qr_code'] = product.qrCode;
    json['wholesale_price'] = product.wholesalePrice;
    json['max_stock'] = product.maxStock;
    json['reorder_point'] = product.reorderPoint;
    json['image_urls'] = product.imageUrls;
    json['video_url'] = product.videoUrl;

    await _supabase.client.from('products').update(json).eq('id', id);
  }

  Future<void> deleteProduct(String id) async {
    await _supabase.client.from('products').delete().eq('id', id);
  }

  Future<List<CategoryModel>> getCategories({String? companyId}) async {
    var query = _supabase.client.from('categories').select('*');

    if (companyId != null) {
      query = query.eq('company_id', companyId);
    }

    final response = await query.order('name');

    return (response as List)
        .map((json) => CategoryModel.fromJson(json))
        .toList();
  }

  Future<String> createCategory(CategoryModel category) async {
    final response = await _supabase.client
        .from('categories')
        .insert(category.toJson())
        .select('id')
        .single();

    return response['id'];
  }

  Future<void> updateCategory(CategoryModel category) async {
    if (category.id == null) throw Exception('Category id is required');
    final json = Map<String, dynamic>.from(category.toJson());
    json.remove('id');
    json.remove('company_id');
    json.remove('created_at');
    await _supabase.client
        .from('categories')
        .update(json)
        .eq('id', category.id!);
  }

  Future<void> deleteCategory(String id) async {
    await _supabase.client.from('categories').delete().eq('id', id);
  }

  Future<List<BrandModel>> getBrands({String? companyId}) async {
    var query = _supabase.client.from('brands').select('*');

    if (companyId != null) {
      query = query.eq('company_id', companyId);
    }

    final response = await query.order('name');
    return (response as List)
        .map((json) => BrandModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<String> createBrand(BrandModel brand) async {
    final response = await _supabase.client
        .from('brands')
        .insert(brand.toJson())
        .select('id')
        .single();

    return response['id'];
  }

  Future<void> updateBrand(BrandModel brand) async {
    if (brand.id == null) throw Exception('Brand id is required');
    final json = Map<String, dynamic>.from(brand.toJson());
    json.remove('id');
    json.remove('company_id');
    json.remove('created_at');
    await _supabase.client.from('brands').update(json).eq('id', brand.id!);
  }

  Future<void> deleteBrand(String id) async {
    await _supabase.client.from('brands').delete().eq('id', id);
  }

  Future<String> uploadAndAttachProductImage({
    required ProductModel product,
    required Uint8List bytes,
    required String fileExtension,
    String? contentType,
  }) async {
    final productId = product.id;
    final companyId = product.companyId;
    if (productId == null) throw Exception('Product id is required');
    if (companyId == null) throw Exception('Company id is required');

    final ext = fileExtension.trim().replaceAll('.', '').toLowerCase();
    final path = '$companyId/products/$productId/${_uuid.v4()}.$ext';

    await _supabase.client.storage.from('bag-images').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: contentType,
          ),
        );

    final url = _supabase.client.storage.from('bag-images').getPublicUrl(path);

    final current = product.imageUrls ?? const <String>[];
    final next = [...current, url];
    await _supabase.client.from('products').update({
      'image_urls': next,
      'updated_at': DateTime.now().toUtc().toIso8601String()
    }).eq('id', productId);

    return url;
  }

  Stream<List<ProductModel>> watchProducts({String? companyId}) {
    final stream = _supabase.client
        .from('products')
        .stream(primaryKey: ['id']).order('created_at', ascending: false);

    return stream.map((data) {
      final list = (data as List)
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
      if (companyId == null) return list;
      return list.where((p) => p.companyId == companyId).toList();
    });
  }

  Future<List<ProductModel>> searchProducts(String query,
      {String? companyId}) async {
    var searchQuery = _supabase.client
        .from('products')
        .select('*')
        .or('name.ilike.%$query%,sku.ilike.%$query%,barcode.ilike.%$query%');

    if (companyId != null) {
      searchQuery = searchQuery.eq('company_id', companyId);
    }

    final response = await searchQuery.limit(50);

    return (response as List)
        .map((json) => ProductModel.fromJson(json))
        .toList();
  }

  Future<DemoCatalogSeedResult> seedDemoCatalog({
    required String companyId,
  }) async {
    final now = DateTime.now().toUtc();
    final warehouse = await _ensureWarehouse(companyId, now);
    final categories = await _ensureCategories(companyId, now);
    final brands = await _ensureBrands(companyId, now);
    final existingSkus = await _loadExistingSkus(companyId);

    var productsCreated = 0;
    var movementsCreated = 0;

    for (final item in _demoCatalog) {
      if (existingSkus.contains(item.sku.toUpperCase())) {
        continue;
      }

      final product = ProductModel(
        companyId: companyId,
        sku: item.sku,
        name: item.name,
        description: item.description,
        categoryId: categories.ids[item.category],
        brandId: brands.ids[item.brand],
        bagType: item.bagType,
        material: item.material,
        color: item.color,
        size: item.size,
        dimensions: item.dimensions,
        weightGrams: item.weightGrams,
        barcode: 'BAR-${item.sku}',
        unitCost: item.unitCost,
        sellingPrice: item.sellingPrice,
        wholesalePrice: item.wholesalePrice,
        minStock: item.minStock,
        maxStock: item.minStock * 5,
        reorderPoint: item.minStock,
        isActive: true,
        hasWarranty: item.hasWarranty,
        warrantyMonths: item.warrantyMonths,
        createdAt: now,
        updatedAt: now,
      );

      final insertedProduct = await _supabase.client
          .from('products')
          .insert(product.toJson())
          .select('id')
          .single();

      final productId = insertedProduct['id'] as String;

      await _supabase.client.from('stock_movements').insert({
        'company_id': companyId,
        'product_id': productId,
        'warehouse_id': warehouse.id,
        'movement_type': 'PURCHASE',
        'quantity_change': item.initialStock,
        'quantity_before': 0,
        'reference_type': 'DEMO_SEED',
        'reference_id': productId,
        'notes': 'Seeded catalog product',
      });

      productsCreated += 1;
      movementsCreated += 1;
    }

    return DemoCatalogSeedResult(
      categoriesCreated: categories.createdCount,
      brandsCreated: brands.createdCount,
      productsCreated: productsCreated,
      stockMovementsCreated: movementsCreated,
      warehouseCreated: warehouse.created,
    );
  }

  Future<_SeededCategories> _ensureCategories(
    String companyId,
    DateTime now,
  ) async {
    final existing = await _supabase.client
        .from('categories')
        .select('id, name')
        .eq('company_id', companyId);

    final ids = <String, String>{};
    final existingByName = <String, String>{
      for (final row in existing as List)
        (row['name'] as String).toLowerCase(): row['id'] as String,
    };

    var createdCount = 0;
    for (final category in _demoCategories) {
      final key = category.name.toLowerCase();
      final foundId = existingByName[key];
      if (foundId != null) {
        ids[category.name] = foundId;
        continue;
      }

      final inserted = await _supabase.client
          .from('categories')
          .insert({
            'company_id': companyId,
            'name': category.name,
            'description': category.description,
            'icon': category.icon,
            'color': category.color,
            'created_at': now.toIso8601String(),
          })
          .select('id, name')
          .single();

      ids[inserted['name'] as String] = inserted['id'] as String;
      createdCount += 1;
    }

    return _SeededCategories(ids: ids, createdCount: createdCount);
  }

  Future<_SeededBrands> _ensureBrands(
    String companyId,
    DateTime now,
  ) async {
    final existing = await _supabase.client
        .from('brands')
        .select('id, name')
        .eq('company_id', companyId);

    final ids = <String, String>{};
    final existingByName = <String, String>{
      for (final row in existing as List)
        (row['name'] as String).toLowerCase(): row['id'] as String,
    };

    var createdCount = 0;
    for (final brand in _demoBrands) {
      final key = brand.name.toLowerCase();
      final foundId = existingByName[key];
      if (foundId != null) {
        ids[brand.name] = foundId;
        continue;
      }

      final inserted = await _supabase.client
          .from('brands')
          .insert({
            'company_id': companyId,
            'name': brand.name,
            'website': brand.website,
            'created_at': now.toIso8601String(),
          })
          .select('id, name')
          .single();

      ids[inserted['name'] as String] = inserted['id'] as String;
      createdCount += 1;
    }

    return _SeededBrands(ids: ids, createdCount: createdCount);
  }

  Future<_SeededWarehouse> _ensureWarehouse(
    String companyId,
    DateTime now,
  ) async {
    final existing = await _supabase.client
        .from('warehouses')
        .select('id')
        .eq('company_id', companyId)
        .eq('is_default', true)
        .maybeSingle();

    if (existing != null) {
      return _SeededWarehouse(
        id: existing['id'] as String,
        created: false,
      );
    }

    final inserted = await _supabase.client
        .from('warehouses')
        .insert({
          'company_id': companyId,
          'name': 'Main Store',
          'type': 'SHOWROOM',
          'is_default': true,
          'created_at': now.toIso8601String(),
        })
        .select('id')
        .single();

    return _SeededWarehouse(
      id: inserted['id'] as String,
      created: true,
    );
  }

  Future<Set<String>> _loadExistingSkus(String companyId) async {
    final rows = await _supabase.client
        .from('products')
        .select('sku')
        .eq('company_id', companyId);

    return (rows as List)
        .map((row) => (row['sku'] as String).toUpperCase())
        .toSet();
  }

  static const List<_DemoCategory> _demoCategories = [
    _DemoCategory(
      'Backpacks',
      'School, laptop, and travel backpacks',
      'backpack',
      '#4CAF50',
    ),
    _DemoCategory(
      'Handbags',
      'Daily handbags and premium purses',
      'handbag',
      '#FF9800',
    ),
    _DemoCategory(
      'Tote Bags',
      'Lightweight carry-all tote bags',
      'shopping',
      '#2196F3',
    ),
    _DemoCategory(
      'Wallets',
      'Slim wallets and card holders',
      'wallet',
      '#9C27B0',
    ),
    _DemoCategory(
      'Luggage',
      'Cabin and check-in travel luggage',
      'luggage',
      '#FF5722',
    ),
    _DemoCategory(
      'Messenger Bags',
      'Cross-body and work messenger bags',
      'bag_personal',
      '#795548',
    ),
    _DemoCategory(
      'Duffle Bags',
      'Gym and weekend duffle bags',
      'sports',
      '#00BCD4',
    ),
    _DemoCategory(
      'Clutches',
      'Evening and party clutches',
      'diamond',
      '#E91E63',
    ),
  ];

  static const List<_DemoBrand> _demoBrands = [
    _DemoBrand('Urban Nomad', 'https://urbannomad.example'),
    _DemoBrand('LeatherLane', 'https://leatherlane.example'),
    _DemoBrand('MetroCarry', 'https://metrocarry.example'),
    _DemoBrand('VoyagePro', 'https://voyagepro.example'),
    _DemoBrand('SwiftStyle', 'https://swiftstyle.example'),
  ];

  static const List<_DemoCatalogItem> _demoCatalog = [
    // ===== Backpacks (5 items) =====
    _DemoCatalogItem(
      sku: 'BAG-BPK-001',
      name: 'Campus Pro Backpack',
      description: 'Durable daily backpack with padded laptop sleeve and multiple compartments. Perfect for school and college students in Bangladesh.',
      category: 'Backpacks',
      brand: 'Urban Nomad',
      bagType: 'Backpack',
      material: 'Polyester',
      color: 'Black',
      size: 'Medium',
      dimensions: '18 x 12 x 7 in',
      weightGrams: 920,
      unitCost: 650,
      sellingPrice: 1290,
      wholesalePrice: 990,
      minStock: 5,
      initialStock: 25,
      hasWarranty: true,
      warrantyMonths: 6,
    ),
    _DemoCatalogItem(
      sku: 'BAG-BPK-002',
      name: 'Transit Laptop Backpack',
      description: 'Slim professional backpack for commute and office use. Water-resistant nylon with padded laptop compartment up to 15.6".',
      category: 'Backpacks',
      brand: 'MetroCarry',
      bagType: 'Backpack',
      material: 'Nylon',
      color: 'Navy Blue',
      size: 'Large',
      dimensions: '19 x 13 x 8 in',
      weightGrams: 1050,
      unitCost: 850,
      sellingPrice: 1690,
      wholesalePrice: 1290,
      minStock: 4,
      initialStock: 20,
      hasWarranty: true,
      warrantyMonths: 12,
    ),
    _DemoCatalogItem(
      sku: 'BAG-BPK-003',
      name: 'Explorer Anti-Theft Backpack',
      description: 'Travel-safe backpack with hidden zip pockets and USB charging port. Ideal for Dhaka commuters and travelers.',
      category: 'Backpacks',
      brand: 'VoyagePro',
      bagType: 'Backpack',
      material: 'Oxford Fabric',
      color: 'Charcoal Grey',
      size: 'Large',
      dimensions: '20 x 13 x 8 in',
      weightGrams: 1120,
      unitCost: 950,
      sellingPrice: 1890,
      wholesalePrice: 1450,
      minStock: 4,
      initialStock: 18,
      hasWarranty: true,
      warrantyMonths: 12,
    ),
    _DemoCatalogItem(
      sku: 'BAG-BPK-004',
      name: 'Student Classic Backpack',
      description: 'Affordable lightweight backpack for school-going children. Padded shoulder straps and water bottle pocket.',
      category: 'Backpacks',
      brand: 'Urban Nomad',
      bagType: 'Backpack',
      material: 'Polyester',
      color: 'Royal Blue',
      size: 'Medium',
      dimensions: '17 x 11 x 6 in',
      weightGrams: 680,
      unitCost: 380,
      sellingPrice: 790,
      wholesalePrice: 590,
      minStock: 8,
      initialStock: 35,
    ),
    _DemoCatalogItem(
      sku: 'BAG-BPK-005',
      name: 'Premium Leather Backpack',
      description: 'Genuine leather backpack for executives and professionals. Stylish and durable with brass zippers.',
      category: 'Backpacks',
      brand: 'LeatherLane',
      bagType: 'Backpack',
      material: 'Genuine Leather',
      color: 'Dark Brown',
      size: 'Medium',
      dimensions: '16 x 12 x 6 in',
      weightGrams: 1350,
      unitCost: 1850,
      sellingPrice: 3590,
      wholesalePrice: 2790,
      minStock: 3,
      initialStock: 10,
      hasWarranty: true,
      warrantyMonths: 12,
    ),

    // ===== Handbags (4 items) =====
    _DemoCatalogItem(
      sku: 'BAG-HND-001',
      name: 'Classic Leather Handbag',
      description: 'Elegant handbag with gold-tone hardware and secure zip closure. Roomy enough for daily essentials with style.',
      category: 'Handbags',
      brand: 'LeatherLane',
      bagType: 'Handbag',
      material: 'Genuine Leather',
      color: 'Tan',
      size: 'Medium',
      dimensions: '13 x 9 x 5 in',
      weightGrams: 780,
      unitCost: 1200,
      sellingPrice: 2590,
      wholesalePrice: 1890,
      minStock: 4,
      initialStock: 15,
      hasWarranty: true,
      warrantyMonths: 6,
    ),
    _DemoCatalogItem(
      sku: 'BAG-HND-002',
      name: 'Designer Tote Handbag',
      description: 'Fashion-forward handbag with trendy design and ample storage. Perfect for office and outings.',
      category: 'Handbags',
      brand: 'SwiftStyle',
      bagType: 'Handbag',
      material: 'PU Leather',
      color: 'Blush Pink',
      size: 'Large',
      dimensions: '15 x 10 x 6 in',
      weightGrams: 650,
      unitCost: 850,
      sellingPrice: 1790,
      wholesalePrice: 1350,
      minStock: 4,
      initialStock: 20,
    ),
    _DemoCatalogItem(
      sku: 'BAG-HND-003',
      name: 'Embroidered Shoulder Bag',
      description: 'Beautiful hand-embroidered shoulder bag with traditional Bangladeshi motifs. Unique and eye-catching.',
      category: 'Handbags',
      brand: 'SwiftStyle',
      bagType: 'Shoulder Bag',
      material: 'Cotton Blend',
      color: 'Red & Gold',
      size: 'Medium',
      dimensions: '12 x 8 x 4 in',
      weightGrams: 520,
      unitCost: 550,
      sellingPrice: 1190,
      wholesalePrice: 890,
      minStock: 5,
      initialStock: 22,
    ),
    _DemoCatalogItem(
      sku: 'BAG-HND-004',
      name: 'Mini Crossbody Handbag',
      description: 'Compact crossbody bag for phones, wallet, and makeup. Trendy everyday companion.',
      category: 'Handbags',
      brand: 'Urban Nomad',
      bagType: 'Crossbody',
      material: 'Faux Leather',
      color: 'White',
      size: 'Small',
      dimensions: '9 x 5 x 3 in',
      weightGrams: 380,
      unitCost: 420,
      sellingPrice: 890,
      wholesalePrice: 650,
      minStock: 6,
      initialStock: 30,
    ),

    // ===== Tote Bags (4 items) =====
    _DemoCatalogItem(
      sku: 'BAG-TOT-001',
      name: 'Daily Market Tote',
      description: 'Spacious reusable tote bag for everyday shopping and carrying essentials. Lightweight and foldable.',
      category: 'Tote Bags',
      brand: 'Urban Nomad',
      bagType: 'Tote',
      material: 'Canvas',
      color: 'Beige',
      size: 'Large',
      dimensions: '16 x 14 x 6 in',
      weightGrams: 540,
      unitCost: 280,
      sellingPrice: 590,
      wholesalePrice: 420,
      minStock: 6,
      initialStock: 40,
    ),
    _DemoCatalogItem(
      sku: 'BAG-TOT-002',
      name: 'Premium Structured Tote',
      description: 'Structured tote with reinforced handles and inner pockets. Ideal for work and meetings.',
      category: 'Tote Bags',
      brand: 'LeatherLane',
      bagType: 'Tote',
      material: 'PU Leather',
      color: 'Brown',
      size: 'Large',
      dimensions: '17 x 13 x 6 in',
      weightGrams: 690,
      unitCost: 680,
      sellingPrice: 1450,
      wholesalePrice: 1090,
      minStock: 5,
      initialStock: 18,
    ),
    _DemoCatalogItem(
      sku: 'BAG-TOT-003',
      name: 'Monogram Shopper Tote',
      description: 'Fashion tote with stylish monogram print and durable reinforced stitching.',
      category: 'Tote Bags',
      brand: 'LeatherLane',
      bagType: 'Tote',
      material: 'Canvas',
      color: 'Cream',
      size: 'Large',
      dimensions: '17 x 15 x 6 in',
      weightGrams: 630,
      unitCost: 520,
      sellingPrice: 1090,
      wholesalePrice: 790,
      minStock: 5,
      initialStock: 22,
    ),
    _DemoCatalogItem(
      sku: 'BAG-TOT-004',
      name: 'Jute Eco Shopper',
      description: 'Eco-friendly jute tote bag with printed design. Perfect for grocery runs and beach days.',
      category: 'Tote Bags',
      brand: 'SwiftStyle',
      bagType: 'Tote',
      material: 'Jute',
      color: 'Natural',
      size: 'Large',
      dimensions: '15 x 13 x 5 in',
      weightGrams: 420,
      unitCost: 180,
      sellingPrice: 390,
      wholesalePrice: 280,
      minStock: 10,
      initialStock: 50,
    ),

    // ===== Wallets (4 items) =====
    _DemoCatalogItem(
      sku: 'BAG-WLT-001',
      name: 'Slim RFID Wallet',
      description: 'Compact wallet with RFID blocking technology. Holds cards and cash securely.',
      category: 'Wallets',
      brand: 'MetroCarry',
      bagType: 'Wallet',
      material: 'Leather',
      color: 'Black',
      size: 'Small',
      dimensions: '4.5 x 3.5 x 0.5 in',
      weightGrams: 120,
      unitCost: 280,
      sellingPrice: 590,
      wholesalePrice: 420,
      minStock: 8,
      initialStock: 45,
      hasWarranty: true,
      warrantyMonths: 3,
    ),
    _DemoCatalogItem(
      sku: 'BAG-WLT-002',
      name: 'Premium Bi-Fold Wallet',
      description: 'Everyday wallet with multiple card slots, ID window, and a coin pocket. Durable stitching.',
      category: 'Wallets',
      brand: 'LeatherLane',
      bagType: 'Wallet',
      material: 'Leather',
      color: 'Dark Brown',
      size: 'Small',
      dimensions: '4.7 x 3.7 x 0.6 in',
      weightGrams: 140,
      unitCost: 350,
      sellingPrice: 750,
      wholesalePrice: 550,
      minStock: 8,
      initialStock: 38,
      hasWarranty: true,
      warrantyMonths: 6,
    ),
    _DemoCatalogItem(
      sku: 'BAG-WLT-003',
      name: 'Zipper Coin Wallet',
      description: 'Practical zip-around wallet with separate coin compartment. Perfect for Bangladeshi market goers.',
      category: 'Wallets',
      brand: 'Urban Nomad',
      bagType: 'Wallet',
      material: 'Faux Leather',
      color: 'Navy',
      size: 'Small',
      dimensions: '5 x 3.5 x 1 in',
      weightGrams: 160,
      unitCost: 220,
      sellingPrice: 490,
      wholesalePrice: 350,
      minStock: 8,
      initialStock: 42,
    ),
    _DemoCatalogItem(
      sku: 'BAG-WLT-004',
      name: 'Travel Passport Wallet',
      description: 'Organizer wallet for passport, boarding pass, cards, and currency. Essential for travelers.',
      category: 'Wallets',
      brand: 'VoyagePro',
      bagType: 'Wallet',
      material: 'Nylon',
      color: 'Grey',
      size: 'Medium',
      dimensions: '8 x 5 x 1 in',
      weightGrams: 190,
      unitCost: 380,
      sellingPrice: 790,
      wholesalePrice: 590,
      minStock: 5,
      initialStock: 25,
    ),

    // ===== Messenger & Crossbody (4 items) =====
    _DemoCatalogItem(
      sku: 'BAG-MSG-001',
      name: 'Urban Messenger Bag',
      description: 'Cross-body bag for laptop and documents. Multiple pockets for organization.',
      category: 'Messenger Bags',
      brand: 'MetroCarry',
      bagType: 'Messenger',
      material: 'Waxed Canvas',
      color: 'Olive Green',
      size: 'Medium',
      dimensions: '16 x 12 x 5 in',
      weightGrams: 880,
      unitCost: 720,
      sellingPrice: 1490,
      wholesalePrice: 1090,
      minStock: 5,
      initialStock: 16,
      hasWarranty: true,
      warrantyMonths: 6,
    ),
    _DemoCatalogItem(
      sku: 'BAG-MSG-002',
      name: 'Canvas Courier Bag',
      description: 'Casual messenger bag with adjustable strap and front buckle closure.',
      category: 'Messenger Bags',
      brand: 'SwiftStyle',
      bagType: 'Messenger',
      material: 'Canvas',
      color: 'Khaki',
      size: 'Medium',
      dimensions: '15 x 11 x 5 in',
      weightGrams: 760,
      unitCost: 520,
      sellingPrice: 1090,
      wholesalePrice: 790,
      minStock: 5,
      initialStock: 18,
    ),
    _DemoCatalogItem(
      sku: 'BAG-CBR-001',
      name: 'Crossbody Sling Bag',
      description: 'Compact sling bag for daily essentials. Trendy and practical for Dhaka streets.',
      category: 'Messenger Bags',
      brand: 'SwiftStyle',
      bagType: 'Crossbody',
      material: 'Nylon',
      color: 'Forest Green',
      size: 'Small',
      dimensions: '10 x 8 x 3 in',
      weightGrams: 410,
      unitCost: 320,
      sellingPrice: 690,
      wholesalePrice: 490,
      minStock: 6,
      initialStock: 28,
    ),
    _DemoCatalogItem(
      sku: 'BAG-CBR-002',
      name: 'Mini Phone Sling',
      description: 'Hands-free mini pouch for phone, cards, and keys. Ultra-lightweight.',
      category: 'Messenger Bags',
      brand: 'Urban Nomad',
      bagType: 'Pouch',
      material: 'Faux Leather',
      color: 'Rose Gold',
      size: 'Small',
      dimensions: '7 x 4 x 1 in',
      weightGrams: 180,
      unitCost: 180,
      sellingPrice: 390,
      wholesalePrice: 280,
      minStock: 8,
      initialStock: 35,
    ),

    // ===== Duffle Bags (3 items) =====
    _DemoCatalogItem(
      sku: 'BAG-DUF-001',
      name: 'Weekend Duffle Bag',
      description: 'Roomy duffle for short trips and weekend getaways. Water-resistant base.',
      category: 'Duffle Bags',
      brand: 'VoyagePro',
      bagType: 'Duffle',
      material: 'Nylon',
      color: 'Charcoal',
      size: 'Large',
      dimensions: '22 x 11 x 10 in',
      weightGrams: 1020,
      unitCost: 820,
      sellingPrice: 1690,
      wholesalePrice: 1250,
      minStock: 4,
      initialStock: 14,
      hasWarranty: true,
      warrantyMonths: 6,
    ),
    _DemoCatalogItem(
      sku: 'BAG-DUF-002',
      name: 'Gym Sport Duffle',
      description: 'Lightweight sports bag with ventilated shoe compartment and wet pocket.',
      category: 'Duffle Bags',
      brand: 'Urban Nomad',
      bagType: 'Duffle',
      material: 'Polyester',
      color: 'Red',
      size: 'Medium',
      dimensions: '20 x 10 x 10 in',
      weightGrams: 890,
      unitCost: 580,
      sellingPrice: 1190,
      wholesalePrice: 890,
      minStock: 4,
      initialStock: 20,
    ),
    _DemoCatalogItem(
      sku: 'BAG-DUF-003',
      name: 'Canvas Holdall Duffle',
      description: 'Vintage-style canvas holdall with leather trim. Perfect weekend companion.',
      category: 'Duffle Bags',
      brand: 'LeatherLane',
      bagType: 'Duffle',
      material: 'Canvas',
      color: 'Army Green',
      size: 'Large',
      dimensions: '24 x 12 x 11 in',
      weightGrams: 1150,
      unitCost: 920,
      sellingPrice: 1890,
      wholesalePrice: 1390,
      minStock: 3,
      initialStock: 12,
    ),

    // ===== Luggage (3 items) =====
    _DemoCatalogItem(
      sku: 'BAG-LUG-001',
      name: 'Cabin Spinner Luggage',
      description: 'Carry-on luggage with smooth 360-degree spinner wheels and TSA lock. Fits airline cabin size.',
      category: 'Luggage',
      brand: 'VoyagePro',
      bagType: 'Luggage',
      material: 'ABS',
      color: 'Silver',
      size: 'Cabin',
      dimensions: '21 x 14 x 9 in',
      weightGrams: 2750,
      unitCost: 1650,
      sellingPrice: 3290,
      wholesalePrice: 2490,
      minStock: 3,
      initialStock: 12,
      hasWarranty: true,
      warrantyMonths: 24,
    ),
    _DemoCatalogItem(
      sku: 'BAG-LUG-002',
      name: 'Check-In Hard Shell Case',
      description: 'Large polycarbonate luggage for long trips. Scratch-resistant and lightweight.',
      category: 'Luggage',
      brand: 'MetroCarry',
      bagType: 'Luggage',
      material: 'Polycarbonate',
      color: 'Midnight Blue',
      size: 'Large',
      dimensions: '28 x 19 x 12 in',
      weightGrams: 3850,
      unitCost: 2200,
      sellingPrice: 4590,
      wholesalePrice: 3490,
      minStock: 3,
      initialStock: 10,
      hasWarranty: true,
      warrantyMonths: 24,
    ),
    _DemoCatalogItem(
      sku: 'BAG-LUG-003',
      name: 'Travel Duffle with Wheels',
      description: 'Hybrid wheeled duffle with retractable handle. Best of both worlds.',
      category: 'Luggage',
      brand: 'VoyagePro',
      bagType: 'Luggage',
      material: 'Polyester',
      color: 'Black',
      size: 'Medium',
      dimensions: '24 x 14 x 10 in',
      weightGrams: 2100,
      unitCost: 1250,
      sellingPrice: 2590,
      wholesalePrice: 1890,
      minStock: 4,
      initialStock: 15,
      hasWarranty: true,
      warrantyMonths: 12,
    ),

    // ===== Clutches (3 items) =====
    _DemoCatalogItem(
      sku: 'BAG-CLT-001',
      name: 'Evening Pearl Clutch',
      description: 'Elegant satin clutch with pearl embellishment. Perfect for weddings and parties.',
      category: 'Clutches',
      brand: 'SwiftStyle',
      bagType: 'Clutch',
      material: 'Satin',
      color: 'Pearl White',
      size: 'Small',
      dimensions: '9 x 5 x 2 in',
      weightGrams: 320,
      unitCost: 380,
      sellingPrice: 790,
      wholesalePrice: 590,
      minStock: 3,
      initialStock: 25,
    ),
    _DemoCatalogItem(
      sku: 'BAG-CLT-002',
      name: 'Beaded Embellished Clutch',
      description: 'Hand-beaded clutch with traditional Bangladeshi embroidery. Stunning piece.',
      category: 'Clutches',
      brand: 'SwiftStyle',
      bagType: 'Clutch',
      material: 'Silk',
      color: 'Gold',
      size: 'Small',
      dimensions: '10 x 5 x 2 in',
      weightGrams: 290,
      unitCost: 520,
      sellingPrice: 1090,
      wholesalePrice: 790,
      minStock: 3,
      initialStock: 18,
    ),
    _DemoCatalogItem(
      sku: 'BAG-CLT-003',
      name: 'Minimalist Leather Clutch',
      description: 'Sleek leather clutch for modern minimalists. Fits phone, cards, and lipstick.',
      category: 'Clutches',
      brand: 'LeatherLane',
      bagType: 'Clutch',
      material: 'Leather',
      color: 'Black',
      size: 'Small',
      dimensions: '8 x 4 x 1.5 in',
      weightGrams: 260,
      unitCost: 450,
      sellingPrice: 950,
      wholesalePrice: 690,
      minStock: 4,
      initialStock: 22,
    ),
  ];
}

class DemoCatalogSeedResult {
  final int categoriesCreated;
  final int brandsCreated;
  final int productsCreated;
  final int stockMovementsCreated;
  final bool warehouseCreated;

  const DemoCatalogSeedResult({
    required this.categoriesCreated,
    required this.brandsCreated,
    required this.productsCreated,
    required this.stockMovementsCreated,
    required this.warehouseCreated,
  });
}

class _SeededCategories {
  final Map<String, String> ids;
  final int createdCount;

  const _SeededCategories({required this.ids, required this.createdCount});
}

class _SeededBrands {
  final Map<String, String> ids;
  final int createdCount;

  const _SeededBrands({required this.ids, required this.createdCount});
}

class _SeededWarehouse {
  final String id;
  final bool created;

  const _SeededWarehouse({required this.id, required this.created});
}

class _DemoCategory {
  final String name;
  final String description;
  final String icon;
  final String color;

  const _DemoCategory(this.name, this.description, this.icon, this.color);
}

class _DemoBrand {
  final String name;
  final String website;

  const _DemoBrand(this.name, this.website);
}

class _DemoCatalogItem {
  final String sku;
  final String name;
  final String description;
  final String category;
  final String brand;
  final String bagType;
  final String material;
  final String color;
  final String size;
  final String dimensions;
  final double weightGrams;
  final double unitCost;
  final double sellingPrice;
  final double wholesalePrice;
  final int minStock;
  final int initialStock;
  final bool hasWarranty;
  final int warrantyMonths;

  const _DemoCatalogItem({
    required this.sku,
    required this.name,
    required this.description,
    required this.category,
    required this.brand,
    required this.bagType,
    required this.material,
    required this.color,
    required this.size,
    required this.dimensions,
    required this.weightGrams,
    required this.unitCost,
    required this.sellingPrice,
    required this.wholesalePrice,
    required this.minStock,
    required this.initialStock,
    this.hasWarranty = false,
    this.warrantyMonths = 0,
  });
}

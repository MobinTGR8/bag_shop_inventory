import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/product/brand_model.dart';
import '../data/models/product/category_model.dart';
import '../data/models/product/product_model.dart';
import '../data/repositories/customer_repository.dart';
import '../data/repositories/product_repository.dart';
import '../data/repositories/supplier_repository.dart';

final bulkDataServiceProvider = Provider<BulkDataService>((ref) {
  return BulkDataService(
    ref.watch(productRepositoryProvider),
    ref.watch(supplierRepositoryProvider),
    ref.watch(customerRepositoryProvider),
  );
});

class BulkImportResult {
  final int created;
  final int updated;
  final int skipped;
  final List<String> warnings;

  const BulkImportResult({
    required this.created,
    required this.updated,
    required this.skipped,
    required this.warnings,
  });
}

class BulkDataService {
  final ProductRepository _products;
  final SupplierRepository _suppliers;
  final CustomerRepository _customers;

  const BulkDataService(this._products, this._suppliers, this._customers);

  Future<String> exportProductsCsv({required String? companyId}) async {
    final items = await _products.getProducts(companyId: companyId);
    final categories = await _products.getCategories(companyId: companyId);
    final brands = await _products.getBrands(companyId: companyId);
    final categoryNames = <String, String>{
      for (final c in categories)
        if (c.id != null) c.id!: c.name,
    };
    final brandNames = <String, String>{
      for (final b in brands)
        if (b.id != null) b.id!: b.name,
    };

    final rows = <List<String>>[
      [
        'sku',
        'name',
        'description',
        'category',
        'brand',
        'bag_type',
        'material',
        'color',
        'size',
        'dimensions',
        'weight_grams',
        'barcode',
        'unit_cost',
        'selling_price',
        'wholesale_price',
        'min_stock',
        'max_stock',
        'reorder_point',
        'is_active',
        'has_warranty',
        'warranty_months',
      ],
      for (final item in items)
        [
          item.sku,
          item.name,
          item.description,
          _lookupCategoryName(item.categoryId, categoryNames),
          _lookupBrandName(item.brandId, brandNames),
          item.bagType ?? '',
          item.material ?? '',
          item.color ?? '',
          item.size ?? '',
          item.dimensions ?? '',
          item.weightGrams?.toString() ?? '',
          item.barcode ?? '',
          item.unitCost.toString(),
          item.sellingPrice.toString(),
          item.wholesalePrice?.toString() ?? '',
          item.minStock.toString(),
          item.maxStock?.toString() ?? '',
          item.reorderPoint?.toString() ?? '',
          item.isActive.toString(),
          item.hasWarranty.toString(),
          item.warrantyMonths.toString(),
        ],
    ];

    return _CsvCodec.encode(rows);
  }

  Future<BulkImportResult> importProductsCsv({
    required String companyId,
    required String csvText,
  }) async {
    final rows = _CsvCodec.decode(csvText);
    if (rows.isEmpty) {
      return const BulkImportResult(
          created: 0, updated: 0, skipped: 0, warnings: ['CSV is empty.']);
    }

    final headers = rows.first.map(_normalizeHeader).toList();
    final dataRows = rows.skip(1).toList();

    final categoryCache = <String, CategoryModel>{
      for (final c in await _products.getCategories(companyId: companyId))
        _normalizeHeader(c.name): c,
    };
    final brandCache = <String, BrandModel>{
      for (final b in await _products.getBrands(companyId: companyId))
        _normalizeHeader(b.name): b,
    };

    var created = 0;
    var updated = 0;
    var skipped = 0;
    final warnings = <String>[];

    for (final row in dataRows) {
      final map = _rowMap(headers, row);
      final sku = map['sku']?.trim() ?? '';
      final name = map['name']?.trim() ?? '';
      if (sku.isEmpty || name.isEmpty) {
        skipped += 1;
        warnings.add('Skipped a product row with missing sku/name.');
        continue;
      }

      final categoryId =
          await _resolveCategoryId(companyId, map['category'], categoryCache);
      final brandId =
          await _resolveBrandId(companyId, map['brand'], brandCache);

      final existing = await _products.getProductBySku(sku);
      final product = ProductModel(
        id: existing?.id,
        companyId: companyId,
        sku: sku,
        name: name,
        description: map['description'] ?? '',
        categoryId: categoryId,
        brandId: brandId,
        bagType: _emptyToNull(map['bag_type'] ?? map['bagtype']),
        material: _emptyToNull(map['material']),
        color: _emptyToNull(map['color']),
        size: _emptyToNull(map['size']),
        dimensions: _emptyToNull(map['dimensions']),
        weightGrams: _parseDouble(map['weight_grams']),
        barcode: _emptyToNull(map['barcode']),
        unitCost: _parseDouble(map['unit_cost']) ?? 0,
        sellingPrice: _parseDouble(map['selling_price']) ?? 0,
        wholesalePrice: _parseDouble(map['wholesale_price']),
        minStock: _parseInt(map['min_stock']) ?? 0,
        maxStock: _parseInt(map['max_stock']),
        reorderPoint: _parseInt(map['reorder_point']),
        isActive: _parseBool(map['is_active'], fallback: true),
        hasWarranty: _parseBool(map['has_warranty']),
        warrantyMonths: _parseInt(map['warranty_months']) ?? 0,
        updatedAt: DateTime.now().toUtc(),
      );

      if (existing == null) {
        await _products.createProduct(product);
        created += 1;
      } else {
        await _products.updateProduct(existing.id!, product);
        updated += 1;
      }
    }

    return BulkImportResult(
        created: created,
        updated: updated,
        skipped: skipped,
        warnings: warnings);
  }

  Future<String> exportSuppliersCsv({required String? companyId}) async {
    final items = await _suppliers.listSuppliers(companyId: companyId);
    return _CsvCodec.encode([
      ['name'],
      for (final item in items) [item.name],
    ]);
  }

  Future<BulkImportResult> importSuppliersCsv({
    required String companyId,
    required String csvText,
  }) async {
    final rows = _CsvCodec.decode(csvText);
    if (rows.isEmpty) {
      return const BulkImportResult(
          created: 0, updated: 0, skipped: 0, warnings: ['CSV is empty.']);
    }

    var created = 0;
    var updated = 0;
    var skipped = 0;
    final warnings = <String>[];

    final existing = await _suppliers.listSuppliers(companyId: companyId);
    final byName = {for (final s in existing) _normalizeHeader(s.name): s};

    final headers = rows.first.map(_normalizeHeader).toList();
    for (final row in rows.skip(1)) {
      final map = _rowMap(headers, row);
      final name = map['name']?.trim() ?? '';
      if (name.isEmpty) {
        skipped += 1;
        warnings.add('Skipped a supplier row with no name.');
        continue;
      }

      final key = _normalizeHeader(name);
      final current = byName[key];
      if (current == null) {
        await _suppliers.createSupplier(companyId: companyId, name: name);
        created += 1;
      } else if (current.name != name) {
        await _suppliers.updateSupplier(supplierId: current.id, name: name);
        updated += 1;
      } else {
        skipped += 1;
      }
    }

    return BulkImportResult(
        created: created,
        updated: updated,
        skipped: skipped,
        warnings: warnings);
  }

  Future<String> exportCustomersCsv({required String? companyId}) async {
    final items = await _customers.listCustomers(companyId: companyId ?? '');
    return _CsvCodec.encode([
      ['name', 'phone'],
      for (final item in items) [item.name, item.phone ?? ''],
    ]);
  }

  Future<BulkImportResult> importCustomersCsv({
    required String companyId,
    required String csvText,
  }) async {
    final rows = _CsvCodec.decode(csvText);
    if (rows.isEmpty) {
      return const BulkImportResult(
          created: 0, updated: 0, skipped: 0, warnings: ['CSV is empty.']);
    }

    var created = 0;
    var updated = 0;
    var skipped = 0;
    final warnings = <String>[];

    final existing = await _customers.listCustomers(companyId: companyId);
    final byName = {for (final c in existing) _normalizeHeader(c.name): c};

    final headers = rows.first.map(_normalizeHeader).toList();
    for (final row in rows.skip(1)) {
      final map = _rowMap(headers, row);
      final name = map['name']?.trim() ?? '';
      final phone = _emptyToNull(map['phone']);
      if (name.isEmpty) {
        skipped += 1;
        warnings.add('Skipped a customer row with no name.');
        continue;
      }

      final key = _normalizeHeader(name);
      final current = byName[key];
      if (current == null) {
        await _customers.createCustomer(
            companyId: companyId, name: name, phone: phone);
        created += 1;
      } else if ((current.phone ?? '') != (phone ?? '')) {
        await _customers.updateCustomer(
            customerId: current.id, name: name, phone: phone);
        updated += 1;
      } else {
        skipped += 1;
      }
    }

    return BulkImportResult(
        created: created,
        updated: updated,
        skipped: skipped,
        warnings: warnings);
  }

  Future<String> exportCustomersCsvText({required String? companyId}) async {
    return exportCustomersCsv(companyId: companyId);
  }

  String _lookupCategoryName(String? id, Map<String, String> names) {
    if (id == null) return '';
    return names[id] ?? '';
  }

  String _lookupBrandName(String? id, Map<String, String> names) {
    if (id == null) return '';
    return names[id] ?? '';
  }

  Future<String?> _resolveCategoryId(
    String companyId,
    String? name,
    Map<String, CategoryModel> cache,
  ) async {
    final normalized = _normalizeHeader(name ?? '');
    if (normalized.isEmpty) return null;
    final existing = cache[normalized];
    if (existing?.id != null) return existing!.id;

    final created = await _products.createCategory(
      CategoryModel(companyId: companyId, name: name!.trim()),
    );
    final model =
        CategoryModel(id: created, companyId: companyId, name: name.trim());
    cache[normalized] = model;
    return created;
  }

  Future<String?> _resolveBrandId(
    String companyId,
    String? name,
    Map<String, BrandModel> cache,
  ) async {
    final normalized = _normalizeHeader(name ?? '');
    if (normalized.isEmpty) return null;
    final existing = cache[normalized];
    if (existing?.id != null) return existing!.id;

    final created = await _products.createBrand(
      BrandModel(companyId: companyId, name: name!.trim()),
    );
    final model =
        BrandModel(id: created, companyId: companyId, name: name.trim());
    cache[normalized] = model;
    return created;
  }

  static String _normalizeHeader(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  static Map<String, String> _rowMap(List<String> headers, List<String> row) {
    final map = <String, String>{};
    for (var i = 0; i < headers.length; i += 1) {
      map[headers[i]] = i < row.length ? row[i] : '';
    }
    return map;
  }

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  static int? _parseInt(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  static double? _parseDouble(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  static bool _parseBool(String? value, {bool fallback = false}) {
    final trimmed = value?.trim().toLowerCase() ?? '';
    if (trimmed.isEmpty) return fallback;
    return ['1', 'true', 'yes', 'y', 'on'].contains(trimmed);
  }
}

class _CsvCodec {
  static String encode(List<List<String>> rows) {
    return rows.map((row) => row.map(_escape).join(',')).join('\n');
  }

  static List<List<String>> decode(String input) {
    final rows = <List<String>>[];
    final currentRow = <String>[];
    final currentCell = StringBuffer();
    var inQuotes = false;

    void endCell() {
      currentRow.add(currentCell.toString());
      currentCell.clear();
    }

    void endRow() {
      endCell();
      rows.add(List<String>.from(currentRow));
      currentRow.clear();
    }

    for (var i = 0; i < input.length; i += 1) {
      final char = input[i];
      if (char == '"') {
        if (inQuotes && i + 1 < input.length && input[i + 1] == '"') {
          currentCell.write('"');
          i += 1;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }

      if (!inQuotes && char == ',') {
        endCell();
        continue;
      }

      if (!inQuotes && (char == '\n' || char == '\r')) {
        if (char == '\r' && i + 1 < input.length && input[i + 1] == '\n') {
          i += 1;
        }
        if (currentCell.isNotEmpty || currentRow.isNotEmpty) {
          endRow();
        }
        continue;
      }

      currentCell.write(char);
    }

    if (currentCell.isNotEmpty || currentRow.isNotEmpty) {
      endRow();
    }

    return rows
        .where((row) => row.any((cell) => cell.trim().isNotEmpty))
        .toList();
  }

  static String _escape(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

import 'package:equatable/equatable.dart';

class ProductModel extends Equatable {
  final String? id;
  final String? companyId;

  final String sku;

  final String name;

  final String description;

  final String? categoryId;

  final String? brandId;

  final String? bagType;
  final String? material;
  final String? color;
  final String? size;
  final String? dimensions;
  final double? weightGrams;

  final String? barcode;
  final String? qrCode;

  final double unitCost;
  final double sellingPrice;
  final double? wholesalePrice;

  final int minStock;
  final int? maxStock;
  final int? reorderPoint;

  final bool isActive;
  final bool hasWarranty;
  final int warrantyMonths;

  final List<String>? imageUrls;
  final String? videoUrl;

  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    this.id,
    this.companyId,
    required this.sku,
    required this.name,
    this.description = '',
    this.categoryId,
    this.brandId,
    this.bagType,
    this.material,
    this.color,
    this.size,
    this.dimensions,
    this.weightGrams,
    this.barcode,
    this.qrCode,
    required this.unitCost,
    required this.sellingPrice,
    this.wholesalePrice,
    this.minStock = 5,
    this.maxStock,
    this.reorderPoint,
    this.isActive = true,
    this.hasWarranty = false,
    this.warrantyMonths = 0,
    this.imageUrls,
    this.videoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      companyId: json['company_id'],
      sku: json['sku'],
      name: json['name'],
      description: json['description'] ?? '',
      categoryId: json['category_id'],
      brandId: json['brand_id'],
      bagType: json['bag_type'],
      material: json['material'],
      color: json['color'],
      size: json['size'],
      dimensions: json['dimensions'],
      weightGrams: json['weight_grams']?.toDouble(),
      barcode: json['barcode'],
      qrCode: json['qr_code'],
      unitCost: (json['unit_cost'] as num).toDouble(),
      sellingPrice: (json['selling_price'] as num).toDouble(),
      wholesalePrice: json['wholesale_price']?.toDouble(),
      minStock: json['min_stock'] ?? 5,
      maxStock: json['max_stock'],
      reorderPoint: json['reorder_point'],
      isActive: json['is_active'] ?? true,
      hasWarranty: json['has_warranty'] ?? false,
      warrantyMonths: json['warranty_months'] ?? 0,
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'])
          : null,
      videoUrl: json['video_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      'sku': sku,
      'name': name,
      'description': description,
      if (categoryId != null) 'category_id': categoryId,
      if (brandId != null) 'brand_id': brandId,
      if (bagType != null) 'bag_type': bagType,
      if (material != null) 'material': material,
      if (color != null) 'color': color,
      if (size != null) 'size': size,
      if (dimensions != null) 'dimensions': dimensions,
      if (weightGrams != null) 'weight_grams': weightGrams,
      if (barcode != null) 'barcode': barcode,
      if (qrCode != null) 'qr_code': qrCode,
      'unit_cost': unitCost,
      'selling_price': sellingPrice,
      if (wholesalePrice != null) 'wholesale_price': wholesalePrice,
      'min_stock': minStock,
      if (maxStock != null) 'max_stock': maxStock,
      if (reorderPoint != null) 'reorder_point': reorderPoint,
      'is_active': isActive,
      'has_warranty': hasWarranty,
      'warranty_months': warrantyMonths,
      if (imageUrls != null) 'image_urls': imageUrls,
      if (videoUrl != null) 'video_url': videoUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ProductModel copyWith({
    String? id,
    String? companyId,
    String? sku,
    String? name,
    String? description,
    String? categoryId,
    String? brandId,
    String? bagType,
    String? material,
    String? color,
    String? size,
    String? dimensions,
    double? weightGrams,
    String? barcode,
    String? qrCode,
    double? unitCost,
    double? sellingPrice,
    double? wholesalePrice,
    int? minStock,
    int? maxStock,
    int? reorderPoint,
    bool? isActive,
    bool? hasWarranty,
    int? warrantyMonths,
    List<String>? imageUrls,
    String? videoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      brandId: brandId ?? this.brandId,
      bagType: bagType ?? this.bagType,
      material: material ?? this.material,
      color: color ?? this.color,
      size: size ?? this.size,
      dimensions: dimensions ?? this.dimensions,
      weightGrams: weightGrams ?? this.weightGrams,
      barcode: barcode ?? this.barcode,
      qrCode: qrCode ?? this.qrCode,
      unitCost: unitCost ?? this.unitCost,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      minStock: minStock ?? this.minStock,
      maxStock: maxStock ?? this.maxStock,
      reorderPoint: reorderPoint ?? this.reorderPoint,
      isActive: isActive ?? this.isActive,
      hasWarranty: hasWarranty ?? this.hasWarranty,
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        sku,
        name,
        description,
        categoryId,
        brandId,
        bagType,
        material,
        color,
        size,
        dimensions,
        weightGrams,
        barcode,
        qrCode,
        unitCost,
        sellingPrice,
        wholesalePrice,
        minStock,
        maxStock,
        reorderPoint,
        isActive,
        hasWarranty,
        warrantyMonths,
        imageUrls,
        videoUrl,
        createdAt,
        updatedAt,
      ];
}

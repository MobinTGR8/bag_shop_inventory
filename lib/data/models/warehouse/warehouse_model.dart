class WarehouseModel {
  final String id;
  final String companyId;
  final String name;
  final String type;
  final bool isDefault;

  const WarehouseModel({
    required this.id,
    required this.companyId,
    required this.name,
    required this.type,
    required this.isDefault,
  });

  factory WarehouseModel.fromJson(Map<String, dynamic> json) {
    return WarehouseModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      name: (json['name'] as String?) ?? '',
      type: (json['type'] as String?) ?? 'SHOWROOM',
      isDefault: (json['is_default'] as bool?) ?? false,
    );
  }
}

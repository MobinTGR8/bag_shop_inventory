class SupplierModel {
  final String id;
  final String name;
  SupplierModel({required this.id, required this.name});

  factory SupplierModel.fromJson(Map<String, dynamic> json) =>
      SupplierModel(id: json['id'] as String, name: json['name'] as String);
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

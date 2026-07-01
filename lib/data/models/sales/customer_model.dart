class CustomerModel {
  final String id;
  final String name;
  final String? phone;
  CustomerModel({required this.id, required this.name, this.phone});

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?);
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'phone': phone};
}

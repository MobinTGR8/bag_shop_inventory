import 'package:equatable/equatable.dart';

class CompanyModel extends Equatable {
  final String id;
  final String name;
  final String shopName;
  final String? phone;
  final String? email;

  const CompanyModel({
    required this.id,
    required this.name,
    required this.shopName,
    required this.phone,
    required this.email,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      shopName: (json['shop_name'] as String?) ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, shopName, phone, email];
}

import 'package:equatable/equatable.dart';

class BrandModel extends Equatable {
  final String? id;
  final String? companyId;

  final String name;
  final String? logoUrl;
  final String? website;
  final DateTime createdAt;

  BrandModel({
    this.id,
    this.companyId,
    required this.name,
    this.logoUrl,
    this.website,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id'],
      companyId: json['company_id'],
      name: (json['name'] as String?) ?? '',
      logoUrl: json['logo_url'],
      website: json['website'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      'name': name,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (website != null) 'website': website,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, companyId, name, logoUrl, website, createdAt];
}

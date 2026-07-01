import 'package:equatable/equatable.dart';

class CategoryModel extends Equatable {
  final String? id;
  final String? companyId;

  final String name;
  final String? description;
  final String? icon;
  final String? color;

  final DateTime createdAt;

  CategoryModel({
    this.id,
    this.companyId,
    required this.name,
    this.description,
    this.icon,
    this.color,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      companyId: json['company_id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
      color: json['color'],
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
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        name,
        description,
        icon,
        color,
        createdAt,
      ];
}

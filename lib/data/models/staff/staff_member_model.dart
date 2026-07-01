import 'package:equatable/equatable.dart';

import '../../../core/constants/user_roles.dart';

class StaffMemberModel extends Equatable {
  final String id;
  final String? userId;
  final String companyId;
  final String name;
  final String? email;
  final String? phone;
  final UserRole role;
  final List<String> permissions;
  final bool isActive;
  final DateTime? joinedDate;

  const StaffMemberModel({
    required this.id,
    this.userId,
    required this.companyId,
    required this.name,
    this.email,
    this.phone,
    required this.role,
    required this.permissions,
    required this.isActive,
    this.joinedDate,
  });

  /// Creates a copy with the given fields replaced.
  StaffMemberModel copyWith({
    String? id,
    String? userId,
    String? companyId,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    List<String>? permissions,
    bool? isActive,
    DateTime? joinedDate,
  }) {
    return StaffMemberModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
      joinedDate: joinedDate ?? this.joinedDate,
    );
  }

  factory StaffMemberModel.fromJson(Map<String, dynamic> json) {
    return StaffMemberModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      companyId: json['company_id'] as String,
      name: (json['name'] as String?) ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: UserRoleX.fromDb((json['role'] as String?) ?? 'STAFF'),
      permissions: (json['permissions'] as List?)?.cast<String>() ?? <String>[],
      isActive: (json['is_active'] as bool?) ?? true,
      joinedDate: json['joined_date'] == null
          ? null
          : DateTime.tryParse(json['joined_date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'company_id': companyId,
      'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'role': role.toDb(),
      'permissions': permissions,
      'is_active': isActive,
      if (joinedDate != null) 'joined_date': joinedDate!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        companyId,
        name,
        email,
        phone,
        role,
        permissions,
        isActive,
        joinedDate
      ];
}

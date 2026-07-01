enum UserRole {
  owner,
  manager,
  staff,
  accountant,
}

extension UserRoleX on UserRole {
  static UserRole fromDb(String value) {
    switch (value.toUpperCase()) {
      case 'OWNER':
        return UserRole.owner;
      case 'MANAGER':
        return UserRole.manager;
      case 'ACCOUNTANT':
        return UserRole.accountant;
      case 'STAFF':
      default:
        return UserRole.staff;
    }
  }

  String toDb() {
    switch (this) {
      case UserRole.owner:
        return 'OWNER';
      case UserRole.manager:
        return 'MANAGER';
      case UserRole.accountant:
        return 'ACCOUNTANT';
      case UserRole.staff:
        return 'STAFF';
    }
  }

  bool get isAdmin => this == UserRole.owner || this == UserRole.manager;
}

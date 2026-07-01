import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/permissions.dart';
import '../../../../core/constants/user_roles.dart';
import 'auth_provider.dart';

final permissionsProvider = Provider<Set<String>>((ref) {
  final auth = ref.watch(authProvider);
  final role = auth.role;

  // Not logged in
  if (role == null) return <String>{};

  // Admins: everything
  if (role.isAdmin || role == UserRole.owner) {
    return <String>{
      AppPermissions.inventoryView,
      AppPermissions.inventoryEdit,
      AppPermissions.productsView,
      AppPermissions.productsEdit,
      AppPermissions.customersView,
      AppPermissions.customersEdit,
      AppPermissions.salesView,
      AppPermissions.salesPos,
      AppPermissions.purchasesView,
      AppPermissions.purchasesEdit,
      AppPermissions.reportsView,
      AppPermissions.staffManage,
    };
  }

  // Base defaults per role
  final defaults = <String>{
    AppPermissions.inventoryView,
    AppPermissions.productsView,
  };

  switch (role) {
    case UserRole.staff:
      defaults.addAll({
        AppPermissions.salesPos,
        AppPermissions.salesView,
        AppPermissions.customersView,
        AppPermissions.purchasesView,
      });
      break;
    case UserRole.accountant:
      defaults.addAll({
        AppPermissions.salesView,
        AppPermissions.customersView,
        AppPermissions.purchasesView,
        AppPermissions.reportsView,
      });
      break;
    case UserRole.manager:
    case UserRole.owner:
      // handled above
      break;
  }

  // Explicit per-user permissions from DB can expand/limit. If present, use it
  // as the source of truth (still keeping inventory/products view as minimum).
  final explicit = auth.permissions;
  if (explicit != null) {
    final set = <String>{...defaults};
    set.addAll(explicit);
    return set;
  }

  return defaults;
});

final hasPermissionProvider = Provider.family<bool, String>((ref, permission) {
  return ref.watch(permissionsProvider).contains(permission);
});

final canAccessAdminProvider = Provider<bool>((ref) {
  final auth = ref.watch(authProvider);
  final role = auth.role;
  if (role == null) return false;
  if (role.isAdmin) return true;
  return ref.watch(permissionsProvider).contains(AppPermissions.staffManage);
});

final canAccessPosProvider = Provider<bool>((ref) {
  return ref.watch(permissionsProvider).contains(AppPermissions.salesPos);
});

final canAccessReportsProvider = Provider<bool>((ref) {
  return ref.watch(permissionsProvider).contains(AppPermissions.reportsView);
});

final canViewInventoryProvider = Provider<bool>((ref) {
  return ref.watch(hasPermissionProvider(AppPermissions.inventoryView));
});

final canEditInventoryProvider = Provider<bool>((ref) {
  return ref.watch(hasPermissionProvider(AppPermissions.inventoryEdit));
});

final canEditProductsProvider = Provider<bool>((ref) {
  return ref.watch(hasPermissionProvider(AppPermissions.productsEdit));
});

final canViewCustomersProvider = Provider<bool>((ref) {
  return ref.watch(hasPermissionProvider(AppPermissions.customersView));
});

final canEditCustomersProvider = Provider<bool>((ref) {
  return ref.watch(hasPermissionProvider(AppPermissions.customersEdit));
});

final canViewSalesProvider = Provider<bool>((ref) {
  return ref.watch(hasPermissionProvider(AppPermissions.salesView));
});

final canViewPurchasesProvider = Provider<bool>((ref) {
  return ref.watch(hasPermissionProvider(AppPermissions.purchasesView));
});

final canEditPurchasesProvider = Provider<bool>((ref) {
  return ref.watch(hasPermissionProvider(AppPermissions.purchasesEdit));
});

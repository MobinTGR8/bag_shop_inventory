import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:bag_shop_inventory/core/constants/user_roles.dart';
import 'package:bag_shop_inventory/presentation/features/admin/screens/admin_dashboard_screen.dart';
import 'package:bag_shop_inventory/presentation/features/auth/providers/auth_provider.dart';
import 'package:bag_shop_inventory/presentation/features/auth/providers/permission_provider.dart';
import 'package:bag_shop_inventory/presentation/features/auth/screens/login_screen.dart';
import 'package:bag_shop_inventory/presentation/features/debug/screens/supabase_test_screen.dart';
import 'package:bag_shop_inventory/services/supabase_service.dart';

class TestAuthNotifier extends AuthNotifier {
  TestAuthNotifier(super.service, AuthState initialState) {
    state = initialState;
  }
}

SupabaseService _makeDummySupabaseService() {
  return SupabaseService(
    SupabaseClient(
      'https://example.supabase.co',
      'public-anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    ),
  );
}

AuthState _authState({
  String? companyId,
  UserRole? role,
  List<String>? permissions,
}) {
  return AuthState(
    user: null,
    companyId: companyId,
    role: role,
    permissions: permissions,
  );
}

Widget _wrapWithAuth(Widget child, AuthState authState) {
  final service = _makeDummySupabaseService();

  return ProviderScope(
    overrides: [
      supabaseServiceProvider.overrideWithValue(service),
      authProvider.overrideWith(
        (ref) => TestAuthNotifier(service, authState),
      ),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  test('Owner has admin and edit permissions', () {
    final service = _makeDummySupabaseService();
    final container = ProviderContainer(
      overrides: [
        supabaseServiceProvider.overrideWithValue(service),
        authProvider.overrideWith(
          (ref) => TestAuthNotifier(
            service,
            _authState(companyId: 'company-1', role: UserRole.owner),
          ),
        ),
      ],
    );

    addTearDown(container.dispose);

    expect(container.read(canAccessAdminProvider), isTrue);
    expect(container.read(canEditProductsProvider), isTrue);
    expect(container.read(canEditInventoryProvider), isTrue);
    expect(container.read(canEditPurchasesProvider), isTrue);
  });

  test('Staff permission matrix stays limited', () {
    final service = _makeDummySupabaseService();
    final container = ProviderContainer(
      overrides: [
        supabaseServiceProvider.overrideWithValue(service),
        authProvider.overrideWith(
          (ref) => TestAuthNotifier(
            service,
            _authState(companyId: 'company-1', role: UserRole.staff),
          ),
        ),
      ],
    );

    addTearDown(container.dispose);

    expect(container.read(canAccessAdminProvider), isFalse);
    expect(container.read(canEditProductsProvider), isFalse);
    expect(container.read(canEditInventoryProvider), isFalse);
    expect(container.read(canViewSalesProvider), isTrue);
    expect(container.read(canViewPurchasesProvider), isTrue);
  });

  testWidgets('Login screen renders required fields', (tester) async {
    await tester.pumpWidget(
      _wrapWithAuth(
        LoginScreen(),
        _authState(),
      ),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('Supabase test screen reports missing company context',
      (tester) async {
    await tester.pumpWidget(
      _wrapWithAuth(
        const SupabaseTestScreen(),
        _authState(role: UserRole.owner),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Supabase Connection Test'), findsOneWidget);
    expect(find.textContaining('Missing companyId'), findsOneWidget);
  });

  testWidgets('Admin dashboard exposes live operations hub', (tester) async {
    await tester.pumpWidget(
      _wrapWithAuth(
        const AdminDashboardScreen(),
        _authState(companyId: 'company-1', role: UserRole.owner),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Operations hub'), findsOneWidget);
    expect(find.text('Staff management'), findsOneWidget);
    expect(find.text('Bulk import / export'), findsOneWidget);
    expect(find.text('Backend health'), findsOneWidget);
  });
}

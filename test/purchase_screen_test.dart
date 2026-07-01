import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:bag_shop_inventory/core/constants/user_roles.dart';
import 'package:bag_shop_inventory/presentation/features/auth/providers/auth_provider.dart';
import 'package:bag_shop_inventory/presentation/features/purchases/screens/receive_purchase_screen.dart';
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
  testWidgets('Receive purchase screen denies users without edit access',
      (tester) async {
    await tester.pumpWidget(
      _wrapWithAuth(
        const ReceivePurchaseScreen(purchaseOrderId: 'po-1'),
        const AuthState(
          user: null,
          companyId: 'company-1',
          role: UserRole.staff,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No access'), findsOneWidget);
    expect(find.textContaining('receive purchases'), findsOneWidget);
  });
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/constants/user_roles.dart';
import '../../../../services/supabase_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(supabaseServiceProvider));
});

class AuthState {
  static const Object _unset = Object();

  final bool isLoading;
  final String? error;
  final sb.User? user;
  final String? companyId;
  final String? staffId;
  final UserRole? role;
  final List<String>? permissions;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.user,
    this.companyId,
    this.staffId,
    this.role,
    this.permissions,
  });

  AuthState copyWith({
    bool? isLoading,
    Object? error = _unset,
    Object? user = _unset,
    Object? companyId = _unset,
    Object? staffId = _unset,
    Object? role = _unset,
    Object? permissions = _unset,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      user: identical(user, _unset) ? this.user : user as sb.User?,
      companyId:
          identical(companyId, _unset) ? this.companyId : companyId as String?,
      staffId: identical(staffId, _unset) ? this.staffId : staffId as String?,
      role: identical(role, _unset) ? this.role : role as UserRole?,
      permissions: identical(permissions, _unset)
          ? this.permissions
          : permissions as List<String>?,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseService _supabaseService;
  late final sb.SupabaseClient _supabase;
  late final StreamSubscription _authSub;

  AuthNotifier(this._supabaseService) : super(const AuthState()) {
    _supabase = _supabaseService.client;

    // Keep state in sync with Supabase auth.
    _authSub = _supabase.auth.onAuthStateChange.listen((event) {
      final user = event.session?.user;
      if (user == null) {
        state = const AuthState();
      } else {
        // Do a best-effort refresh of company/role.
        unawaited(checkAuth());
      }
    });

    unawaited(checkAuth());
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final normalizedEmail = _normalizeEmail(email);

      final response = await _supabase.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Sign in failed. Please try again.');
      }

      final resolved = await _resolveCompanyAndRole(user.id);
      state = state.copyWith(
        isLoading: false,
        user: user,
        companyId: resolved.companyId,
        staffId: resolved.staffId,
        role: resolved.role,
        permissions: resolved.permissions,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Auth login failed: $e');
      }
      state = state.copyWith(
        isLoading: false,
        error: _formatAuthError(e),
      );
    }
  }

  Future<void> registerAdmin({
    required String email,
    required String password,
    required String shopName,
    required String phone,
    required String name,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final normalizedEmail = _normalizeEmail(email);
      final normalizedPhone = phone.trim();
      final normalizedName = name.trim();
      final normalizedShopName = shopName.trim();

      final response = await _supabase.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: {
          'name': normalizedName,
          'shop_name': normalizedShopName,
        },
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Sign up failed. Please try again.');
      }

      // Create company for the user
      final companyResponse = await _supabase
          .from('companies')
          .insert({
            'name': normalizedName,
            'shop_name': normalizedShopName,
            'phone': normalizedPhone,
            'email': normalizedEmail,
            'owner_id': user.id,
          })
          .select('id')
          .single();

      // Create owner record in staff table (unifies role handling)
      final staffResponse = await _supabase
          .from('staff')
          .insert({
            'company_id': companyResponse['id'],
            'user_id': user.id,
            'name': normalizedName,
            'email': normalizedEmail,
            'phone': normalizedPhone,
            'role': UserRole.owner.toDb(),
            'permissions': <String>[],
            'is_active': true,
          })
          .select('id, role')
          .single();

      // Create default warehouse
      await _supabase.from('warehouses').insert({
        'company_id': companyResponse['id'],
        'name': 'Main Store',
        'type': 'SHOWROOM',
        'is_default': true,
      });

      state = state.copyWith(
        isLoading: false,
        user: user,
        companyId: companyResponse['id'],
        staffId: staffResponse['id'],
        role: UserRoleX.fromDb(staffResponse['role'] as String),
        permissions: (staffResponse['permissions'] as List?)?.cast<String>() ??
            <String>[],
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Auth registerAdmin failed: $e');
      }
      state = state.copyWith(
        isLoading: false,
        error: _formatAuthError(e),
      );
    }
  }

  String _normalizeEmail(String email) {
    final normalized = email
        .replaceAll(RegExp(r'[\s\u200B-\u200D\uFEFF]'), '')
        .trim()
        .toLowerCase();
    if (normalized.isEmpty) {
      throw Exception('Email is required.');
    }
    return normalized;
  }

  String _formatAuthError(Object e) {
    // Prefer clean, user-friendly messages over raw exception dumps.
    if (e is sb.AuthApiException) {
      switch (e.code) {
        case 'email_address_invalid':
          return 'Please enter a valid email address.';
        case 'user_already_exists':
          return 'An account with this email already exists. Try signing in instead.';
        case 'weak_password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'over_email_send_rate_limit':
        case 'email_rate_limit_exceeded':
          return 'Too many attempts. Please wait a bit and try again.';
        case 'too_many_requests':
          return 'Too many requests. Please try again in a moment.';
        case 'invalid_login_credentials':
          return 'Incorrect email or password.';
        case 'email_not_confirmed':
          return 'Email confirmation is enabled in Supabase. Disable it (Auth → Providers → Email → Confirm email) or confirm this email, then try again.';
        case 'user_not_found':
          return 'No account found for this email.';
        case 'signup_disabled':
          return 'Sign up is disabled for this project.';
        default:
          // Keep the message, but include the code/status in debug builds to
          // make web debugging easier (e.g. Chrome console 400s).
          if (kDebugMode) {
            final code = (e.code ?? '').toString();
            final status = (e.statusCode).toString();
            return '${e.message} (code: $code, status: $status)';
          }
          return e.message;
      }
    }
    if (e is sb.AuthException) {
      return e.message;
    }
    final msg = e.toString();
    return msg.startsWith('Exception: ') ? msg.substring(11) : msg;
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> checkAuth() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final resolved = await _resolveCompanyAndRole(user.id);
        state = state.copyWith(
          user: user,
          companyId: resolved.companyId,
          staffId: resolved.staffId,
          role: resolved.role,
          permissions: resolved.permissions,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<_ResolvedCompanyRole> _resolveCompanyAndRole(String userId) async {
    // Owner path
    final company = await _supabase
        .from('companies')
        .select('id')
        .eq('owner_id', userId)
        .maybeSingle();

    if (company != null) {
      // Prefer the staff row if it exists (created on admin register), else
      // treat as OWNER.
      final staffRow = await _supabase
          .from('staff')
          .select('id, role, company_id, permissions')
          .eq('user_id', userId)
          .maybeSingle();

      if (staffRow != null) {
        return _ResolvedCompanyRole(
          companyId: staffRow['company_id'] as String,
          staffId: staffRow['id'] as String,
          role: UserRoleX.fromDb(staffRow['role'] as String),
          permissions: (staffRow['permissions'] as List?)?.cast<String>(),
        );
      }

      return _ResolvedCompanyRole(
        companyId: company['id'] as String,
        staffId: null,
        role: UserRole.owner,
        permissions: null,
      );
    }

    // Staff path
    final staffRow = await _supabase
        .from('staff')
        .select('id, role, company_id, permissions')
        .eq('user_id', userId)
        .maybeSingle();

    if (staffRow != null) {
      return _ResolvedCompanyRole(
        companyId: staffRow['company_id'] as String,
        staffId: staffRow['id'] as String,
        role: UserRoleX.fromDb(staffRow['role'] as String),
        permissions: (staffRow['permissions'] as List?)?.cast<String>(),
      );
    }

    return const _ResolvedCompanyRole(
      companyId: null,
      staffId: null,
      role: null,
      permissions: null,
    );
  }
}

class _ResolvedCompanyRole {
  final String? companyId;
  final String? staffId;
  final UserRole? role;
  final List<String>? permissions;

  const _ResolvedCompanyRole({
    required this.companyId,
    required this.staffId,
    required this.role,
    required this.permissions,
  });
}

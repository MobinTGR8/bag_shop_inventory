import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/user_roles.dart';
import '../../services/supabase_service.dart';
import '../models/staff/staff_member_model.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository(ref.watch(supabaseServiceProvider));
});

class StaffRepository {
  final SupabaseService _supabase;

  StaffRepository(this._supabase);

  Future<List<StaffMemberModel>> listStaff({required String companyId}) async {
    final response = await _supabase.client
        .from('staff')
        .select(
            'id, user_id, company_id, name, email, phone, role, permissions, is_active, joined_date')
        .eq('company_id', companyId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => StaffMemberModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> setStaffActive({
    required String staffId,
    required bool isActive,
  }) async {
    await _supabase.client.from('staff').update({
      'is_active': isActive,
    }).eq('id', staffId);
  }

  Future<void> updateStaffRole({
    required String staffId,
    required UserRole role,
  }) async {
    await _supabase.client.from('staff').update({
      'role': role.toDb(),
    }).eq('id', staffId);
  }

  Future<void> updateStaffPermissions({
    required String staffId,
    required List<String> permissions,
  }) async {
    await _supabase.client.from('staff').update({
      'permissions': permissions,
    }).eq('id', staffId);
  }

  Future<StaffMemberModel> createStaff({
    required String companyId,
    required String name,
    String? email,
    String? phone,
    required UserRole role,
    List<String> permissions = const [],
  }) async {
    final response = await _supabase.client
        .from('staff')
        .insert({
          'company_id': companyId,
          'name': name,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
          'role': role.toDb(),
          'permissions': permissions,
          'is_active': true,
          'joined_date': DateTime.now().toUtc().toIso8601String(),
        })
        .select()
        .single();

    return StaffMemberModel.fromJson(response);
  }

  Future<void> updateStaffName({
    required String staffId,
    required String name,
    String? email,
    String? phone,
  }) async {
    final updates = <String, dynamic>{
      'name': name,
    };
    if (email != null) updates['email'] = email;
    if (phone != null) updates['phone'] = phone;

    await _supabase.client.from('staff').update(updates).eq('id', staffId);
  }

  Future<void> deleteStaff({required String staffId}) async {
    await _supabase.client.from('staff').delete().eq('id', staffId);
  }

  // -----------------------------------------------------------------------
  // Real-time streams using Supabase Realtime channels
  // -----------------------------------------------------------------------

  Future<StaffMemberModel?> getStaff({required String staffId}) async {
    final response = await _supabase.client
        .from('staff')
        .select(
            'id, user_id, company_id, name, email, phone, role, permissions, is_active, joined_date')
        .eq('id', staffId)
        .maybeSingle();

    if (response == null) return null;
    return StaffMemberModel.fromJson(response);
  }

  /// Returns a real-time stream of staff members for the given company.
  Stream<List<StaffMemberModel>> streamStaff({required String companyId}) {
    final controller = StreamController<List<StaffMemberModel>>();

    void emit() async {
      try {
        final data = await listStaff(companyId: companyId);
        if (!controller.isClosed) controller.add(data);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    // Emit initial data immediately
    emit();

    // Subscribe to realtime changes
    final channel = _supabase.client.channel('staff-changes-$companyId');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'staff',
      callback: (_) => emit(),
    ).subscribe();

    // Cleanup when the stream is cancelled
    controller.onCancel = () {
      _supabase.client.removeChannel(channel);
    };

    return controller.stream;
  }

}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../services/supabase_service.dart';
import '../models/sales/customer_model.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(ref.watch(supabaseServiceProvider));
});

class CustomerRepository {
  final SupabaseService _supabase;
  final Uuid _uuid = const Uuid();

  CustomerRepository(this._supabase);

  Future<List<CustomerModel>> listCustomers({required String companyId}) async {
    final rows = await _supabase.client
        .from('customers')
        .select('id, company_id, name, phone')
        .eq('company_id', companyId)
        .order('name')
        .limit(500);

    return (rows as List)
        .map((e) => CustomerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CustomerModel?> getCustomerById({required String customerId}) async {
    final row = await _supabase.client
        .from('customers')
        .select('id, company_id, name, phone')
        .eq('id', customerId)
        .maybeSingle();

    if (row == null) return null;
    return CustomerModel.fromJson(row);
  }

  Future<String> createCustomer({
    required String companyId,
    required String name,
    String? phone,
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) throw Exception('Customer name is required');

    final id = _uuid.v4();

    final row = await _supabase.client
        .from('customers')
        .insert({
          'id': id,
          'company_id': companyId,
          'name': normalizedName,
          'phone': (phone?.trim().isEmpty ?? true) ? null : phone!.trim(),
        })
        .select('id')
        .single();

    return row['id'] as String;
  }

  Future<void> updateCustomer({
    required String customerId,
    required String name,
    String? phone,
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) throw Exception('Customer name is required');

    await _supabase.client.from('customers').update({
      'name': normalizedName,
      'phone': (phone?.trim().isEmpty ?? true) ? null : phone!.trim(),
    }).eq('id', customerId);
  }

  Future<void> deleteCustomer({required String customerId}) async {
    await _supabase.client.from('customers').delete().eq('id', customerId);
  }
}

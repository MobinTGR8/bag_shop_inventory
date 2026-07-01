import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/supabase_service.dart';
import '../models/purchases/supplier_model.dart';

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  return SupplierRepository(ref.watch(supabaseServiceProvider));
});

class SupplierRepository {
  final SupabaseService _supabase;

  SupplierRepository(this._supabase);

  Future<List<SupplierModel>> listSuppliers(
      {required String? companyId}) async {
    if (companyId == null) return <SupplierModel>[];

    final rows = await _supabase.client
        .from('suppliers')
        .select('id, name')
        .eq('company_id', companyId)
        .order('name');

    return (rows as List)
        .map((e) => SupplierModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SupplierModel?> getSupplierById({required String supplierId}) async {
    final row = await _supabase.client
        .from('suppliers')
        .select('id, name')
        .eq('id', supplierId)
        .maybeSingle();

    if (row == null) return null;
    return SupplierModel.fromJson(row);
  }

  Future<String> createSupplier({
    required String companyId,
    required String name,
  }) async {
    final row = await _supabase.client
        .from('suppliers')
        .insert({
          'company_id': companyId,
          'name': name,
        })
        .select('id')
        .single();

    return row['id'] as String;
  }

  Future<void> updateSupplier({
    required String supplierId,
    required String name,
  }) async {
    await _supabase.client
        .from('suppliers')
        .update({'name': name}).eq('id', supplierId);
  }
}

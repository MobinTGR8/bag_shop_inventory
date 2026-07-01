import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/supabase_service.dart';
import '../models/company/company_model.dart';

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return CompanyRepository(ref.watch(supabaseServiceProvider));
});

class CompanyRepository {
  final SupabaseService _supabase;

  CompanyRepository(this._supabase);

  Future<CompanyModel?> getCompanyById({required String? companyId}) async {
    if (companyId == null) return null;

    final row = await _supabase.client
        .from('companies')
        .select('id, name, shop_name, phone, email')
        .eq('id', companyId)
        .maybeSingle();

    if (row == null) return null;
    return CompanyModel.fromJson(row);
  }
}

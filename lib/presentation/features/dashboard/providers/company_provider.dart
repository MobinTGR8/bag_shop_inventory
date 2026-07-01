import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/company/company_model.dart';
import '../../../../data/repositories/company_repository.dart';
import '../../auth/providers/auth_provider.dart';

final companyProvider = FutureProvider<CompanyModel?>((ref) async {
  final companyId = ref.watch(authProvider).companyId;
  return ref
      .watch(companyRepositoryProvider)
      .getCompanyById(companyId: companyId);
});

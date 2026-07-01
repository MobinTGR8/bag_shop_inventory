import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/staff/staff_member_model.dart';
import '../../../../data/repositories/staff_repository.dart';
import '../../../features/auth/providers/auth_provider.dart';

final companyIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).companyId;
});

/// Real-time stream of staff members for the current company.
final staffListProvider = StreamProvider<List<StaffMemberModel>>((ref) {
  final companyId = ref.watch(companyIdProvider);
  if (companyId == null) return Stream.value([]);
  return ref.watch(staffRepositoryProvider).streamStaff(companyId: companyId);
});

/// Fetches a single staff member by ID.
final staffMemberProvider = FutureProvider.family<StaffMemberModel?, String>((ref, staffId) {
  return ref.watch(staffRepositoryProvider).getStaff(staffId: staffId);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/notification_service.dart';
import '../../auth/providers/auth_provider.dart';

final inAppNotificationsProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  final companyId = ref.watch(authProvider).companyId;
  if (companyId == null) return <AppNotification>[];
  return ref.watch(notificationServiceProvider).getInAppNotifications(
        companyId: companyId,
      );
});

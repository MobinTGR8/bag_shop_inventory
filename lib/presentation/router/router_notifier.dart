import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/providers/auth_provider.dart';

class RouterNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  final notifier = RouterNotifier();

  ref.listen<AuthState>(authProvider, (_, __) {
    notifier.refresh();
  });

  return notifier;
});

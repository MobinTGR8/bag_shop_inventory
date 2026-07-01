import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityResultProvider = StreamProvider<ConnectivityResult>((ref) {
  final connectivity = Connectivity();

  return (() async* {
    yield await connectivity.checkConnectivity();
    yield* connectivity.onConnectivityChanged;
  })();
});

final isOfflineProvider = Provider<bool>((ref) {
  final resultAsync = ref.watch(connectivityResultProvider);
  return resultAsync.maybeWhen(
    data: (result) => result == ConnectivityResult.none,
    orElse: () => false,
  );
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/router/app_router.dart';
import '../presentation/theme/app_theme.dart';

class BagShopInventoryApp extends ConsumerWidget {
  const BagShopInventoryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Bag Shop Inventory',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => child ?? const SizedBox.shrink(),
    );
  }
}

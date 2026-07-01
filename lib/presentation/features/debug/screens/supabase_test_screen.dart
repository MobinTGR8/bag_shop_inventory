import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_body.dart';
import '../../../../services/supabase_service.dart';
import '../../auth/providers/auth_provider.dart';

final _supabaseConnectionTestProvider =
    FutureProvider<_SupabaseTestResult>((ref) async {
  final auth = ref.watch(authProvider);
  final companyId = auth.companyId;
  if (companyId == null) {
    return const _SupabaseTestResult(
      ok: false,
      message:
          'Missing companyId. Register an admin (creates a company) or join with an invite code, then try again.',
    );
  }

  final client = ref.watch(supabaseServiceProvider).client;

  try {
    final rows = await client
        .from('products')
        .select('id, sku, name')
        .eq('company_id', companyId)
        .limit(1);

    final list = (rows as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) {
      return const _SupabaseTestResult(
        ok: true,
        message:
            'Connected. Read products OK, but no products found for this company yet.',
      );
    }

    final first = list.first;
    final sku = (first['sku'] as String?) ?? '';
    final name = (first['name'] as String?) ?? '';

    return _SupabaseTestResult(
      ok: true,
      message: 'Connected. Read products OK (example: $sku • $name).',
    );
  } catch (e) {
    return _SupabaseTestResult(
      ok: false,
      message: 'Read failed: $e',
    );
  }
});

class SupabaseTestScreen extends ConsumerWidget {
  const SupabaseTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    final testAsync = ref.watch(_supabaseConnectionTestProvider);
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Connection Test'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(_supabaseConnectionTestProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: AppBody(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Auth context', style: tt.titleMedium),
                    const SizedBox(height: 12),
                    _kv(context, 'User ID', user?.id ?? '(not signed in)'),
                    _kv(context, 'Email', user?.email ?? '(none)'),
                    _kv(context, 'Company ID', auth.companyId ?? '(none)'),
                    _kv(context, 'Role', auth.role?.name ?? '(none)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RLS read test', style: tt.titleMedium),
                    const SizedBox(height: 12),
                    testAsync.when(
                      loading: () => const Row(
                        children: [
                          SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Testing read access to products...'),
                        ],
                      ),
                      error: (e, _) => Text('Test crashed: $e'),
                      data: (r) => Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            r.ok ? Icons.check_circle : Icons.error,
                            color: r.ok ? scheme.primary : scheme.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(r.message)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'If this fails with “permission denied”, it usually means your RLS policies were not applied or your user is not linked to a company/staff row.',
                      style: tt.bodySmall?.copyWith(
                        color: scheme.onSurface.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              k,
              style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}

class _SupabaseTestResult {
  final bool ok;
  final String message;

  const _SupabaseTestResult({required this.ok, required this.message});
}

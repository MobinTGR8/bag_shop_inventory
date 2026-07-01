import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_body.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../services/sync_service.dart';

class SyncQueueScreen extends ConsumerStatefulWidget {
  const SyncQueueScreen({super.key});

  @override
  ConsumerState<SyncQueueScreen> createState() => _SyncQueueScreenState();
}

class _SyncQueueScreenState extends ConsumerState<SyncQueueScreen> {
  bool _syncing = false;

  Future<void> _runSync() async {
    setState(() => _syncing = true);
    try {
      final result = await ref.read(syncServiceProvider).syncOutbox();
      ref.invalidate(pendingOutboxActionsProvider);
      ref.invalidate(pendingOutboxCountProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage == null
                ? 'Sync done. Sent: ${result.processed}, remaining: ${result.remaining}'
                : 'Sync stopped. Sent: ${result.processed}, remaining: ${result.remaining}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _clearQueue() async {
    await ref.read(syncServiceProvider).clearOutbox();
    ref.invalidate(pendingOutboxActionsProvider);
    ref.invalidate(pendingOutboxCountProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Outbox cleared.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actionsAsync = ref.watch(pendingOutboxActionsProvider);
    final countAsync = ref.watch(pendingOutboxCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Queue'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(pendingOutboxActionsProvider);
              ref.invalidate(pendingOutboxCountProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: actionsAsync.when(
        loading: () => const AppBody(child: LoadingIndicator()),
        error: (e, _) => AppBody(
          child: ErrorState(
            title: 'Failed to load queue',
            message: e.toString(),
            onRetry: () {
              ref.invalidate(pendingOutboxActionsProvider);
              ref.invalidate(pendingOutboxCountProvider);
            },
          ),
        ),
        data: (actions) {
          final pendingCount = countAsync.asData?.value ?? actions.length;

          if (actions.isEmpty) {
            return AppBody(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  const EmptyState(
                    title: 'Queue is empty',
                    message: 'No offline actions are waiting to sync.',
                    icon: Icons.cloud_done_outlined,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _syncing ? null : _runSync,
                    icon: _syncing
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync),
                    label: const Text('Sync now'),
                  ),
                ],
              ),
            );
          }

          return AppBody(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.cloud_queue_outlined),
                    title: Text('$pendingCount queued action(s)'),
                    subtitle: const Text(
                      'Oldest actions are synced first. Failed duplicate inserts are skipped as already applied.',
                    ),
                    trailing: FilledButton(
                      onPressed: _syncing ? null : _runSync,
                      child: _syncing
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Retry all'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _syncing ? null : _clearQueue,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Clear queue'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final action in actions)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.pending_actions_outlined),
                      title: Text(
                          '${action.kind.toUpperCase()} • ${action.table}'),
                      subtitle: Text(
                        'Created: ${action.createdAt.toLocal()}\nRows: ${action.rows.length}${action.values != null ? '\nUpdate fields: ${action.values!.keys.join(', ')}' : ''}',
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'remove') {
                            await ref
                                .read(syncServiceProvider)
                                .removeAction(action.id);
                          } else if (value == 'sync') {
                            await _runSync();
                          }
                          ref.invalidate(pendingOutboxActionsProvider);
                          ref.invalidate(pendingOutboxCountProvider);
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'sync', child: Text('Sync now')),
                          PopupMenuItem(value: 'remove', child: Text('Remove')),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

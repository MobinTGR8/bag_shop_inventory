import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/exceptions/app_exceptions.dart';
import 'supabase_service.dart';
import 'outbox_action.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.watch(supabaseServiceProvider));
});

final pendingOutboxCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(syncServiceProvider).getPendingCount();
});

final pendingOutboxActionsProvider =
    FutureProvider<List<OutboxAction>>((ref) async {
  return ref.watch(syncServiceProvider).getPendingActions();
});

class SyncResult {
  final int processed;
  final int remaining;
  final String? errorMessage;
  final String? failedTable;
  final String? failedKind;

  const SyncResult({
    required this.processed,
    required this.remaining,
    this.errorMessage,
    this.failedTable,
    this.failedKind,
  });
}

class QueuedForSyncException implements Exception {
  final String message;
  const QueuedForSyncException([this.message = 'Queued for sync']);

  @override
  String toString() => message;
}

class SyncService {
  static const _outboxKey = 'outbox_actions_v1';

  final SupabaseService _supabase;
  final Uuid _uuid = const Uuid();

  SyncService(this._supabase);

  Future<List<OutboxAction>> _loadOutbox(SharedPreferences prefs) async {
    final raw = prefs.getString(_outboxKey);
    if (raw == null || raw.trim().isEmpty) return <OutboxAction>[];
    try {
      return OutboxAction.decodeList(raw);
    } catch (_) {
      return <OutboxAction>[];
    }
  }

  Future<void> _saveOutbox(
      SharedPreferences prefs, List<OutboxAction> actions) async {
    await prefs.setString(_outboxKey, OutboxAction.encodeList(actions));
  }

  Future<int> getPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    final actions = await _loadOutbox(prefs);
    return actions.length;
  }

  Future<List<OutboxAction>> getPendingActions() async {
    final prefs = await SharedPreferences.getInstance();
    final actions = await _loadOutbox(prefs);
    actions.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return actions;
  }

  Future<void> removeAction(String actionId) async {
    final prefs = await SharedPreferences.getInstance();
    final actions = await _loadOutbox(prefs);
    actions.removeWhere((action) => action.id == actionId);
    await _saveOutbox(prefs, actions);
  }

  bool _containsEquivalentAction(
    List<OutboxAction> actions,
    OutboxAction candidate,
  ) {
    final candidateFingerprint = candidate.businessFingerprint();
    return actions
        .any((action) => action.businessFingerprint() == candidateFingerprint);
  }

  Future<void> clearAndReplace(List<OutboxAction> actions) async {
    final prefs = await SharedPreferences.getInstance();
    await _saveOutbox(prefs, actions);
  }

  Future<void> enqueueInsert({
    required String table,
    required List<Map<String, dynamic>> rows,
  }) async {
    if (rows.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final actions = await _loadOutbox(prefs);

    final action = OutboxAction(
      id: _uuid.v4(),
      kind: 'insert',
      table: table,
      rows: rows,
      createdAt: DateTime.now().toUtc(),
    );

    if (_containsEquivalentAction(actions, action)) return;

    actions.insert(0, action);

    await _saveOutbox(prefs, actions);
  }

  Future<void> enqueueUpdate({
    required String table,
    required Map<String, dynamic> values,
    required Map<String, dynamic> match,
  }) async {
    if (values.isEmpty || match.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final actions = await _loadOutbox(prefs);

    final action = OutboxAction(
      id: _uuid.v4(),
      kind: 'update',
      table: table,
      rows: const <Map<String, dynamic>>[],
      values: values,
      match: match,
      createdAt: DateTime.now().toUtc(),
    );

    if (_containsEquivalentAction(actions, action)) return;

    actions.insert(0, action);

    await _saveOutbox(prefs, actions);
  }

  Future<bool> _insertAlreadyApplied(OutboxAction action) async {
    if (action.kind != 'insert' || action.table != 'stock_movements') {
      return false;
    }
    if (action.rows.isEmpty) return false;

    final first = action.rows.first;
    final referenceType = first['reference_type'] as String?;
    final referenceId = first['reference_id'] as String?;
    if (referenceType == null || referenceId == null) return false;

    final allMatch = action.rows.every((row) {
      return row['reference_type'] == referenceType &&
          row['reference_id'] == referenceId;
    });
    if (!allMatch) return false;

    final rows = await _supabase.client
        .from('stock_movements')
        .select('id')
        .eq('reference_type', referenceType)
        .eq('reference_id', referenceId)
        .limit(1);

    return (rows as List).isNotEmpty;
  }

  Future<SyncResult> syncOutbox() async {
    final prefs = await SharedPreferences.getInstance();
    final actions = await _loadOutbox(prefs);
    if (actions.isEmpty) return const SyncResult(processed: 0, remaining: 0);

    var processed = 0;
    final remainingActions = <OutboxAction>[...actions];

    // Oldest-first so actions apply in order.
    remainingActions.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    while (remainingActions.isNotEmpty) {
      final action = remainingActions.first;
      try {
        if (action.kind == 'insert') {
          if (await _insertAlreadyApplied(action)) {
            remainingActions.removeAt(0);
            processed += 1;
            continue;
          }
          await _supabase.client.from(action.table).insert(action.rows);
        } else if (action.kind == 'update') {
          final values = action.values;
          final match = action.match;
          if (values == null || match == null) {
            throw const SyncException(
              'Invalid update action payload',
              code: 'invalid_payload',
            );
          }
          final matchObj = <String, Object>{
            for (final e in match.entries) e.key: e.value as Object,
          };
          await _supabase.client
              .from(action.table)
              .update(values)
              .match(matchObj);
        } else {
          throw SyncException(
            'Unsupported outbox action: ${action.kind}',
            code: 'unsupported_action',
          );
        }

        remainingActions.removeAt(0);
        processed += 1;
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint(
            'Sync outbox failed for ${action.table}/${action.kind}: $error',
          );
          debugPrintStack(stackTrace: stackTrace);
        }

        if (error is SyncException && error.code == 'invalid_payload') {
          remainingActions.removeAt(0);
          processed += 1;
          continue;
        }

        if (_isDuplicateConflict(error)) {
          remainingActions.removeAt(0);
          processed += 1;
          continue;
        }

        // Stop on first failure; keep the rest for later.
        return SyncResult(
          processed: processed,
          remaining: remainingActions.length,
          errorMessage: error.toString(),
          failedTable: action.table,
          failedKind: action.kind,
        );
      }
    }

    // Persist remaining actions.
    await _saveOutbox(prefs, remainingActions);

    return SyncResult(processed: processed, remaining: remainingActions.length);
  }

  Future<void> clearOutbox() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_outboxKey);
  }

  bool _isDuplicateConflict(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('duplicate key') ||
        text.contains('already exists') ||
        text.contains('unique constraint');
  }
}

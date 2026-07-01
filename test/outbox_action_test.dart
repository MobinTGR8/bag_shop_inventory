import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bag_shop_inventory/services/outbox_action.dart';
import 'package:bag_shop_inventory/services/sync_service.dart';
import 'package:bag_shop_inventory/services/supabase_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('OutboxAction encodes/decodes list', () {
    final action = OutboxAction(
      id: '1',
      kind: 'insert',
      table: 'stock_movements',
      rows: const [
        {'a': 1, 'b': 'x'},
      ],
      createdAt: DateTime.utc(2025, 1, 1),
    );

    final updateAction = OutboxAction(
      id: '2',
      kind: 'update',
      table: 'purchase_order_items',
      rows: const [],
      values: const {'received_quantity': 10},
      match: const {'id': 'abc'},
      createdAt: DateTime.utc(2025, 1, 2),
    );

    final raw = OutboxAction.encodeList([action, updateAction]);
    final decoded = OutboxAction.decodeList(raw);

    expect(decoded, hasLength(2));
    expect(decoded.first.id, '1');
    expect(decoded.first.table, 'stock_movements');
    expect(decoded.first.rows.first['a'], 1);
    expect(decoded.last.kind, 'update');
    expect(decoded.last.values?['received_quantity'], 10);
    expect(decoded.last.match?['id'], 'abc');
  });

  test('OutboxAction business fingerprint is stable for identical payloads',
      () {
    final first = OutboxAction(
      id: '1',
      kind: 'insert',
      table: 'stock_movements',
      rows: const [
        {'a': 1, 'b': 'x'},
      ],
      createdAt: DateTime.utc(2025, 1, 1),
    );

    final second = OutboxAction(
      id: '1',
      kind: 'insert',
      table: 'stock_movements',
      rows: const [
        {'b': 'x', 'a': 1},
      ],
      createdAt: DateTime.utc(2025, 1, 1),
    );

    expect(first.businessFingerprint(), second.businessFingerprint());
  });

  test('SyncService enqueues and counts pending actions', () async {
    final supabaseClient = SupabaseClient('https://example.supabase.co', 'key');
    final service = SyncService(SupabaseService(supabaseClient));

    expect(await service.getPendingCount(), 0);

    await service.enqueueInsert(
      table: 'stock_movements',
      rows: const [
        {'movement_type': 'ADJUSTMENT', 'qty': 1},
      ],
    );

    await service.enqueueUpdate(
      table: 'purchase_order_items',
      values: const {'received_quantity': 10},
      match: const {'id': 'abc'},
    );

    expect(await service.getPendingCount(), 2);

    await service.enqueueInsert(
      table: 'stock_movements',
      rows: const [
        {'movement_type': 'ADJUSTMENT', 'qty': 1},
      ],
    );

    await service.enqueueUpdate(
      table: 'purchase_order_items',
      values: const {'received_quantity': 10},
      match: const {'id': 'abc'},
    );

    expect(await service.getPendingCount(), 2);

    await service.clearOutbox();
    expect(await service.getPendingCount(), 0);
  });

  test('SyncService syncOutbox does not throw on failure', () async {
    final supabaseClient = SupabaseClient('https://example.supabase.co', 'key');
    final service = SyncService(SupabaseService(supabaseClient));

    await service.enqueueInsert(
      table: 'stock_movements',
      rows: const [
        {'movement_type': 'ADJUSTMENT', 'qty': 1},
      ],
    );

    final result = await service.syncOutbox();

    // With dummy credentials, insert should fail but the service should handle it.
    expect(result.processed, 0);
    expect(result.remaining, 1);
  });
}

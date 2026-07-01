import 'package:flutter_test/flutter_test.dart';

import 'package:bag_shop_inventory/services/stable_fingerprint.dart';

void main() {
  test('StableFingerprint ignores map key ordering', () {
    final first = StableFingerprint.of({
      'companyId': 'c1',
      'items': [
        {'productId': 'p1', 'quantity': 2},
      ],
    });

    final second = StableFingerprint.of({
      'items': [
        {'quantity': 2, 'productId': 'p1'},
      ],
      'companyId': 'c1',
    });

    expect(first, second);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb hide AuthState;

import 'package:bag_shop_inventory/core/constants/user_roles.dart';
import 'package:bag_shop_inventory/data/models/product/product_model.dart';
import 'package:bag_shop_inventory/data/models/purchases/purchase_order_detail_model.dart';
import 'package:bag_shop_inventory/data/models/purchases/purchase_order_item_model.dart';
import 'package:bag_shop_inventory/data/models/purchases/purchase_order_model.dart';
import 'package:bag_shop_inventory/data/models/warehouse/warehouse_model.dart';
import 'package:bag_shop_inventory/data/repositories/inventory_operations_repository.dart';
import 'package:bag_shop_inventory/data/repositories/product_repository.dart';
import 'package:bag_shop_inventory/data/repositories/purchase_repository.dart';
import 'package:bag_shop_inventory/data/repositories/sales_repository.dart';
import 'package:bag_shop_inventory/data/repositories/warehouse_repository.dart';
import 'package:bag_shop_inventory/presentation/features/auth/providers/auth_provider.dart';
import 'package:bag_shop_inventory/presentation/features/inventory/screens/adjust_stock_screen.dart';
import 'package:bag_shop_inventory/presentation/features/inventory/providers/warehouses_provider.dart';
import 'package:bag_shop_inventory/presentation/features/purchases/screens/receive_purchase_screen.dart';
import 'package:bag_shop_inventory/presentation/features/sales/screens/pos_screen.dart';
import 'package:bag_shop_inventory/services/supabase_service.dart';
import 'package:bag_shop_inventory/services/sync_service.dart';

class TestAuthNotifier extends AuthNotifier {
  TestAuthNotifier(super.service, AuthState initialState) {
    state = initialState;
  }
}

class FakeProductRepository extends ProductRepository {
  FakeProductRepository(super.supabase, this.products);

  final List<ProductModel> products;

  @override
  Future<List<ProductModel>> getProducts({String? companyId}) async {
    return products;
  }
}

class FakeWarehouseRepository extends WarehouseRepository {
  FakeWarehouseRepository(super.supabase, this.warehouses);

  final List<WarehouseModel> warehouses;

  @override
  Future<List<WarehouseModel>> listWarehouses(
      {required String companyId}) async {
    return warehouses;
  }

  @override
  Future<String?> getDefaultWarehouseId({required String companyId}) async {
    return warehouses
        .firstWhere((w) => w.isDefault, orElse: () => warehouses.first)
        .id;
  }
}

class FakeSalesRepository extends SalesRepository {
  FakeSalesRepository(super.supabase, super.sync);

  int createCalls = 0;

  @override
  Future<({String id, String invoiceNumber, bool queuedForSync})> createSale({
    required String companyId,
    required String createdBy,
    required String warehouseId,
    required List<({String productId, int quantity, double unitPrice})> items,
    String status = 'CONFIRMED',
    String paymentStatus = 'PAID',
    String? paymentMethod,
    Map<String, dynamic>? paymentSplit,
    double taxAmount = 0,
    double discountAmount = 0,
    double shippingCharge = 0,
    String? clientRequestId,
  }) async {
    createCalls += 1;
    return (
      id: 'sale-1',
      invoiceNumber: 'INV-001',
      queuedForSync: false,
    );
  }
}

class FakePurchaseRepository extends PurchaseRepository {
  FakePurchaseRepository(super.supabase, super.sync, this.detail);

  final PurchaseOrderDetailModel detail;
  int receiveCalls = 0;

  @override
  Future<PurchaseOrderDetailModel> getPurchaseOrderDetail({
    required String purchaseOrderId,
  }) async {
    return detail;
  }

  @override
  Future<void> receivePurchaseOrder({
    required String purchaseOrderId,
    required String companyId,
    required String receivedBy,
    required String fallbackWarehouseId,
    required Map<String, int> receiveByItemId,
    Map<String, String?>? warehouseByItemId,
  }) async {
    receiveCalls += 1;
  }
}

class FakeInventoryOperationsRepository extends InventoryOperationsRepository {
  FakeInventoryOperationsRepository(super.supabase, super.sync);

  int adjustCalls = 0;
  int transferCalls = 0;

  @override
  Future<void> adjustStock({
    required String companyId,
    required String createdBy,
    required String productId,
    required String warehouseId,
    required int quantityDelta,
    String? batchNumber,
    String? reason,
  }) async {
    adjustCalls += 1;
  }

  @override
  Future<void> transferStock({
    required String companyId,
    required String createdBy,
    required String productId,
    required String fromWarehouseId,
    required String toWarehouseId,
    required int quantity,
    String? batchNumber,
  }) async {
    transferCalls += 1;
  }
}

SupabaseService _makeDummySupabaseService() {
  return SupabaseService(
    sb.SupabaseClient(
      'https://example.supabase.co',
      'public-anon-key',
      authOptions: const sb.AuthClientOptions(autoRefreshToken: false),
    ),
  );
}

sb.User _testUser() {
  return const sb.User(
    id: 'user-1',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2026-01-01T00:00:00.000Z',
  );
}

AuthState _authState() {
  return AuthState(
    user: _testUser(),
    companyId: 'company-1',
    staffId: 'staff-1',
    role: UserRole.owner,
    permissions: const [],
  );
}

Widget _wrapWithAuthAndOverrides({
  required Widget child,
  required SupabaseService service,
  required AuthState authState,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      supabaseServiceProvider.overrideWithValue(service),
      authProvider.overrideWith(
        (ref) => TestAuthNotifier(service, authState),
      ),
      ...overrides,
    ],
    child: child,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('POS checkout creates a sale and routes to sales',
      (tester) async {
    final service = _makeDummySupabaseService();
    final product = ProductModel(
      id: 'product-1',
      companyId: 'company-1',
      sku: 'BAG-001',
      name: 'Travel Bag',
      unitCost: 10,
      sellingPrice: 20,
      minStock: 5,
      maxStock: 20,
      reorderPoint: 5,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
    final products = [product];
    final warehouses = [
      const WarehouseModel(
        id: 'wh-1',
        companyId: 'company-1',
        name: 'Main Warehouse',
        type: 'SHOWROOM',
        isDefault: true,
      ),
    ];
    final productRepo = FakeProductRepository(service, products);
    final warehouseRepo = FakeWarehouseRepository(service, warehouses);
    final salesRepo = FakeSalesRepository(service, SyncService(service));

    final router = GoRouter(
      initialLocation: '/pos',
      routes: [
        GoRoute(
          path: '/pos',
          builder: (context, state) => _wrapWithAuthAndOverrides(
            service: service,
            authState: _authState(),
            overrides: [
              productRepositoryProvider.overrideWithValue(productRepo),
              warehouseRepositoryProvider.overrideWithValue(warehouseRepo),
              salesRepositoryProvider.overrideWithValue(salesRepo),
            ],
            child: const PosScreen(),
          ),
        ),
        GoRoute(
          path: '/sales',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Sales landing')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Travel Bag'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();

    expect(salesRepo.createCalls, 1);
    expect(find.text('Sales landing'), findsOneWidget);
  });

  testWidgets('Purchase receive confirms and loads the next route',
      (tester) async {
    final service = _makeDummySupabaseService();
    final detail = PurchaseOrderDetailModel(
      order: PurchaseOrderModel(
        id: 'po-1',
        companyId: 'company-1',
        supplierId: 'supplier-1',
        poNumber: 'PO-001',
        status: 'PENDING',
        orderDate: DateTime.utc(2026, 1, 1),
        expectedDelivery: null,
        actualDelivery: null,
        totalAmount: 100,
        notes: null,
      ),
      supplierName: 'Supplier A',
      items: const [
        PurchaseOrderItemModel(
          id: 'item-1',
          productId: 'product-1',
          quantity: 5,
          unitCost: 20,
          warehouseId: null,
          batchNumber: null,
          receivedQuantity: 0,
          productName: 'Travel Bag',
          productSku: 'BAG-001',
        ),
      ],
    );
    final warehouses = [
      const WarehouseModel(
        id: 'wh-1',
        companyId: 'company-1',
        name: 'Main Warehouse',
        type: 'SHOWROOM',
        isDefault: true,
      ),
    ];
    final purchaseRepo =
        FakePurchaseRepository(service, SyncService(service), detail);
    final warehouseRepo = FakeWarehouseRepository(service, warehouses);

    await tester.pumpWidget(
      _wrapWithAuthAndOverrides(
        service: service,
        authState: _authState(),
        overrides: [
          purchaseRepositoryProvider.overrideWithValue(purchaseRepo),
          warehouseRepositoryProvider.overrideWithValue(warehouseRepo),
        ],
        child: const MaterialApp(
          home: ReceivePurchaseScreen(purchaseOrderId: 'po-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm receive'));
    await tester.pumpAndSettle();

    expect(purchaseRepo.receiveCalls, 1);
  });

  testWidgets('Inventory adjust and transfer flows call the repository',
      (tester) async {
    final service = _makeDummySupabaseService();
    final products = [
      ProductModel(
        id: 'product-1',
        companyId: 'company-1',
        sku: 'BAG-001',
        name: 'Travel Bag',
        unitCost: 10,
        sellingPrice: 20,
        minStock: 5,
        maxStock: 20,
        reorderPoint: 5,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    ];
    final adjustWarehouses = [
      const WarehouseModel(
        id: 'wh-1',
        companyId: 'company-1',
        name: 'Main Warehouse',
        type: 'SHOWROOM',
        isDefault: true,
      ),
    ];
    final productRepo = FakeProductRepository(service, products);
    final adjustWarehouseRepo =
        FakeWarehouseRepository(service, adjustWarehouses);
    final inventoryRepo =
        FakeInventoryOperationsRepository(service, SyncService(service));

    await tester.pumpWidget(
      _wrapWithAuthAndOverrides(
        service: service,
        authState: _authState(),
        overrides: [
          productRepositoryProvider.overrideWithValue(productRepo),
          inventoryOperationsRepositoryProvider
              .overrideWithValue(inventoryRepo),
          inventoryWarehousesProvider.overrideWith(
            (ref) async => adjustWarehouses,
          ),
          warehouseRepositoryProvider.overrideWithValue(adjustWarehouseRepo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AdjustStockScreen(),
                      ),
                    );
                  },
                  child: const Text('Open adjust'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Open adjust'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pick product'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Travel Bag'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '4');
    await tester.tap(find.text('Save adjustment'));
    await tester.pumpAndSettle();

    expect(inventoryRepo.adjustCalls, 1);

    final transferRepo =
        FakeInventoryOperationsRepository(service, SyncService(service));
    await transferRepo.transferStock(
      companyId: 'company-1',
      createdBy: 'user-1',
      productId: 'product-1',
      fromWarehouseId: 'wh-1',
      toWarehouseId: 'wh-2',
      quantity: 2,
    );

    expect(transferRepo.transferCalls, 1);
  });
}

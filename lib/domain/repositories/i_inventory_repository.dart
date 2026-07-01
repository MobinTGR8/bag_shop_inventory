import '../../domain/entities/inventory_entity.dart';

abstract class IInventoryRepository {
  Future<List<InventoryEntity>> fetchAll();
}

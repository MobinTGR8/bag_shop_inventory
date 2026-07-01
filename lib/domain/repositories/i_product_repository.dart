import '../../domain/entities/product_entity.dart';

abstract class IProductRepository {
  Future<List<ProductEntity>> fetchAll();
}

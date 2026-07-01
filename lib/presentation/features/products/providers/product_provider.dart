import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/product/product_model.dart';
import '../../../../data/models/product/category_model.dart';
import '../../../../data/models/product/brand_model.dart';
import '../../../../data/repositories/product_repository.dart';
import '../../auth/providers/auth_provider.dart';

final productsStreamProvider = StreamProvider<List<ProductModel>>((ref) {
  final companyId = ref.watch(authProvider).companyId;
  return ref
      .watch(productRepositoryProvider)
      .watchProducts(companyId: companyId);
});

final productsProvider = FutureProvider<List<ProductModel>>((ref) {
  final companyId = ref.watch(authProvider).companyId;
  return ref.watch(productRepositoryProvider).getProducts(companyId: companyId);
});

final productByIdProvider =
    FutureProvider.family<ProductModel?, String>((ref, id) async {
  return ref.watch(productRepositoryProvider).getProductById(id);
});

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final companyId = ref.watch(authProvider).companyId;
  return ref
      .watch(productRepositoryProvider)
      .getCategories(companyId: companyId);
});

final brandsProvider = FutureProvider<List<BrandModel>>((ref) async {
  final companyId = ref.watch(authProvider).companyId;
  return ref.watch(productRepositoryProvider).getBrands(companyId: companyId);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/product_model.dart';
import '../data/product_repository.dart';

final productSearchProvider = StateProvider<String>((ref) => '');
final productCategoryFilterProvider = StateProvider<String?>((ref) => null);

final productsProvider =
    FutureProvider.family<List<Product>, void>((ref, _) async {
  final search = ref.watch(productSearchProvider);
  final category = ref.watch(productCategoryFilterProvider);
  return ProductRepository.getAll(
    search: search.isNotEmpty ? search : null,
    category: category,
  );
});

final productDetailProvider =
    FutureProvider.family<Product?, String>((ref, id) async {
  return ProductRepository.getById(id);
});

final productCategoriesProvider = FutureProvider<List<String>>((ref) async {
  return ProductRepository.getCategories();
});

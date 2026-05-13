import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/recipe_model.dart';
import '../data/recipe_item_model.dart';
import '../data/recipe_repository.dart';

final recipeProductFilterProvider = StateProvider<String?>((ref) => null);

final recipesProvider =
    FutureProvider.family<List<Recipe>, void>((ref, _) async {
  final productId = ref.watch(recipeProductFilterProvider);
  return RecipeRepository.getAll(productId: productId);
});

final recipeDetailProvider =
    FutureProvider.family<Recipe?, String>((ref, id) async {
  return RecipeRepository.getById(id);
});

final recipeItemsProvider =
    FutureProvider.family<List<RecipeItem>, String>((ref, recipeId) async {
  return RecipeRepository.getItems(recipeId);
});

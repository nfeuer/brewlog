import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/drink_recipe.dart';
import '../services/database_service.dart';
import 'user_provider.dart';

/// Provider for all drink recipes
final drinkRecipesProvider =
    StateNotifierProvider<DrinkRecipesNotifier, List<DrinkRecipe>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return DrinkRecipesNotifier(db);
});

class DrinkRecipesNotifier extends StateNotifier<List<DrinkRecipe>> {
  final DatabaseService _db;

  DrinkRecipesNotifier(this._db) : super([]) {
    _loadRecipes();
  }

  void _loadRecipes() {
    state = _db.getAllDrinkRecipes();
  }

  /// Create new drink recipe
  Future<String> createRecipe(DrinkRecipe recipe) async {
    final id = await _db.createDrinkRecipe(recipe);
    _loadRecipes();
    return id;
  }

  /// Update existing drink recipe
  Future<void> updateRecipe(DrinkRecipe recipe) async {
    await _db.updateDrinkRecipe(recipe);
    _loadRecipes();
  }

  /// Delete drink recipe
  Future<void> deleteRecipe(String recipeId) async {
    await _db.deleteDrinkRecipe(recipeId);
    _loadRecipes();
  }

  /// Search recipes by name
  List<DrinkRecipe> searchRecipes(String query) {
    if (query.isEmpty) return state;
    return _db.searchDrinkRecipes(query);
  }

  /// Refresh recipes from database
  void refresh() {
    _loadRecipes();
  }
}

/// Provider for a single drink recipe by ID
final drinkRecipeByIdProvider =
    Provider.family<DrinkRecipe?, String>((ref, recipeId) {
  final recipes = ref.watch(drinkRecipesProvider);
  try {
    return recipes.firstWhere((r) => r.id == recipeId);
  } catch (e) {
    return null;
  }
});

/// Provider to check if user has any drink recipes
final hasDrinkRecipesProvider = Provider<bool>((ref) {
  final recipes = ref.watch(drinkRecipesProvider);
  return recipes.isNotEmpty;
});

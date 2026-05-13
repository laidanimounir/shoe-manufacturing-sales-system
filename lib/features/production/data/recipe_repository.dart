import '../../../core/services/supabase_service.dart';
import 'recipe_model.dart';
import 'recipe_item_model.dart';

class RecipeRepository {
  static const _table = 'recipes';
  static const _itemsTable = 'recipe_items';

  static Future<List<Recipe>> getAll({String? productId}) async {
    final client = SupabaseService.client;
    var query = client.from(_table).select('*, products(name)');

    if (productId != null && productId.isNotEmpty) {
      query = query.eq('product_id', productId);
    }

    final data = await query.order('name');
    return (data as List).map((json) => Recipe.fromMap(json)).toList();
  }

  static Future<Recipe?> getById(String id) async {
    final client = SupabaseService.client;
    final response = await client
        .from(_table)
        .select('*, products(name)')
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return Recipe.fromMap(response);
  }

  static Future<List<RecipeItem>> getItems(String recipeId) async {
    final client = SupabaseService.client;
    final data = await client
        .from(_itemsTable)
        .select('*, raw_materials(name, unit)')
        .eq('recipe_id', recipeId)
        .order('raw_materials(name)');
    return (data as List).map((json) => RecipeItem.fromMap(json)).toList();
  }

  static Future<Recipe> create({
    required String productId,
    required String name,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final client = SupabaseService.client;

    final insertMap = {
      'product_id': productId,
      'name': name.trim(),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    final response = await client
        .from(_table)
        .insert(insertMap)
        .select('*, products(name)')
        .single();

    final recipeId = response['id'] as String;

    if (items.isNotEmpty) {
      final itemMaps = items.map((item) {
        return {
          'recipe_id': recipeId,
          'raw_material_id': item['raw_material_id'],
          'quantity_per_unit': item['quantity_per_unit'],
          'unit': item['unit'],
        };
      }).toList();

      await client.from(_itemsTable).insert(itemMaps);
    }

    await SupabaseService.logAudit(
      action: 'create',
      tableName: _table,
      recordId: recipeId,
      newData: insertMap,
      description: 'Recette créée : $name',
    );

    return Recipe.fromMap(response);
  }

  static Future<Recipe> update({
    required String id,
    required String productId,
    required String name,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final client = SupabaseService.client;

    final old = await client.from(_table).select().eq('id', id).single();

    final updateMap = {
      'product_id': productId,
      'name': name.trim(),
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    await client.from(_table).update(updateMap).eq('id', id);

    await client.from(_itemsTable).delete().eq('recipe_id', id);

    if (items.isNotEmpty) {
      final itemMaps = items.map((item) {
        return {
          'recipe_id': id,
          'raw_material_id': item['raw_material_id'],
          'quantity_per_unit': item['quantity_per_unit'],
          'unit': item['unit'],
        };
      }).toList();

      await client.from(_itemsTable).insert(itemMaps);
    }

    await SupabaseService.logAudit(
      action: 'update',
      tableName: _table,
      recordId: id,
      oldData: old,
      newData: updateMap,
      description: 'Recette modifiée : $name',
    );

    final updated =
        await client.from(_table).select('*, products(name)').eq('id', id).single();
    return Recipe.fromMap(updated);
  }

  static Future<void> delete(String id, String name) async {
    final client = SupabaseService.client;

    await client.from(_itemsTable).delete().eq('recipe_id', id);
    await client.from(_table).delete().eq('id', id);

    await SupabaseService.logAudit(
      action: 'delete',
      tableName: _table,
      recordId: id,
      description: 'Recette supprimée : $name',
    );
  }
}

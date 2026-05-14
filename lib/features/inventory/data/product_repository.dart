import '../../../core/services/supabase_service.dart';
import 'product_model.dart';

class ProductRepository {
  static const _table = 'products';

  static Future<List<Product>> getAll({
    String? search,
    String? category,
    bool? isActive,
  }) async {
    final client = SupabaseService.client;
    var query = client.from(_table).select();

    if (search != null && search.isNotEmpty) {
      query = query.ilike('name', '%$search%');
    }
    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }
    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }

    final data = await query.order('name');
    return (data as List).map((json) => Product.fromMap(json)).toList();
  }

  static Future<Product?> getById(String id) async {
    final client = SupabaseService.client;
    final response = await client.from(_table).select().eq('id', id).maybeSingle();
    if (response == null) return null;
    return Product.fromMap(response);
  }

  static Future<Product> create({
    required String name,
    String? category,
    String? size,
    String? color,
    String? material,
    String? sku,
    String? barcode,
    double sellingPrice = 0,
    bool isActive = true,
  }) async {
    final client = SupabaseService.client;

    final insertMap = {
      'name': name.trim(),
      if (category != null && category.trim().isNotEmpty) 'category': category.trim(),
      if (size != null && size.trim().isNotEmpty) 'size': size.trim(),
      if (color != null && color.trim().isNotEmpty) 'color': color.trim(),
      if (material != null && material.trim().isNotEmpty) 'material': material.trim(),
      if (sku != null && sku.trim().isNotEmpty) 'sku': sku.trim(),
      if (barcode != null && barcode.trim().isNotEmpty) 'barcode': barcode.trim(),
      'selling_price': sellingPrice,
      'is_active': isActive,
    };

    final response = await client.from(_table).insert(insertMap).select().single();

    await SupabaseService.logAudit(
      action: 'create',
      tableName: _table,
      recordId: response['id'],
      newData: insertMap,
      description: 'Produit créé : $name',
    );

    return Product.fromMap(response);
  }

  static Future<Product> update({
    required String id,
    required String name,
    String? category,
    String? size,
    String? color,
    String? material,
    String? sku,
    String? barcode,
    double sellingPrice = 0,
    bool isActive = true,
  }) async {
    final client = SupabaseService.client;

    final old = await client.from(_table).select().eq('id', id).single();

    final updateMap = {
      'name': name.trim(),
      'category': category?.trim().isEmpty == true ? null : category?.trim(),
      'size': size?.trim().isEmpty == true ? null : size?.trim(),
      'color': color?.trim().isEmpty == true ? null : color?.trim(),
      'material': material?.trim().isEmpty == true ? null : material?.trim(),
      'sku': sku?.trim().isEmpty == true ? null : sku?.trim(),
      'barcode': barcode?.trim().isEmpty == true ? null : barcode?.trim(),
      'selling_price': sellingPrice,
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await client.from(_table).update(updateMap).eq('id', id);

    await SupabaseService.logAudit(
      action: 'update',
      tableName: _table,
      recordId: id,
      oldData: old,
      newData: updateMap,
      description: 'Produit modifié : $name',
    );

    final updated = await client.from(_table).select().eq('id', id).single();
    return Product.fromMap(updated);
  }

  static Future<void> toggleActive(String id, bool isActive, String name) async {
    final client = SupabaseService.client;

    await client
        .from(_table)
        .update({'is_active': isActive, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);

    await SupabaseService.logAudit(
      action: isActive ? 'update' : 'delete',
      tableName: _table,
      recordId: id,
      newData: {'is_active': isActive},
      description: 'Produit $name ${isActive ? "activé" : "désactivé"}',
    );
  }

  static Future<List<Product>> getAllWithStock({
    String? search,
    String? category,
  }) async {
    final client = SupabaseService.client;
    var query = client.from('products').select().eq('is_active', true);

    if (search != null && search.isNotEmpty) {
      query = query.ilike('name', '%$search%');
    }
    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }

    final productsData = await query.order('name');
    final inventoryData = await client.from('inventory').select('product_id, quantity');
    final stockMap = <String, double>{};
    for (final row in inventoryData as List) {
      final pid = row['product_id'] as String;
      final qty = (row['quantity'] as num?)?.toDouble() ?? 0;
      stockMap[pid] = (stockMap[pid] ?? 0) + qty;
    }

    return (productsData as List).map((json) {
      json['total_stock'] = stockMap[json['id'] as String] ?? 0;
      return Product.fromMap(json);
    }).toList();
  }

  static Future<List<String>> getCategories() async {
    final client = SupabaseService.client;
    final data = await client
        .from(_table)
        .select('category')
        .not('category', 'is', null)
        .order('category');

    final categories = <String>{};
    for (final row in data as List) {
      final cat = row['category'] as String?;
      if (cat != null && cat.isNotEmpty) {
        categories.add(cat);
      }
    }
    return categories.toList()..sort();
  }
}

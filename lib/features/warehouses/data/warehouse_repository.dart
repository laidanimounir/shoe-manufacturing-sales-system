import '../../../core/services/supabase_service.dart';
import 'warehouse_model.dart';

class WarehouseRepository {
  static const _table = 'warehouses';

  static Future<List<Warehouse>> getAll({String? search}) async {
    final client = SupabaseService.client;

    if (search != null && search.isNotEmpty) {
      final data = await client
          .from(_table)
          .select()
          .ilike('name', '%$search%')
          .order('name');
      return (data as List).map((json) => Warehouse.fromMap(json)).toList();
    }

    final data = await client.from(_table).select().order('name');
    return (data as List).map((json) => Warehouse.fromMap(json)).toList();
  }

  static Future<Warehouse> create({
    required String name,
    String? location,
    bool isActive = true,
  }) async {
    final client = SupabaseService.client;

    final insertMap = {
      'name': name.trim(),
      if (location != null && location.trim().isNotEmpty)
        'location': location.trim(),
      'is_active': isActive,
    };

    final response = await client.from(_table).insert(insertMap).select().single();

    await SupabaseService.logAudit(
      action: 'INSERT',
      tableName: _table,
      recordId: response['id'],
      newData: insertMap,
      description: 'Dépôt créé : $name',
    );

    return Warehouse.fromMap(response);
  }

  static Future<Warehouse> update({
    required String id,
    required String name,
    String? location,
    required bool isActive,
  }) async {
    final client = SupabaseService.client;

    final old = await client.from(_table).select().eq('id', id).single();

    final updateMap = {
      'name': name.trim(),
      'location': location?.trim().isEmpty == true ? null : location?.trim(),
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await client.from(_table).update(updateMap).eq('id', id);

    await SupabaseService.logAudit(
      action: 'UPDATE',
      tableName: _table,
      recordId: id,
      oldData: old,
      newData: updateMap,
      description: 'Dépôt modifié : $name',
    );

    final updated = await client.from(_table).select().eq('id', id).single();
    return Warehouse.fromMap(updated);
  }

  static Future<void> toggleActive(String id, bool isActive, String name) async {
    final client = SupabaseService.client;

    await client
        .from(_table)
        .update({'is_active': isActive, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);

    final action = isActive ? 'ACTIVATE' : 'DEACTIVATE';
    await SupabaseService.logAudit(
      action: action,
      tableName: _table,
      recordId: id,
      newData: {'is_active': isActive},
      description: 'Dépôt $name ${isActive ? "activé" : "désactivé"}',
    );
  }

  static Future<Warehouse?> getById(String id) async {
    final client = SupabaseService.client;
    final response = await client.from(_table).select().eq('id', id).maybeSingle();
    if (response == null) return null;
    return Warehouse.fromMap(response);
  }

  static Future<Map<String, dynamic>> getStats(String warehouseId) async {
    final client = SupabaseService.client;

    final results = await Future.wait([
      client.from('inventory').select('quantity').eq('warehouse_id', warehouseId),
      client.from('employees').select('id').eq('warehouse_id', warehouseId).eq('is_active', true),
      client.from('inventory')
          .select('quantity')
          .eq('warehouse_id', warehouseId)
          .filter('quantity', 'gt', 0),
    ]);

    final inventoryItems = results[0] as List;
    final totalProducts = inventoryItems.fold<int>(0, (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 0));
    final activeEmployees = (results[1] as List).length;
    final productVarieties = (results[2] as List).length;

    return {
      'totalProducts': totalProducts,
      'activeEmployees': activeEmployees,
      'productVarieties': productVarieties,
    };
  }

  static Future<List<Map<String, dynamic>>> getEmployees(String warehouseId) async {
    final client = SupabaseService.client;
    final response = await client
        .from('employees')
        .select('id, job_title, is_active, base_salary, hire_date, profile_id, profiles(full_name)')
        .eq('warehouse_id', warehouseId)
        .order('is_active', ascending: false)
        .order('job_title');

    return List<Map<String, dynamic>>.from(response as List);
  }

  static Future<List<Map<String, dynamic>>> getInventorySummary(String warehouseId) async {
    final client = SupabaseService.client;
    final response = await client
        .from('inventory')
        .select('id, quantity, last_updated, product_id, products(name, category, size)')
        .eq('warehouse_id', warehouseId)
        .order('quantity', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }
}

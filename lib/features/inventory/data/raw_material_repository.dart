import '../../../core/services/supabase_service.dart';
import 'raw_material_model.dart';

class RawMaterialRepository {
  static const _table = 'raw_materials';

  static Future<List<RawMaterial>> getAll({
    String? warehouseId,
    String? search,
  }) async {
    final client = SupabaseService.client;
    var query = client.from(_table).select('*, warehouses(name)');

    if (warehouseId != null && warehouseId.isNotEmpty) {
      query = query.eq('warehouse_id', warehouseId);
    }
    if (search != null && search.isNotEmpty) {
      query = query.ilike('name', '%$search%');
    }

    final data = await query.order('name');
    return (data as List).map((json) => RawMaterial.fromMap(json)).toList();
  }

  static Future<RawMaterial?> getById(String id) async {
    final client = SupabaseService.client;
    final response = await client
        .from(_table)
        .select('*, warehouses(name)')
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return RawMaterial.fromMap(response);
  }

  static Future<RawMaterial> create({
    required String name,
    required String unit,
    String? warehouseId,
    double quantity = 0,
    double minQuantity = 0,
    double unitCost = 0,
  }) async {
    final client = SupabaseService.client;

    final insertMap = {
      'name': name.trim(),
      'unit': unit,
      if (warehouseId != null && warehouseId.isNotEmpty) 'warehouse_id': warehouseId,
      'quantity': quantity,
      'min_quantity': minQuantity,
      'unit_cost': unitCost,
    };

    final response = await client.from(_table).insert(insertMap).select('*, warehouses(name)').single();

    await SupabaseService.logAudit(
      action: 'create',
      tableName: _table,
      recordId: response['id'],
      newData: insertMap,
      description: 'Matière créée : $name',
    );

    return RawMaterial.fromMap(response);
  }

  static Future<RawMaterial> update({
    required String id,
    required String name,
    required String unit,
    String? warehouseId,
    double quantity = 0,
    double minQuantity = 0,
    double unitCost = 0,
  }) async {
    final client = SupabaseService.client;

    final old = await client.from(_table).select().eq('id', id).single();

    final updateMap = {
      'name': name.trim(),
      'unit': unit,
      'warehouse_id': warehouseId?.trim().isEmpty == true ? null : warehouseId?.trim(),
      'quantity': quantity,
      'min_quantity': minQuantity,
      'unit_cost': unitCost,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await client.from(_table).update(updateMap).eq('id', id);

    await SupabaseService.logAudit(
      action: 'update',
      tableName: _table,
      recordId: id,
      oldData: old,
      newData: updateMap,
      description: 'Matière modifiée : $name',
    );

    final updated = await client.from(_table).select('*, warehouses(name)').eq('id', id).single();
    return RawMaterial.fromMap(updated);
  }

  static Future<void> updateStock(String id, double quantity, String name) async {
    final client = SupabaseService.client;

    await client
        .from(_table)
        .update({'quantity': quantity, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);

    await SupabaseService.logAudit(
      action: 'update',
      tableName: _table,
      recordId: id,
      newData: {'quantity': quantity},
      description: 'Stock mis à jour : $name → $quantity',
    );
  }

  static Future<List<RawMaterial>> getLowStock() async {
    final client = SupabaseService.client;
    final data = await client
        .from(_table)
        .select('*, warehouses(name)')
        .order('quantity');

    final all = (data as List).map((json) => RawMaterial.fromMap(json)).toList();
    return all.where((m) => m.quantity <= m.minQuantity).toList();
  }
}

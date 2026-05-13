import '../../../core/services/supabase_service.dart';
import 'production_order_model.dart';

class ProductionOrderRepository {
  static const _table = 'production_orders';
  static const _logsTable = 'production_logs';
  static const _entriesTable = 'production_stock_entries';
  static const _costTable = 'production_cost_summaries';
  static const _inventoryTable = 'inventory';

  static Future<List<ProductionOrder>> getAll({
    String? status,
    String? warehouseId,
  }) async {
    final client = SupabaseService.client;
    var query = client
        .from(_table)
        .select('*, warehouses(name), products(name), recipes(name), profiles(full_name)');

    if (status != null && status.isNotEmpty && status != 'all') {
      query = query.eq('status', status);
    }
    if (warehouseId != null && warehouseId.isNotEmpty) {
      query = query.eq('warehouse_id', warehouseId);
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((json) => ProductionOrder.fromMap(json)).toList();
  }

  static Future<ProductionOrder?> getById(String id) async {
    final client = SupabaseService.client;
    final response = await client
        .from(_table)
        .select('*, warehouses(name), products(name), recipes(name), profiles(full_name)')
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return ProductionOrder.fromMap(response);
  }

  static Future<ProductionOrder> create({
    required String? warehouseId,
    required String? productId,
    required String? recipeId,
    required int orderedQty,
    DateTime? targetDate,
    String? notes,
  }) async {
    final client = SupabaseService.client;

    final insertMap = {
      'warehouse_id': warehouseId,
      'product_id': productId,
      'recipe_id': recipeId,
      'ordered_qty': orderedQty,
      if (targetDate != null) 'target_date': targetDate.toIso8601String().split('T').first,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    final response = await client
        .from(_table)
        .insert(insertMap)
        .select('*, warehouses(name), products(name), recipes(name), profiles(full_name)')
        .single();

    await SupabaseService.logAudit(
      action: 'create',
      tableName: _table,
      recordId: response['id'],
      newData: insertMap,
      description: 'Ordre de production créé',
    );

    return ProductionOrder.fromMap(response);
  }

  static Future<void> updateStatus(String id, String status, String notes) async {
    final client = SupabaseService.client;

    final old = await client.from(_table).select().eq('id', id).single();

    await client
        .from(_table)
        .update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);

    await SupabaseService.logAudit(
      action: 'update',
      tableName: _table,
      recordId: id,
      oldData: old,
      newData: {'status': status},
      description: 'Ordre ${notes.isNotEmpty ? notes : status}',
    );
  }

  static Future<void> addWorkerLog({
    required String orderId,
    required String? workerId,
    required String? warehouseId,
    required int quantity,
    DateTime? logDate,
    String? notes,
  }) async {
    final client = SupabaseService.client;

    await client.from(_logsTable).insert({
      'order_id': orderId,
      'worker_id': workerId,
      'warehouse_id': warehouseId,
      'quantity': quantity,
      if (logDate != null) 'log_date': logDate.toIso8601String().split('T').first,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    });

    final order = await client
        .from(_table)
        .select('produced_qty')
        .eq('id', orderId)
        .single();

    final currentProduced = (order['produced_qty'] as num?)?.toInt() ?? 0;
    final newProduced = currentProduced + quantity;

    await client
        .from(_table)
        .update({
          'produced_qty': newProduced,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', orderId);
  }

  static Future<void> enterStock({
    required String orderId,
    required String? warehouseId,
    required String? productId,
    required int quantity,
    required double unitCost,
    String? notes,
  }) async {
    final client = SupabaseService.client;
    final whId = warehouseId ?? '';
    final pId = productId ?? '';

    await client.from(_entriesTable).insert({
      'order_id': orderId,
      'warehouse_id': whId,
      'product_id': pId,
      'quantity': quantity,
      'unit_cost': unitCost,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    });

    await client
        .from(_table)
        .update({
          'entered_stock_qty': quantity,
          'status': 'completed',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', orderId);

    final existing = await client
        .from(_inventoryTable)
        .select('id, quantity')
        .eq('warehouse_id', whId)
        .eq('product_id', pId)
        .maybeSingle();

    if (existing != null) {
      final currentQty = (existing['quantity'] as num?)?.toInt() ?? 0;
      await client
          .from(_inventoryTable)
          .update({'quantity': currentQty + quantity, 'last_updated': DateTime.now().toIso8601String()})
          .eq('id', existing['id']);
    } else {
      await client.from(_inventoryTable).insert({
        'warehouse_id': warehouseId,
        'product_id': productId,
        'quantity': quantity,
      });
    }

    await SupabaseService.logAudit(
      action: 'approve',
      tableName: _table,
      recordId: orderId,
      description: 'Entrée en stock : $quantity unités, coût unitaire $unitCost',
    );
  }

  static Future<Map<String, dynamic>?> getCostSummary(String orderId) async {
    final client = SupabaseService.client;
    final response = await client
        .from(_costTable)
        .select()
        .eq('order_id', orderId)
        .maybeSingle();
    return response;
  }

  static Future<List<Map<String, dynamic>>> getLogs(String orderId) async {
    final client = SupabaseService.client;
    final data = await client
        .from(_logsTable)
        .select('*, profiles(full_name)')
        .eq('order_id', orderId)
        .order('log_date', ascending: false)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data as List);
  }
}

import '../../../core/services/supabase_service.dart';
import 'purchase_order_model.dart';
import 'purchase_order_item_model.dart';

class PurchaseOrderRepository {
  static const _table = 'purchase_orders';
  static const _itemsTable = 'purchase_order_items';
  static const _paymentsTable = 'supplier_payments';
  static const _suppliersTable = 'suppliers';
  static const _rawMaterialsTable = 'raw_materials';
  static const _inventoryTable = 'inventory';

  static Future<List<PurchaseOrder>> getAll({
    String? supplierId,
    String? status,
  }) async {
    final client = SupabaseService.client;
    var query = client
        .from(_table)
        .select('*, suppliers(name), warehouses(name), profiles(full_name)');

    if (supplierId != null && supplierId.isNotEmpty) {
      query = query.eq('supplier_id', supplierId);
    }
    if (status != null && status.isNotEmpty && status != 'all') {
      query = query.eq('status', status);
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((json) => PurchaseOrder.fromMap(json)).toList();
  }

  static Future<PurchaseOrder?> getById(String id) async {
    final client = SupabaseService.client;
    final response = await client
        .from(_table)
        .select('*, suppliers(name), warehouses(name), profiles(full_name)')
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return PurchaseOrder.fromMap(response);
  }

  static Future<List<PurchaseOrderItem>> getItems(String orderId) async {
    final client = SupabaseService.client;
    final data = await client
        .from(_itemsTable)
        .select('*, raw_materials(name), products(name)')
        .eq('purchase_order_id', orderId)
        .order('id');
    return (data as List)
        .map((json) => PurchaseOrderItem.fromMap(json))
        .toList();
  }

  static Future<PurchaseOrder> create({
    required String supplierId,
    String? warehouseId,
    required String orderType,
    required double totalAmount,
    double paidAmount = 0,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final client = SupabaseService.client;

    final insertMap = {
      'supplier_id': supplierId,
      if (warehouseId != null && warehouseId.isNotEmpty)
        'warehouse_id': warehouseId,
      'order_type': orderType,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    final response =
        await client.from(_table).insert(insertMap).select().single();

    final orderId = response['id'] as String;

    if (items.isNotEmpty) {
      final itemMaps = items.map((item) {
        final map = {
          'purchase_order_id': orderId,
          'item_type': item['item_type'],
          'quantity': item['quantity'],
          'unit_cost': item['unit_cost'],
        };
        if (item['item_type'] == 'raw_material') {
          map['raw_material_id'] = item['raw_material_id'];
        } else {
          map['product_id'] = item['product_id'];
        }
        return map;
      }).toList();

      await client.from(_itemsTable).insert(itemMaps);
    }

    await SupabaseService.logAudit(
      action: 'create',
      tableName: _table,
      recordId: orderId,
      newData: insertMap,
      description: 'Bon de commande créé',
    );

    if (paidAmount > 0) {
      await client.from(_paymentsTable).insert({
        'purchase_order_id': orderId,
        'supplier_id': supplierId,
        'amount': paidAmount,
        'payment_method': 'cash',
      });

      final supplier = await client
          .from(_suppliersTable)
          .select('total_debt')
          .eq('id', supplierId)
          .single();
      final currentDebt = (supplier['total_debt'] as num?)?.toDouble() ?? 0;
      final newDebt = currentDebt + (totalAmount - paidAmount);

      await client
          .from(_suppliersTable)
          .update({'total_debt': newDebt})
          .eq('id', supplierId);

      await SupabaseService.logAudit(
        action: 'payment',
        tableName: _paymentsTable,
        description: 'Paiement à la création: $paidAmount DZD',
      );
    } else {
      final supplier = await client
          .from(_suppliersTable)
          .select('total_debt')
          .eq('id', supplierId)
          .single();
      final currentDebt = (supplier['total_debt'] as num?)?.toDouble() ?? 0;
      final newDebt = currentDebt + totalAmount;

      await client
          .from(_suppliersTable)
          .update({'total_debt': newDebt})
          .eq('id', supplierId);
    }

    final full = await client
        .from(_table)
        .select('*, suppliers(name), warehouses(name), profiles(full_name)')
        .eq('id', orderId)
        .single();
    return PurchaseOrder.fromMap(full);
  }

  static Future<void> updateStatus(
      String id, String status, String notes) async {
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
      description: 'Commande ${notes.isNotEmpty ? notes : status}',
    );
  }

  static Future<void> receive({
    required String orderId,
    String? warehouseId,
  }) async {
    final client = SupabaseService.client;

    final items = await client
        .from(_itemsTable)
        .select()
        .eq('purchase_order_id', orderId);

    for (final item in items as List) {
      final itemType = item['item_type'] as String;
      final qty = (item['quantity'] as num?)?.toDouble() ?? 0;

      if (itemType == 'raw_material') {
        final rmId = item['raw_material_id'] as String?;
        if (rmId != null) {
          final existing = await client
              .from(_rawMaterialsTable)
              .select('id, quantity')
              .eq('id', rmId)
              .single();
          final currentQty = (existing['quantity'] as num?)?.toDouble() ?? 0;
          await client
              .from(_rawMaterialsTable)
              .update({'quantity': currentQty + qty})
              .eq('id', rmId);
        }
      } else if (itemType == 'product' || itemType == 'finished_product') {
        final pId = item['product_id'] as String?;
        if (pId != null && warehouseId != null) {
          final existingInv = await client
              .from(_inventoryTable)
              .select('id, quantity')
              .eq('warehouse_id', warehouseId)
              .eq('product_id', pId)
              .maybeSingle();

          if (existingInv != null) {
            final currentQty =
                (existingInv['quantity'] as num?)?.toInt() ?? 0;
            await client
                .from(_inventoryTable)
                .update({'quantity': currentQty + qty.toInt()})
                .eq('id', existingInv['id']);
          } else {
            await client.from(_inventoryTable).insert({
              'warehouse_id': warehouseId,
              'product_id': pId,
              'quantity': qty.toInt(),
            });
          }
        }
      }
    }

    await client
        .from(_table)
        .update({
          'status': 'received',
          'received_date': DateTime.now().toIso8601String().split('T').first,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', orderId);

    await SupabaseService.logAudit(
      action: 'approve',
      tableName: _table,
      recordId: orderId,
      description: 'Commande reçue en stock',
    );
  }

  static Future<void> recordPayment({
    required String orderId,
    required String supplierId,
    required double amount,
    required String paymentMethod,
    String? notes,
  }) async {
    final client = SupabaseService.client;

    await client.from(_paymentsTable).insert({
      'purchase_order_id': orderId,
      'supplier_id': supplierId,
      'amount': amount,
      'payment_method': paymentMethod,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    });

    final order = await client
        .from(_table)
        .select('paid_amount, total_amount')
        .eq('id', orderId)
        .single();

    final currentPaid = (order['paid_amount'] as num?)?.toDouble() ?? 0;
    final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0;
    final newPaid = currentPaid + amount;

    String newStatus;
    if (newPaid >= totalAmount) {
      newStatus = 'received';
    } else if (newPaid > 0) {
      newStatus = 'partial';
    } else {
      newStatus = 'pending';
    }

    await client
        .from(_table)
        .update({
          'paid_amount': newPaid,
          'status': newStatus,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', orderId);

    final supplier = await client
        .from(_suppliersTable)
        .select('total_debt')
        .eq('id', supplierId)
        .single();
    final currentDebt =
        (supplier['total_debt'] as num?)?.toDouble() ?? 0;
    final newDebt = (currentDebt - amount).clamp(0, double.infinity);

    await client
        .from(_suppliersTable)
        .update({
          'total_debt': newDebt,
        })
        .eq('id', supplierId);

    await SupabaseService.logAudit(
      action: 'payment',
      tableName: _paymentsTable,
      description: 'Paiement fournisseur: $amount DZD',
    );
  }

  static Future<List<Map<String, dynamic>>> getPayments(String orderId) async {
    final client = SupabaseService.client;
    final data = await client
        .from(_paymentsTable)
        .select('*, profiles(full_name)')
        .eq('purchase_order_id', orderId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data as List);
  }

  static Future<List<Map<String, dynamic>>> getOrdersBySupplier(
      String supplierId) async {
    final client = SupabaseService.client;
    final data = await client
        .from(_table)
        .select('*, warehouses(name)')
        .eq('supplier_id', supplierId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data as List);
  }
}

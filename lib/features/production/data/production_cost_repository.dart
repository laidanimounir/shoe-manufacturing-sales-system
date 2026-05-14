import '../../../core/services/supabase_service.dart';
import '../../../features/production/data/production_cost_item_model.dart';

class ProductionCostRepository {
  static const _costItemsTable = 'production_cost_items';
  static const _costSummaryTable = 'production_cost_summaries';
  static const _productionOrdersTable = 'production_orders';

  static Future<List<ProductionCostItem>> getCostItems(
      String productionOrderId) async {
    final client = SupabaseService.client;
    final data = await client
        .from(_costItemsTable)
        .select()
        .eq('production_order_id', productionOrderId)
        .order('cost_type')
        .order('created_at');
    return (data as List)
        .map((json) => ProductionCostItem.fromMap(json))
        .toList();
  }

  static Future<void> addCostItem({
    required String productionOrderId,
    required String costType,
    required String label,
    required double amount,
    double? unitAmount,
    double? quantity,
  }) async {
    final client = SupabaseService.client;
    await client.from(_costItemsTable).insert({
      'production_order_id': productionOrderId,
      'cost_type': costType,
      'label': label,
      'amount': amount,
      if (unitAmount != null) 'unit_amount': unitAmount,
      if (quantity != null) 'quantity': quantity,
      'is_auto': false,
      'is_editable': true,
    });

    await recalculateSummary(productionOrderId);
  }

  static Future<void> updateCostItem({
    required String id,
    required double amount,
    String? label,
    String? productionOrderId,
  }) async {
    final client = SupabaseService.client;
    final update = <String, dynamic>{'amount': amount};
    if (label != null) update['label'] = label;

    final item = await client
        .from(_costItemsTable)
        .select('production_order_id')
        .eq('id', id)
        .single();
    final orderId = item['production_order_id'] as String;

    await client.from(_costItemsTable).update(update).eq('id', id);
    await recalculateSummary(orderId);
  }

  static Future<void> deleteCostItem(String id) async {
    final client = SupabaseService.client;
    final item = await client
        .from(_costItemsTable)
        .select('production_order_id')
        .eq('id', id)
        .single();
    final orderId = item['production_order_id'] as String;

    await client.from(_costItemsTable).delete().eq('id', id);
    await recalculateSummary(orderId);
  }

  static Future<void> recalculateSummary(String productionOrderId) async {
    final client = SupabaseService.client;

    final items = await client
        .from(_costItemsTable)
        .select('cost_type, amount')
        .eq('production_order_id', productionOrderId);

    double material = 0, labor = 0, other = 0;
    for (final item in items as List) {
      final amount = (item['amount'] as num?)?.toDouble() ?? 0;
      switch (item['cost_type'] as String? ?? '') {
        case 'material': material += amount; break;
        case 'labor': labor += amount; break;
        case 'other': other += amount; break;
      }
    }

    final order = await client
        .from(_productionOrdersTable)
        .select('warehouse_id, produced_qty, product_id')
        .eq('id', productionOrderId)
        .single();

    final producedQty =
        (order['produced_qty'] as num?)?.toInt() ?? 0;
    final totalCost = material + labor + other;
    final unitCost =
        producedQty > 0 ? totalCost / producedQty : 0;

    final existing = await client
        .from(_costSummaryTable)
        .select('id')
        .eq('order_id', productionOrderId)
        .maybeSingle();

    if (existing != null) {
      await client.from(_costSummaryTable).update({
        'total_material_cost': material,
        'total_labor_cost': labor,
        'total_cost': totalCost,
        'unit_cost': unitCost,
        'total_pairs_produced': producedQty,
        'summary_date': DateTime.now().toIso8601String().split('T').first,
      }).eq('id', existing['id']);
    } else {
      await client.from(_costSummaryTable).insert({
        'order_id': productionOrderId,
        'warehouse_id': order['warehouse_id'],
        'summary_date': DateTime.now().toIso8601String().split('T').first,
        'total_pairs_produced': producedQty,
        'total_material_cost': material,
        'total_labor_cost': labor,
        'total_cost': totalCost,
        'unit_cost': unitCost,
      });
    }
  }

  static Future<void> syncLaborCost(int year, int month) async {
    final client = SupabaseService.client;

    final paidSheets = await client
        .from('salary_sheets')
        .select('net_salary')
        .eq('year', year)
        .eq('month', month)
        .eq('status', 'paid');

    double totalLaborPaid = 0;
    for (final s in paidSheets as List) {
      totalLaborPaid += (s['net_salary'] as num?)?.toDouble() ?? 0;
    }

    if (totalLaborPaid <= 0) return;

    final activeOrders = await client
        .from('production_orders')
        .select('id, produced_qty')
        .inFilter('status', ['in_progress', 'completed']);

    int totalUnits = 0;
    for (final o in activeOrders as List) {
      totalUnits += (o['produced_qty'] as num?)?.toInt() ?? 0;
    }

    if (totalUnits <= 0) return;

    final laborPerUnit = totalLaborPaid / totalUnits;

    for (final o in activeOrders as List) {
      final orderId = o['id'] as String;
      final qty = (o['produced_qty'] as num?)?.toInt() ?? 0;
      final laborAmount = laborPerUnit * qty;

      final existingItem = await client
          .from(_costItemsTable)
          .select('id')
          .eq('production_order_id', orderId)
          .eq('cost_type', 'labor')
          .eq('is_auto', true)
          .maybeSingle();

      if (existingItem != null) {
        await client.from(_costItemsTable).update({
          'amount': laborAmount,
          'unit_amount': laborPerUnit,
        }).eq('id', existingItem['id']);
      } else {
        final monthLabel = ['','Janvier','Février','Mars','Avril','Mai','Juin','Juillet','Août','Septembre','Octobre','Novembre','Décembre'][month];
        await client.from(_costItemsTable).insert({
          'production_order_id': orderId,
          'cost_type': 'labor',
          'label': 'Salaires $monthLabel $year',
          'amount': laborAmount,
          'unit_amount': laborPerUnit,
          'quantity': qty,
          'is_auto': true,
          'is_editable': true,
        });
      }

      await recalculateSummary(orderId);
    }
  }
}

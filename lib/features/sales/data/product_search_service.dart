import '../../../core/services/supabase_service.dart';

class SaleProduct {
  final String id;
  final String name;
  final String? sku;
  final String? barcode;
  final double sellingPrice;
  final int availableQty;
  final String sourceType;
  final double unitCost;

  const SaleProduct({
    required this.id,
    required this.name,
    this.sku,
    this.barcode,
    this.sellingPrice = 0,
    this.availableQty = 0,
    this.sourceType = 'manufactured',
    this.unitCost = 0,
  });
}

class ProductSearchService {
  static Future<List<SaleProduct>> searchForSale({
    required String warehouseId,
    String? query,
  }) async {
    final client = SupabaseService.client;

    var invQuery = client
        .from('inventory')
        .select('quantity, product_id, products!inner(id, name, sku, barcode, selling_price, is_active)')
        .eq('products.is_active', true);

    if (warehouseId.isNotEmpty) {
      invQuery = invQuery.eq('warehouse_id', warehouseId);
    }

    if (query != null && query.isNotEmpty) {
      invQuery = invQuery.or(
        'products.name.ilike.%$query%,products.sku.ilike.%$query%,products.barcode.ilike.%$query%',
      );
    }

    final rows = await invQuery;
    final results = <SaleProduct>[];

    for (final row in rows as List) {
      final p = row['products'] as Map;
      final pId = p['id'] as String;
      final name = p['name'] as String;
      final sku = p['sku'] as String?;
      final barcode = p['barcode'] as String?;
      final price = (p['selling_price'] as num?)?.toDouble() ?? 0;
      final qty = (row['quantity'] as num?)?.toInt() ?? 0;

      String sourceType = 'purchased';
      double unitCost = 0.0;

      final pseCheck = await client
          .from('production_stock_entries')
          .select('id')
          .eq('product_id', pId)
          .limit(1);
      if ((pseCheck as List).isNotEmpty) {
        sourceType = 'manufactured';
        final costData = await client
            .from('production_cost_summaries')
            .select('unit_cost')
            .eq('order_id', (pseCheck).first['order_id'])
            .limit(1);
        if ((costData as List).isNotEmpty) {
          unitCost = (costData.first['unit_cost'] as num?)?.toDouble() ?? 0;
        }
      } else {
        final purchases = await client
            .from('purchase_order_items')
            .select('unit_cost')
            .eq('product_id', pId)
            .eq('item_type', 'product')
            .order('id', ascending: false)
            .limit(1);
        if ((purchases as List).isNotEmpty) {
          sourceType = 'purchased';
          unitCost = (purchases.first['unit_cost'] as num?)?.toDouble() ?? 0;
        }
      }

      results.add(SaleProduct(
        id: pId,
        name: name,
        sku: sku,
        barcode: barcode,
        sellingPrice: price,
        availableQty: qty,
        sourceType: sourceType,
        unitCost: unitCost,
      ));
    }

    return results;
  }

  static Future<SaleProduct?> getByBarcode({
    required String barcode,
    required String warehouseId,
  }) async {
    final client = SupabaseService.client;

    final row = await client
        .from('inventory')
        .select('quantity, product_id, products!inner(id, name, sku, barcode, selling_price, is_active)')
        .eq('products.barcode', barcode)
        .eq('products.is_active', true)
        .eq('warehouse_id', warehouseId)
        .maybeSingle();

    if (row == null) return null;

    final p = row['products'] as Map;
    final qty = (row['quantity'] as num?)?.toInt() ?? 0;

    return SaleProduct(
      id: p['id'] as String,
      name: p['name'] as String,
      sku: p['sku'] as String?,
      barcode: p['barcode'] as String?,
      sellingPrice: (p['selling_price'] as num?)?.toDouble() ?? 0,
      availableQty: qty,
      sourceType: 'manufactured',
      unitCost: 0,
    );
  }
}

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

    var productQuery = client
        .from('products')
        .select('id, name, sku, barcode, selling_price')
        .eq('is_active', true);

    if (query != null && query.isNotEmpty) {
      productQuery = productQuery.or('name.ilike.%$query%,sku.ilike.%$query%');
    }

    productQuery = productQuery.order('name');
    final products = await productQuery;
    final results = <SaleProduct>[];

    for (final p in products as List) {
      final pId = p['id'] as String;
      final name = p['name'] as String;
      final sku = p['sku'] as String?;
      final barcode = p['barcode'] as String?;
      final price = (p['selling_price'] as num?)?.toDouble() ?? 0;

      final invData = await client
          .from('inventory')
          .select('quantity')
          .eq('warehouse_id', warehouseId)
          .eq('product_id', pId)
          .maybeSingle();
      final qty = (invData?['quantity'] as num?)?.toInt() ?? 0;

      String sourceType = 'manufactured';
      double unitCost = 0.0;

      final costData = await client
          .from('production_cost_summaries')
          .select('unit_cost')
          .eq('warehouse_id', warehouseId)
          .order('created_at', ascending: false)
          .limit(1);

      if ((costData as List).isNotEmpty) {
        sourceType = 'manufactured';
        unitCost = (costData.first['unit_cost'] as num?)?.toDouble() ?? 0;
      } else {
        final purchases = await client
            .from('purchase_order_items')
            .select('unit_cost')
            .eq('product_id', pId)
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

    final pData = await client
        .from('products')
        .select('id, name, sku, barcode, selling_price')
        .eq('barcode', barcode)
        .eq('is_active', true)
        .maybeSingle();

    if (pData == null) return null;

    final pId = pData['id'] as String;
    final invData = await client
        .from('inventory')
        .select('quantity')
        .eq('warehouse_id', warehouseId)
        .eq('product_id', pId)
        .maybeSingle();
    final qty = (invData?['quantity'] as num?)?.toInt() ?? 0;

    return SaleProduct(
      id: pId,
      name: pData['name'] as String,
      sku: pData['sku'] as String?,
      barcode: pData['barcode'] as String?,
      sellingPrice: (pData['selling_price'] as num?)?.toDouble() ?? 0,
      availableQty: qty,
      sourceType: 'manufactured',
      unitCost: 0,
    );
  }
}

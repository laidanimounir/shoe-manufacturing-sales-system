import '../../../core/services/supabase_service.dart';

class SaleProduct {
  final String id;
  final String name;
  final String? sku;
  final String? barcode;
  final double sellingPrice;
  final double availableQty;
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
        .select('*')
        .eq('is_active', true);

    if (query != null && query.isNotEmpty) {
      productQuery = productQuery.or(
        'name.ilike.%$query%,sku.ilike.%$query%,barcode.ilike.%$query%',
      );
    }

    final productsData = await productQuery;
    if ((productsData as List).isEmpty) return [];

    final inventoryData = await client
        .from('inventory')
        .select('product_id, quantity')
        .eq('warehouse_id', warehouseId);

    final inventoryMap = <String, double>{};
    for (final row in inventoryData as List) {
      final pid = row['product_id'] as String;
      final qty = (row['quantity'] as num?)?.toDouble() ?? 0;
      inventoryMap[pid] = qty;
    }

    final manufacturedData = await client
        .from('production_stock_entries')
        .select('product_id');
    final manufacturedIds = (manufacturedData as List)
        .map((r) => r['product_id'] as String)
        .toSet();

    final purchasedData = await client
        .from('purchase_order_items')
        .select('product_id')
        .eq('item_type', 'product');
    final purchasedIds = (purchasedData as List)
        .map((r) => r['product_id'] as String)
        .toSet();

    final results = <SaleProduct>[];
    for (final p in (productsData as List)) {
      final pId = p['id'] as String;

      String sourceType = 'purchased';
      if (manufacturedIds.contains(pId)) {
        sourceType = 'manufactured';
      } else if (purchasedIds.contains(pId)) {
        sourceType = 'purchased';
      }

      double unitCost = 0;
      if (sourceType == 'manufactured') {
        final costData = await client
            .from('production_stock_entries')
            .select('unit_cost')
            .eq('product_id', pId)
            .order('created_at', ascending: false)
            .limit(1);
        if ((costData as List).isNotEmpty) {
          unitCost = (costData.first['unit_cost'] as num?)?.toDouble() ?? 0;
        }
      } else if (sourceType == 'purchased') {
        final costData = await client
            .from('purchase_order_items')
            .select('unit_cost')
            .eq('product_id', pId)
            .eq('item_type', 'product')
            .order('id', ascending: false)
            .limit(1);
        if ((costData as List).isNotEmpty) {
          unitCost = (costData.first['unit_cost'] as num?)?.toDouble() ?? 0;
        }
      }

      results.add(SaleProduct(
        id: pId,
        name: p['name'] as String,
        sku: p['sku'] as String?,
        barcode: p['barcode'] as String?,
        sellingPrice: (p['selling_price'] as num?)?.toDouble() ?? 0,
        availableQty: inventoryMap[pId] ?? 0,
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
        .select('*')
        .eq('barcode', barcode)
        .eq('is_active', true)
        .maybeSingle();

    if (pData == null) return null;

    final pId = pData['id'] as String;

    final inv = await client
        .from('inventory')
        .select('quantity')
        .eq('product_id', pId)
        .eq('warehouse_id', warehouseId)
        .maybeSingle();

    final manufacturedCheck = await client
        .from('production_stock_entries')
        .select('id')
        .eq('product_id', pId)
        .limit(1);

    return SaleProduct(
      id: pId,
      name: pData['name'] as String,
      sku: pData['sku'] as String?,
      barcode: pData['barcode'] as String?,
      sellingPrice: (pData['selling_price'] as num?)?.toDouble() ?? 0,
      availableQty: (inv?['quantity'] as num?)?.toDouble() ?? 0,
      sourceType: (manufacturedCheck as List).isNotEmpty ? 'manufactured' : 'purchased',
      unitCost: 0,
    );
  }
}

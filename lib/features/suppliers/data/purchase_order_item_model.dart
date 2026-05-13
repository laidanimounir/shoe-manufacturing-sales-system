class PurchaseOrderItem {
  final String id;
  final String purchaseOrderId;
  final String itemType;
  final String? rawMaterialId;
  final String? rawMaterialName;
  final String? productId;
  final String? productName;
  final double quantity;
  final double unitCost;
  final double totalCost;

  const PurchaseOrderItem({
    required this.id,
    required this.purchaseOrderId,
    required this.itemType,
    this.rawMaterialId,
    this.rawMaterialName,
    this.productId,
    this.productName,
    this.quantity = 0,
    this.unitCost = 0,
    this.totalCost = 0,
  });

  factory PurchaseOrderItem.fromMap(Map<String, dynamic> map) {
    String? rawMaterialName;
    final rm = map['raw_materials'];
    if (rm is Map) {
      rawMaterialName = rm['name'] as String?;
    }

    String? productName;
    final p = map['products'];
    if (p is Map) {
      productName = p['name'] as String?;
    }

    return PurchaseOrderItem(
      id: map['id'] as String,
      purchaseOrderId: map['purchase_order_id'] as String,
      itemType: map['item_type'] as String,
      rawMaterialId: map['raw_material_id'] as String?,
      rawMaterialName: rawMaterialName,
      productId: map['product_id'] as String?,
      productName: productName,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      unitCost: (map['unit_cost'] as num?)?.toDouble() ?? 0,
      totalCost: (map['total_cost'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'purchase_order_id': purchaseOrderId,
      'item_type': itemType,
      if (rawMaterialId != null) 'raw_material_id': rawMaterialId,
      if (productId != null) 'product_id': productId,
      'quantity': quantity,
      'unit_cost': unitCost,
    };
  }

  String get itemName =>
      itemType == 'raw_material' ? rawMaterialName ?? '' : productName ?? '';

  @override
  String toString() =>
      'PurchaseOrderItem($itemName, $quantity x $unitCost)';
}

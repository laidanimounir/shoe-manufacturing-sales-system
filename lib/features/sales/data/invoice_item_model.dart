class InvoiceItem {
  final String id;
  final String invoiceId;
  final String? productId;
  final String? productName;
  final String? productSku;
  final String sourceType;
  final int quantity;
  final double unitPrice;
  final double unitCost;
  final double subtotal;

  const InvoiceItem({
    required this.id,
    required this.invoiceId,
    this.productId,
    this.productName,
    this.productSku,
    this.sourceType = 'manufactured',
    this.quantity = 0,
    this.unitPrice = 0,
    this.unitCost = 0,
    this.subtotal = 0,
  });

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    String? productName;
    String? productSku;
    final p = map['products'];
    if (p is Map) {
      productName = p['name'] as String?;
      productSku = p['sku'] as String?;
    }

    return InvoiceItem(
      id: map['id'] as String,
      invoiceId: map['invoice_id'] as String,
      productId: map['product_id'] as String?,
      productName: productName,
      productSku: productSku,
      sourceType: map['source_type'] as String? ?? 'manufactured',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0,
      unitCost: (map['unit_cost'] as num?)?.toDouble() ?? 0,
      subtotal: (map['total_price'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoice_id': invoiceId,
      'product_id': productId,
      'source_type': sourceType,
      'quantity': quantity,
      'unit_price': unitPrice,
      'unit_cost': unitCost,
    };
  }

  double get marginAmount => unitPrice - unitCost;
  double get marginPercent =>
      unitCost > 0 ? ((unitPrice - unitCost) / unitCost * 100) : 0;

  @override
  String toString() => 'InvoiceItem($productName, $quantity x $unitPrice)';
}

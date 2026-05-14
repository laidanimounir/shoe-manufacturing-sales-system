class ProductionCostItem {
  final String id;
  final String productionOrderId;
  final String costType;
  final String label;
  final double amount;
  final double? unitAmount;
  final double? quantity;
  final bool isAuto;
  final bool isEditable;
  final DateTime? createdAt;

  const ProductionCostItem({
    required this.id,
    required this.productionOrderId,
    required this.costType,
    required this.label,
    this.amount = 0,
    this.unitAmount,
    this.quantity,
    this.isAuto = true,
    this.isEditable = true,
    this.createdAt,
  });

  factory ProductionCostItem.fromMap(Map<String, dynamic> map) {
    return ProductionCostItem(
      id: map['id'] as String,
      productionOrderId: map['production_order_id'] as String,
      costType: map['cost_type'] as String,
      label: map['label'] as String,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      unitAmount: (map['unit_amount'] as num?)?.toDouble(),
      quantity: (map['quantity'] as num?)?.toDouble(),
      isAuto: map['is_auto'] as bool? ?? true,
      isEditable: map['is_editable'] as bool? ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'production_order_id': productionOrderId,
      'cost_type': costType,
      'label': label,
      'amount': amount,
      if (unitAmount != null) 'unit_amount': unitAmount,
      if (quantity != null) 'quantity': quantity,
      'is_auto': isAuto,
      'is_editable': isEditable,
    };
  }

  String get costTypeLabel {
    switch (costType) {
      case 'material': return 'Matières premières';
      case 'labor': return "Main d'œuvre";
      case 'other': return 'Autres charges';
      default: return costType;
    }
  }

  @override
  String toString() => 'ProductionCostItem($label, $amount)';
}

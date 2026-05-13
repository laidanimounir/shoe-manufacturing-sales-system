class RawMaterial {
  final String id;
  final String name;
  final String unit;
  final String? warehouseId;
  final String? warehouseName;
  final double quantity;
  final double minQuantity;
  final double unitCost;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RawMaterial({
    required this.id,
    required this.name,
    required this.unit,
    this.warehouseId,
    this.warehouseName,
    this.quantity = 0,
    this.minQuantity = 0,
    this.unitCost = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory RawMaterial.fromMap(Map<String, dynamic> map) {
    String? warehouseName;
    final wh = map['warehouses'];
    if (wh is Map) {
      warehouseName = wh['name'] as String?;
    }

    return RawMaterial(
      id: map['id'] as String,
      name: map['name'] as String,
      unit: map['unit'] as String,
      warehouseId: map['warehouse_id'] as String?,
      warehouseName: warehouseName,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      minQuantity: (map['min_quantity'] as num?)?.toDouble() ?? 0,
      unitCost: (map['unit_cost'] as num?)?.toDouble() ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'unit': unit,
      'warehouse_id': warehouseId,
      'quantity': quantity,
      'min_quantity': minQuantity,
      'unit_cost': unitCost,
    };
  }

  RawMaterial copyWith({
    String? id,
    String? name,
    String? unit,
    String? warehouseId,
    String? warehouseName,
    double? quantity,
    double? minQuantity,
    double? unitCost,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RawMaterial(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      unitCost: unitCost ?? this.unitCost,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get statusLabel {
    if (quantity <= 0) return 'Rupture';
    if (quantity <= minQuantity) return 'Stock bas';
    return 'OK';
  }

  @override
  String toString() => 'RawMaterial($name)';
}

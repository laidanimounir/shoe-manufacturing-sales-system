class RecipeItem {
  final String id;
  final String recipeId;
  final String rawMaterialId;
  final String? rawMaterialName;
  final String? rawMaterialUnit;
  final double quantityPerUnit;
  final String unit;

  const RecipeItem({
    required this.id,
    required this.recipeId,
    required this.rawMaterialId,
    this.rawMaterialName,
    this.rawMaterialUnit,
    required this.quantityPerUnit,
    required this.unit,
  });

  factory RecipeItem.fromMap(Map<String, dynamic> map) {
    String? rawMaterialName;
    String? rawMaterialUnit;
    final rm = map['raw_materials'];
    if (rm is Map) {
      rawMaterialName = rm['name'] as String?;
      rawMaterialUnit = rm['unit'] as String?;
    }

    return RecipeItem(
      id: map['id'] as String,
      recipeId: map['recipe_id'] as String,
      rawMaterialId: map['raw_material_id'] as String,
      rawMaterialName: rawMaterialName,
      rawMaterialUnit: rawMaterialUnit,
      quantityPerUnit: (map['quantity_per_unit'] as num?)?.toDouble() ?? 0,
      unit: map['unit'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipe_id': recipeId,
      'raw_material_id': rawMaterialId,
      'quantity_per_unit': quantityPerUnit,
      'unit': unit,
    };
  }

  RecipeItem copyWith({
    String? id,
    String? recipeId,
    String? rawMaterialId,
    String? rawMaterialName,
    String? rawMaterialUnit,
    double? quantityPerUnit,
    String? unit,
  }) {
    return RecipeItem(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      rawMaterialId: rawMaterialId ?? this.rawMaterialId,
      rawMaterialName: rawMaterialName ?? this.rawMaterialName,
      rawMaterialUnit: rawMaterialUnit ?? this.rawMaterialUnit,
      quantityPerUnit: quantityPerUnit ?? this.quantityPerUnit,
      unit: unit ?? this.unit,
    );
  }

  @override
  String toString() => 'RecipeItem($rawMaterialName, $quantityPerUnit $unit)';
}

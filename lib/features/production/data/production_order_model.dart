import 'package:intl/intl.dart';

class ProductionOrder {
  final String id;
  final String? warehouseId;
  final String? warehouseName;
  final String? productId;
  final String? productName;
  final String? recipeId;
  final String? recipeName;
  final int orderedQty;
  final int producedQty;
  final int enteredStockQty;
  final String status;
  final String? orderedBy;
  final String? orderedByName;
  final DateTime? targetDate;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductionOrder({
    required this.id,
    this.warehouseId,
    this.warehouseName,
    this.productId,
    this.productName,
    this.recipeId,
    this.recipeName,
    this.orderedQty = 0,
    this.producedQty = 0,
    this.enteredStockQty = 0,
    this.status = 'pending',
    this.orderedBy,
    this.orderedByName,
    this.targetDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductionOrder.fromMap(Map<String, dynamic> map) {
    String? warehouseName;
    final wh = map['warehouses'];
    if (wh is Map) {
      warehouseName = wh['name'] as String?;
    }

    String? productName;
    final p = map['products'];
    if (p is Map) {
      productName = p['name'] as String?;
    }

    String? recipeName;
    final r = map['recipes'];
    if (r is Map) {
      recipeName = r['name'] as String?;
    }

    String? orderedByName;
    final ob = map['profiles'];
    if (ob is Map) {
      orderedByName = ob['full_name'] as String?;
    }

    return ProductionOrder(
      id: map['id'] as String,
      warehouseId: map['warehouse_id'] as String?,
      warehouseName: warehouseName,
      productId: map['product_id'] as String?,
      productName: productName,
      recipeId: map['recipe_id'] as String?,
      recipeName: recipeName,
      orderedQty: (map['ordered_qty'] as num?)?.toInt() ?? 0,
      producedQty: (map['produced_qty'] as num?)?.toInt() ?? 0,
      enteredStockQty: (map['entered_stock_qty'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'pending',
      orderedBy: map['ordered_by'] as String?,
      orderedByName: orderedByName,
      targetDate: map['target_date'] != null
          ? DateTime.tryParse(map['target_date'].toString())
          : null,
      notes: map['notes'] as String?,
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
      'warehouse_id': warehouseId,
      'product_id': productId,
      'recipe_id': recipeId,
      'ordered_qty': orderedQty,
      'target_date': targetDate?.toIso8601String().split('T').first,
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
    };
  }

  ProductionOrder copyWith({
    String? id,
    String? warehouseId,
    String? warehouseName,
    String? productId,
    String? productName,
    String? recipeId,
    String? recipeName,
    int? orderedQty,
    int? producedQty,
    int? enteredStockQty,
    String? status,
    String? orderedBy,
    String? orderedByName,
    DateTime? targetDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductionOrder(
      id: id ?? this.id,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      recipeId: recipeId ?? this.recipeId,
      recipeName: recipeName ?? this.recipeName,
      orderedQty: orderedQty ?? this.orderedQty,
      producedQty: producedQty ?? this.producedQty,
      enteredStockQty: enteredStockQty ?? this.enteredStockQty,
      status: status ?? this.status,
      orderedBy: orderedBy ?? this.orderedBy,
      orderedByName: orderedByName ?? this.orderedByName,
      targetDate: targetDate ?? this.targetDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get formattedDate {
    if (createdAt == null) return '-';
    return DateFormat('dd/MM/yyyy').format(createdAt!);
  }

  @override
  String toString() => 'ProductionOrder(${productName ?? "N/A"})';
}

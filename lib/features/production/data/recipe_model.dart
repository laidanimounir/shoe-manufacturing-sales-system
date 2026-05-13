import 'package:intl/intl.dart';

class Recipe {
  final String id;
  final String productId;
  final String? productName;
  final String name;
  final bool isActive;
  final String? notes;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Recipe({
    required this.id,
    required this.productId,
    this.productName,
    required this.name,
    this.isActive = true,
    this.notes,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Recipe.fromMap(Map<String, dynamic> map) {
    String? productName;
    final p = map['products'];
    if (p is Map) {
      productName = p['name'] as String?;
    }

    return Recipe(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      productName: productName,
      name: map['name'] as String,
      isActive: map['is_active'] as bool? ?? true,
      notes: map['notes'] as String?,
      createdBy: map['created_by'] as String?,
      updatedBy: map['updated_by'] as String?,
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
      'product_id': productId,
      'name': name.trim(),
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
    };
  }

  Recipe copyWith({
    String? id,
    String? productId,
    String? productName,
    String? name,
    bool? isActive,
    String? notes,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get formattedDate {
    if (createdAt == null) return '-';
    return DateFormat('dd/MM/yyyy').format(createdAt!);
  }

  String get statusLabel => isActive ? 'Actif' : 'Inactif';

  @override
  String toString() => 'Recipe($name)';
}

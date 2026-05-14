import 'package:intl/intl.dart';

class Product {
  final String id;
  final String name;
  final String? category;
  final String? size;
  final String? color;
  final String? material;
  final String? sku;
  final String? barcode;
  final double sellingPrice;
  final String? imageUrl;
  final bool isActive;
  final double totalStock;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    required this.id,
    required this.name,
    this.category,
    this.size,
    this.color,
    this.material,
    this.sku,
    this.barcode,
    this.sellingPrice = 0,
    this.imageUrl,
    this.isActive = true,
    this.totalStock = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String?,
      size: map['size'] as String?,
      color: map['color'] as String?,
      material: map['material'] as String?,
      sku: map['sku'] as String?,
      barcode: map['barcode'] as String?,
      sellingPrice: (map['selling_price'] as num?)?.toDouble() ?? 0,
      imageUrl: map['image_url'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      totalStock: (map['total_stock'] as num?)?.toDouble() ?? 0,
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
      'category': category,
      'size': size,
      'color': color,
      'material': material,
      'sku': sku,
      'barcode': barcode,
      'selling_price': sellingPrice,
      'image_url': imageUrl,
      'is_active': isActive,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? category,
    String? size,
    String? color,
    String? material,
    String? sku,
    String? barcode,
    double? sellingPrice,
    String? imageUrl,
    bool? isActive,
    double? totalStock,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      size: size ?? this.size,
      color: color ?? this.color,
      material: material ?? this.material,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      totalStock: totalStock ?? this.totalStock,
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
  String toString() => 'Product($name)';
}

import 'package:intl/intl.dart';

class Supplier {
  final String id;
  final String name;
  final String? phone;
  final String? address;
  final String? city;
  final String supplyType;
  final double totalDebt;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Supplier({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.city,
    this.supplyType = 'raw_material',
    this.totalDebt = 0,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      city: map['city'] as String?,
      supplyType: map['supply_type'] as String? ?? 'raw_material',
      totalDebt: (map['total_debt'] as num?)?.toDouble() ?? 0,
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
      'name': name.trim(),
      'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
      'address': address?.trim().isEmpty == true ? null : address?.trim(),
      'city': city?.trim().isEmpty == true ? null : city?.trim(),
      'supply_type': supplyType,
    };
  }

  Supplier copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? city,
    String? supplyType,
    double? totalDebt,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      supplyType: supplyType ?? this.supplyType,
      totalDebt: totalDebt ?? this.totalDebt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get supplyTypeLabel {
    switch (supplyType) {
      case 'raw_material':
        return 'Matière première';
      case 'finished_product':
        return 'Produit fini';
      case 'both':
        return 'Les deux';
      default:
        return supplyType;
    }
  }

  String get formattedDate {
    if (createdAt == null) return '-';
    return DateFormat('dd/MM/yyyy').format(createdAt!);
  }

  @override
  String toString() => 'Supplier($name)';
}

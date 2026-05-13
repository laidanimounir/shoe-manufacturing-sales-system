import 'package:intl/intl.dart';

class Warehouse {
  final String id;
  final String name;
  final String? location;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Warehouse({
    required this.id,
    required this.name,
    this.location,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory Warehouse.fromMap(Map<String, dynamic> map) {
    return Warehouse(
      id: map['id'] as String,
      name: map['name'] as String,
      location: map['location'] as String?,
      isActive: map['is_active'] as bool? ?? true,
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
      'location': location,
      'is_active': isActive,
    };
  }

  Map<String, dynamic> toFullMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Warehouse copyWith({
    String? id,
    String? name,
    String? location,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Warehouse(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      isActive: isActive ?? this.isActive,
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
  String toString() => 'Warehouse($name)';
}

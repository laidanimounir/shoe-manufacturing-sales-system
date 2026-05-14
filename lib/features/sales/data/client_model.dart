import 'package:intl/intl.dart';

class Client {
  final String id;
  final String fullName;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String clientType;
  final double totalDebt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Client({
    required this.id,
    required this.fullName,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.clientType = 'wholesale',
    this.totalDebt = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] as String,
      fullName: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      city: map['city'] as String?,
      clientType: map['client_type'] as String? ?? 'wholesale',
      totalDebt: (map['total_debt'] as num?)?.toDouble() ?? 0,
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
      'name': fullName.trim(),
      'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
      'email': email?.trim().isEmpty == true ? null : email?.trim(),
      'address': address?.trim().isEmpty == true ? null : address?.trim(),
      'city': city?.trim().isEmpty == true ? null : city?.trim(),
      'client_type': clientType,
    };
  }

  Client copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? clientType,
    double? totalDebt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Client(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      clientType: clientType ?? this.clientType,
      totalDebt: totalDebt ?? this.totalDebt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get clientTypeLabel =>
      clientType == 'wholesale' ? 'Grossiste' : 'Détaillant';

  String get formattedDate {
    if (createdAt == null) return '-';
    return DateFormat('dd/MM/yyyy').format(createdAt!);
  }

  @override
  String toString() => 'Client($fullName)';
}

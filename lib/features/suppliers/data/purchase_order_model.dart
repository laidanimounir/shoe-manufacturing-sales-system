import 'package:intl/intl.dart';

class PurchaseOrder {
  final String id;
  final String supplierId;
  final String? supplierName;
  final String? warehouseId;
  final String? warehouseName;
  final String orderType;
  final double totalAmount;
  final double paidAmount;
  final double debtAmount;
  final String status;
  final String? orderedBy;
  final String? orderedByName;
  final DateTime? orderDate;
  final DateTime? receivedDate;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PurchaseOrder({
    required this.id,
    required this.supplierId,
    this.supplierName,
    this.warehouseId,
    this.warehouseName,
    this.orderType = 'raw_material',
    this.totalAmount = 0,
    this.paidAmount = 0,
    this.debtAmount = 0,
    this.status = 'pending',
    this.orderedBy,
    this.orderedByName,
    this.orderDate,
    this.receivedDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory PurchaseOrder.fromMap(Map<String, dynamic> map) {
    String? supplierName;
    final s = map['suppliers'];
    if (s is Map) {
      supplierName = s['name'] as String?;
    }

    String? warehouseName;
    final w = map['warehouses'];
    if (w is Map) {
      warehouseName = w['name'] as String?;
    }

    String? orderedByName;
    final p = map['profiles'];
    if (p is Map) {
      orderedByName = p['full_name'] as String?;
    }

    return PurchaseOrder(
      id: map['id'] as String,
      supplierId: map['supplier_id'] as String,
      supplierName: supplierName,
      warehouseId: map['warehouse_id'] as String?,
      warehouseName: warehouseName,
      orderType: map['order_type'] as String? ?? 'raw_material',
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0,
      debtAmount: (map['debt_amount'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'pending',
      orderedBy: map['ordered_by'] as String?,
      orderedByName: orderedByName,
      orderDate: map['order_date'] != null
          ? DateTime.tryParse(map['order_date'].toString())
          : null,
      receivedDate: map['received_date'] != null
          ? DateTime.tryParse(map['received_date'].toString())
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
      'supplier_id': supplierId,
      'warehouse_id': warehouseId,
      'order_type': orderType,
      'total_amount': totalAmount,
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
    };
  }

  PurchaseOrder copyWith({
    String? id,
    String? supplierId,
    String? supplierName,
    String? warehouseId,
    String? warehouseName,
    String? orderType,
    double? totalAmount,
    double? paidAmount,
    double? debtAmount,
    String? status,
    String? orderedBy,
    String? orderedByName,
    DateTime? orderDate,
    DateTime? receivedDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      orderType: orderType ?? this.orderType,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      debtAmount: debtAmount ?? this.debtAmount,
      status: status ?? this.status,
      orderedBy: orderedBy ?? this.orderedBy,
      orderedByName: orderedByName ?? this.orderedByName,
      orderDate: orderDate ?? this.orderDate,
      receivedDate: receivedDate ?? this.receivedDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get formattedDate {
    if (createdAt == null) return '-';
    return DateFormat('dd/MM/yyyy').format(createdAt!);
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'received':
        return 'Reçu';
      case 'partial':
        return 'Partiel';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  @override
  String toString() => 'PurchaseOrder($supplierName, ${orderDate ?? "N/A"})';
}

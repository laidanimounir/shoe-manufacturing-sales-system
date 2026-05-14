import 'package:intl/intl.dart';

class Invoice {
  final String id;
  final String invoiceNumber;
  final String? clientId;
  final String? clientName;
  final String? warehouseId;
  final String? warehouseName;
  final String? soldBy;
  final String? soldByName;
  final String saleType;
  final double totalAmount;
  final double paidAmount;
  final String status;
  final String? paymentMethod;
  final DateTime? dueDate;
  final String? notes;
  final DateTime? invoiceDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    this.clientId,
    this.clientName,
    this.warehouseId,
    this.warehouseName,
    this.soldBy,
    this.soldByName,
    this.saleType = 'cash',
    this.totalAmount = 0,
    this.paidAmount = 0,
    this.status = 'unpaid',
    this.paymentMethod,
    this.dueDate,
    this.notes,
    this.invoiceDate,
    this.createdAt,
    this.updatedAt,
  });

  double get remainingDebt => totalAmount - paidAmount;

  factory Invoice.fromMap(Map<String, dynamic> map) {
    String? clientName;
    final c = map['clients'];
    if (c is Map) {
      clientName = c['name'] as String?;
    }

    String? warehouseName;
    final w = map['warehouses'];
    if (w is Map) {
      warehouseName = w['name'] as String?;
    }

    String? soldByName;
    final p = map['profiles'];
    if (p is Map) {
      soldByName = p['full_name'] as String?;
    }

    return Invoice(
      id: map['id'] as String,
      invoiceNumber: map['invoice_number'] as String,
      clientId: map['client_id'] as String?,
      clientName: clientName,
      warehouseId: map['warehouse_id'] as String?,
      warehouseName: warehouseName,
      soldBy: map['sold_by'] as String?,
      soldByName: soldByName,
      saleType: map['sale_type'] as String? ?? 'cash',
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0,
      status: map['payment_status'] as String? ?? 'unpaid',
      paymentMethod: map['payment_method'] as String?,
      dueDate: map['due_date'] != null
          ? DateTime.tryParse(map['due_date'].toString())
          : null,
      notes: map['notes'] as String?,
      invoiceDate: map['invoice_date'] != null
          ? DateTime.tryParse(map['invoice_date'].toString())
          : null,
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
      'invoice_number': invoiceNumber,
      'client_id': clientId,
      'warehouse_id': warehouseId,
      'sold_by': soldBy,
      'sale_type': saleType,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (dueDate != null)
        'due_date': dueDate!.toIso8601String().split('T').first,
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
    };
  }

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    String? clientId,
    String? clientName,
    String? warehouseId,
    String? warehouseName,
    String? soldBy,
    String? soldByName,
    String? saleType,
    double? totalAmount,
    double? paidAmount,
    String? status,
    String? paymentMethod,
    DateTime? dueDate,
    String? notes,
    DateTime? invoiceDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      soldBy: soldBy ?? this.soldBy,
      soldByName: soldByName ?? this.soldByName,
      saleType: saleType ?? this.saleType,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'paid':
        return 'Payée ✓';
      case 'partial':
        return 'Partielle';
      case 'unpaid':
        return 'Impayée';
      default:
        return status;
    }
  }

  String get formattedDate {
    if (invoiceDate != null) {
      return DateFormat('dd/MM/yyyy').format(invoiceDate!);
    }
    if (createdAt != null) return DateFormat('dd/MM/yyyy').format(createdAt!);
    return '-';
  }

  @override
  String toString() => 'Invoice($invoiceNumber)';
}

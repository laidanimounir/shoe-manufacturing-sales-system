import 'package:intl/intl.dart';

class Expense {
  final String id;
  final String? warehouseId;
  final String? warehouseName;
  final String category;
  final double amount;
  final String? description;
  final DateTime expenseDate;
  final String? recordedBy;
  final DateTime? createdAt;

  const Expense({
    required this.id,
    this.warehouseId,
    this.warehouseName,
    required this.category,
    this.amount = 0,
    this.description,
    required this.expenseDate,
    this.recordedBy,
    this.createdAt,
  });

  factory Expense.fromMap(Map<String, dynamic> map) {
    String? whName;
    final wh = map['warehouses'];
    if (wh is Map) whName = wh['name'] as String?;

    return Expense(
      id: map['id'] as String,
      warehouseId: map['warehouse_id'] as String?,
      warehouseName: whName,
      category: map['category'] as String,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      description: map['description'] as String?,
      expenseDate: DateTime.tryParse(map['expense_date']?.toString() ?? '') ?? DateTime.now(),
      recordedBy: map['recorded_by'] as String?,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'warehouse_id': warehouseId,
      'category': category,
      'amount': amount,
      if (description != null && description!.isNotEmpty) 'description': description,
      'expense_date': expenseDate.toIso8601String().split('T').first,
    };
  }

  String get formattedDate =>
      DateFormat('dd/MM/yyyy').format(expenseDate);

  @override
  String toString() => 'Expense($category, $amount)';
}

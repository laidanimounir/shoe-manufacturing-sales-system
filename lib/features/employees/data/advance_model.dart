import 'package:intl/intl.dart';

class Advance {
  final String id;
  final String employeeId;
  final String? employeeName;
  final double amount;
  final String? reason;
  final DateTime advanceDate;
  final bool isDeducted;
  final String? salarySheetId;
  final DateTime? createdAt;

  const Advance({
    required this.id,
    required this.employeeId,
    this.employeeName,
    this.amount = 0,
    this.reason,
    required this.advanceDate,
    this.isDeducted = false,
    this.salarySheetId,
    this.createdAt,
  });

  factory Advance.fromMap(Map<String, dynamic> map) {
    String? employeeName;
    final e = map['employees'];
    if (e is Map) {
      final p = e['profiles'];
      if (p is Map) employeeName = p['full_name'] as String?;
      if (employeeName == null) employeeName = e['position'] as String?;
    }
    return Advance(
      id: map['id'] as String,
      employeeId: map['employee_id'] as String,
      employeeName: employeeName,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      reason: map['reason'] as String?,
      advanceDate: DateTime.tryParse(map['advance_date']?.toString() ?? '') ?? DateTime.now(),
      isDeducted: map['is_deducted'] as bool? ?? false,
      salarySheetId: map['salary_sheet_id'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employee_id': employeeId,
      'amount': amount,
      if (reason != null && reason!.trim().isNotEmpty) 'reason': reason!.trim(),
      'advance_date': advanceDate.toIso8601String().split('T').first,
    };
  }

  String get formattedDate {
    return DateFormat('dd/MM/yyyy').format(advanceDate);
  }

  @override
  String toString() => 'Advance(${employeeName ?? ""}, $amount)';
}

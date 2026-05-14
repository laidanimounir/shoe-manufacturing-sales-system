import 'package:intl/intl.dart';

class Employee {
  final String id;
  final String? profileId;
  final String fullName;
  final String? position;
  final String? phone;
  final String? warehouseId;
  final String? warehouseName;
  final String salaryType;
  final double baseSalary;
  final double dailyRate;
  final DateTime? hireDate;
  final bool isActive;
  final DateTime? createdAt;

  const Employee({
    required this.id,
    this.profileId,
    this.fullName = '',
    this.position,
    this.phone,
    this.warehouseId,
    this.warehouseName,
    this.salaryType = 'monthly',
    this.baseSalary = 0,
    this.dailyRate = 0,
    this.hireDate,
    this.isActive = true,
    this.createdAt,
  });

  factory Employee.fromMap(Map<String, dynamic> map) {
    String name = map['full_name'] as String? ?? map['job_title'] as String? ?? '';
    String? phone;
    String? profileId;
    final pr = map['profiles'];
    if (pr is Map) {
      if (name.isEmpty) name = pr['full_name'] as String? ?? '';
      phone = pr['phone'] as String?;
      profileId = pr['id'] as String?;
    }
    String? whName;
    final wh = map['warehouses'];
    if (wh is Map) {
      whName = wh['name'] as String?;
    }
    return Employee(
      id: map['id'] as String,
      profileId: profileId,
      fullName: name,
      position: map['position'] as String? ?? map['job_title'] as String?,
      phone: phone,
      warehouseId: map['warehouse_id'] as String?,
      warehouseName: whName,
      salaryType: map['salary_type'] as String? ?? 'monthly',
      baseSalary: (map['base_salary'] as num?)?.toDouble() ?? 0,
      dailyRate: (map['daily_rate'] as num?)?.toDouble() ?? 0,
      hireDate: map['hire_date'] != null
          ? DateTime.tryParse(map['hire_date'].toString())
          : null,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'salary_type': salaryType,
      'base_salary': baseSalary,
      'daily_rate': dailyRate,
      if (position != null) 'position': position,
      if (hireDate != null)
        'hire_date': hireDate!.toIso8601String().split('T').first,
    };
  }

  String get salaryLabel =>
      salaryType == 'monthly' ? 'Mensuel' : 'Journalier';

  String get formattedDate {
    if (createdAt == null) return '-';
    return DateFormat('dd/MM/yyyy').format(createdAt!);
  }

  @override
  String toString() => 'Employee($fullName)';
}

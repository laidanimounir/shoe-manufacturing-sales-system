class SalarySheet {
  final String id;
  final String employeeId;
  final String? employeeName;
  final String? warehouseId;
  final int month;
  final int year;
  final int workedDays;
  final int absentDays;
  final double baseSalary;
  final double bonus;
  final double totalAdvances;
  final double deductions;
  final double netSalary;
  final String status;
  final DateTime? paidAt;
  final String? notes;
  final DateTime? createdAt;

  const SalarySheet({
    required this.id,
    required this.employeeId,
    this.employeeName,
    this.warehouseId,
    required this.month,
    required this.year,
    this.workedDays = 0,
    this.absentDays = 0,
    this.baseSalary = 0,
    this.bonus = 0,
    this.totalAdvances = 0,
    this.deductions = 0,
    this.netSalary = 0,
    this.status = 'draft',
    this.paidAt,
    this.notes,
    this.createdAt,
  });

  double get grossSalary => baseSalary + bonus;
  double get totalDeductions => totalAdvances + deductions;

  factory SalarySheet.fromMap(Map<String, dynamic> map) {
    String? employeeName;
    final e = map['employees'];
    if (e is Map) {
      final p = e['profiles'];
      if (p is Map) employeeName = p['full_name'] as String?;
      if (employeeName == null) employeeName = e['position'] as String?;
    }
    return SalarySheet(
      id: map['id'] as String,
      employeeId: map['employee_id'] as String? ?? '',
      employeeName: employeeName,
      warehouseId: map['warehouse_id'] as String?,
      month: (map['month'] as num?)?.toInt() ?? 1,
      year: (map['year'] as num?)?.toInt() ?? DateTime.now().year,
      workedDays: (map['worked_days'] as num?)?.toInt() ?? (map['days_present'] as num?)?.toInt() ?? 0,
      absentDays: (map['absent_days'] as num?)?.toInt() ?? (map['days_absent'] as num?)?.toInt() ?? 0,
      baseSalary: (map['base_salary'] as num?)?.toDouble() ?? 0,
      bonus: (map['bonus'] as num?)?.toDouble() ?? (map['production_bonus'] as num?)?.toDouble() ?? 0,
      totalAdvances: (map['total_advances'] as num?)?.toDouble() ?? 0,
      deductions: (map['deductions'] as num?)?.toDouble() ?? 0,
      netSalary: (map['net_salary'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'draft',
      paidAt: map['paid_at'] != null ? DateTime.tryParse(map['paid_at'].toString()) : null,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
    );
  }

  String get monthLabel {
    final months = ['','Janvier','Février','Mars','Avril','Mai','Juin','Juillet','Août','Septembre','Octobre','Novembre','Décembre'];
    return '${months[month]} $year';
  }

  String get statusLabel {
    switch (status) {
      case 'draft': return 'Brouillon';
      case 'validated': return 'Validé';
      case 'paid': return 'Payé';
      default: return status;
    }
  }

  @override
  String toString() => 'SalarySheet($employeeName, $monthLabel)';
}

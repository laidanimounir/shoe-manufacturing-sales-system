class Attendance {
  final String id;
  final String employeeId;
  final String? employeeName;
  final DateTime workDate;
  final String status;
  final String? notes;
  final DateTime? createdAt;

  const Attendance({
    required this.id,
    required this.employeeId,
    this.employeeName,
    required this.workDate,
    this.status = 'present',
    this.notes,
    this.createdAt,
  });

  factory Attendance.fromMap(Map<String, dynamic> map) {
    String? employeeName;
    final e = map['employees'];
    if (e is Map) {
      final p = e['profiles'];
      if (p is Map) employeeName = p['full_name'] as String?;
      if (employeeName == null) employeeName = e['job_title'] as String?;
    }
    return Attendance(
      id: map['id'] as String,
      employeeId: map['employee_id'] as String,
      employeeName: employeeName,
      workDate: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      status: map['status'] as String? ?? 'present',
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employee_id': employeeId,
      'date': workDate.toIso8601String().split('T').first,
      'status': status,
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
    };
  }

  String get statusLabel {
    switch (status) {
      case 'present': return 'Présent';
      case 'absent': return 'Absent';
      case 'late': return 'En retard';
      case 'half_day': return 'Demi-journée';
      case 'holiday': return 'Congé';
      default: return status;
    }
  }

  @override
  String toString() => 'Attendance($employeeName, $status)';
}

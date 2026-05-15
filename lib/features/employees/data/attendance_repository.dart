import '../../../core/services/supabase_service.dart';
import 'attendance_model.dart';

class AttendanceRepository {
  static const _table = 'attendance';

  static String _monthStart(int year, int month) =>
      '$year-${month.toString().padLeft(2, '0')}-01';

  static String _monthEnd(int year, int month) {
    if (month == 12) return '${year + 1}-01-01';
    return '$year-${(month + 1).toString().padLeft(2, '0')}-01';
  }

  static Future<List<Attendance>> getByMonth(int year, int month) async {
    final client = SupabaseService.client;

    final employees = await client
        .from('employees')
        .select('id, full_name')
        .eq('is_active', true)
        .order('full_name');

    final attendanceRecords = await client
        .from(_table)
        .select('*')
        .gte('date', _monthStart(year, month))
        .lt('date', _monthEnd(year, month))
        .order('date');

    final recordMap = <String, List<Map<String, dynamic>>>{};
    for (final a in attendanceRecords as List) {
      final eid = a['employee_id'] as String;
      recordMap.putIfAbsent(eid, () => []).add(a);
    }

    final result = <Attendance>[];
    for (final emp in employees as List) {
      final eid = emp['id'] as String;
      final name = emp['full_name'] as String? ?? '';
      final records = recordMap[eid] ?? [];

      final daysInMonth = DateTime(year, month + 1, 0).day;
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(year, month, day);
        final dateStr = date.toIso8601String().split('T').first;
        final record = records.cast<Map<String, dynamic>?>().firstWhere(
          (r) => r?['date']?.toString() == dateStr,
          orElse: () => null,
        );

        if (record != null) {
          result.add(Attendance(
            id: record['id'] as String,
            employeeId: eid,
            employeeName: name,
            workDate: date,
            status: record['status'] as String? ?? 'present',
            notes: record['notes'] as String?,
          ));
        }
      }
    }

    return result;
  }

  static Future<List<Attendance>> getByEmployee(
      String employeeId, int year, int month) async {
    final client = SupabaseService.client;
    final data = await client
        .from(_table)
        .select('*, employees!inner(profiles!employees_profile_id_fkey(full_name))')
        .eq('employee_id', employeeId)
        .gte('date', _monthStart(year, month))
        .lt('date', _monthEnd(year, month))
        .order('date');
    return (data as List).map((json) => Attendance.fromMap(json)).toList();
  }

  static Future<List<Attendance>> getTodayAttendance() async {
    final client = SupabaseService.client;
    final today = DateTime.now();
    final dateStr = today.toIso8601String().split('T').first;

    final employees = await client
        .from('employees')
        .select('id, full_name')
        .eq('is_active', true)
        .order('full_name');

    final attendanceRecords = await client
        .from(_table)
        .select()
        .eq('date', dateStr);

    final recordMap = <String, Map<String, dynamic>>{};
    for (final a in attendanceRecords as List) {
      final eid = a['employee_id'] as String;
      recordMap[eid] = a;
    }

    return (employees as List).map((emp) {
      final eid = emp['id'] as String;
      final name = emp['full_name'] as String? ?? '';
      final record = recordMap[eid];
      return Attendance(
        id: record != null ? record['id'] as String : '',
        employeeId: eid,
        employeeName: name,
        workDate: today,
        status: record != null ? (record['status'] as String? ?? 'present') : 'absent',
        notes: record != null ? record['notes'] as String? : null,
      );
    }).toList();
  }

  static Future<void> upsert(Attendance attendance) async {
    final client = SupabaseService.client;
    final date = attendance.workDate.toIso8601String().split('T').first;
    final existing = await client
        .from(_table)
        .select('id')
        .eq('employee_id', attendance.employeeId)
        .eq('date', date)
        .maybeSingle();
    if (existing != null) {
      await client.from(_table).update({
        'status': attendance.status,
        if (attendance.notes != null) 'notes': attendance.notes,
      }).eq('id', existing['id']);
    } else {
      await client.from(_table).insert(attendance.toMap());
    }
  }

  static Future<Map<String, int>> getMonthSummary(
      String employeeId, int year, int month) async {
    final client = SupabaseService.client;
    final data = await client
        .from(_table)
        .select('status')
        .eq('employee_id', employeeId)
        .gte('date', _monthStart(year, month))
        .lt('date', _monthEnd(year, month));
    int present = 0, absent = 0, late = 0, half = 0;
    for (final row in data as List) {
      switch (row['status'] as String? ?? '') {
        case 'present': present++; break;
        case 'absent': absent++; break;
        case 'late': late++; break;
        case 'half_day': half++; break;
      }
    }
    return {
      'workedDays': present + late + (half ~/ 2),
      'absentDays': absent,
      'presentDays': present,
      'lateDays': late,
      'halfDays': half,
    };
  }
}

import '../../../core/services/supabase_service.dart';
import 'salary_sheet_model.dart';
import 'advance_repository.dart';
import 'attendance_repository.dart';

class SalaryRepository {
  static const _table = 'salary_sheets';

  static Future<List<SalarySheet>> getAll({
    int? year,
    int? month,
    String? status,
  }) async {
    final client = SupabaseService.client;
    var query = client
        .from(_table)
        .select('*, employees!inner(profiles!employees_profile_id_fkey(full_name))');

    if (year != null) query = query.eq('year', year);
    if (month != null) query = query.eq('month', month);
    if (status != null && status != 'all') {
      query = query.eq('status', status);
    }

    final data = await query.order('employee_id');
    return (data as List).map((json) => SalarySheet.fromMap(json)).toList();
  }

  static Future<List<SalarySheet>> getByEmployee(String employeeId) async {
    final client = SupabaseService.client;
    final data = await client
        .from(_table)
        .select('*, employees!inner(profiles!employees_profile_id_fkey(full_name))')
        .eq('employee_id', employeeId)
        .order('year', ascending: false)
        .order('month', ascending: false);
    return (data as List).map((json) => SalarySheet.fromMap(json)).toList();
  }

  static Future<void> generateForMonth(int year, int month) async {
    final client = SupabaseService.client;

    final employees = await client
        .from('employees')
        .select('id, base_salary, salary_type, daily_rate, warehouse_id')
        .eq('is_active', true);

    for (final emp in employees as List) {
      final empId = emp['id'] as String;
      final baseSalary = (emp['base_salary'] as num?)?.toDouble() ?? 0;
      final salaryType = emp['salary_type'] as String? ?? 'monthly';
      final dailyRate = (emp['daily_rate'] as num?)?.toDouble() ?? 0;
      final warehouseId = emp['warehouse_id'] as String?;
      final workingDays = 26;

      final summary =
          await AttendanceRepository.getMonthSummary(empId, year, month);
      final workedDays = summary['workedDays'] ?? 0;
      final absentDays = summary['absentDays'] ?? 0;

      double computedBase;
      if (salaryType == 'daily') {
        computedBase = dailyRate * workedDays;
      } else {
        computedBase = workingDays > 0
            ? baseSalary * (workedDays / workingDays)
            : baseSalary;
      }

      final totalAdvances =
          await AdvanceRepository.getTotalPending(empId);

      final deductions = 0.0;
      final netSalary =
          (computedBase - totalAdvances - deductions).clamp(0, double.infinity);

      final existing = await client
          .from(_table)
          .select('id')
          .eq('employee_id', empId)
          .eq('month', month)
          .eq('year', year)
          .maybeSingle();

      if (existing != null) {
        await client.from(_table).update({
          'worked_days': workedDays,
          'absent_days': absentDays,
          'base_salary': computedBase,
          'total_advances': totalAdvances,
          'deductions': deductions,
          'net_salary': netSalary,
        }).eq('id', existing['id']);
      } else {
        final response = await client.from(_table).insert({
          'employee_id': empId,
          'warehouse_id': warehouseId,
          'month': month,
          'year': year,
          'worked_days': workedDays,
          'absent_days': absentDays,
          'base_salary': computedBase,
          'total_advances': totalAdvances,
          'deductions': deductions,
          'net_salary': netSalary,
          'status': 'draft',
        }).select().single();

        final pendingAdvances =
            await AdvanceRepository.getPendingByEmployee(empId);
        for (final adv in pendingAdvances) {
          await AdvanceRepository.markDeducted(adv.id, response['id']);
        }
      }
    }
  }

  static Future<void> validate(String sheetId) async {
    final client = SupabaseService.client;
    await client
        .from(_table)
        .update({'status': 'validated'}).eq('id', sheetId);
  }

  static Future<void> markPaid(String sheetId) async {
    final client = SupabaseService.client;
    await client.from(_table).update({
      'status': 'paid',
      'paid_at': DateTime.now().toIso8601String(),
    }).eq('id', sheetId);

    final sheet = await client
        .from(_table)
        .select('*, employees!inner(profiles!employees_profile_id_fkey(full_name))')
        .eq('id', sheetId)
        .single();
    final name = sheet['employees'] is Map
        ? ((sheet['employees'] as Map)['profiles'] is Map
            ? ((sheet['employees'] as Map)['profiles'] as Map)['full_name']
            : null)
        : null;

    await SupabaseService.logAudit(
      action: 'payment',
      tableName: _table,
      recordId: sheetId,
      description: 'Salaire payé: ${name ?? ""}',
    );
  }

  static Future<Map<String, dynamic>> getMonthlyReport(
      int year, int month) async {
    final client = SupabaseService.client;
    final data = await client
        .from(_table)
        .select('base_salary, total_advances, net_salary, status')
        .eq('year', year)
        .eq('month', month);

    double totalSalary = 0, totalAdvances = 0, totalPaid = 0;
    int headcount = 0;
    for (final row in data as List) {
      totalSalary += (row['base_salary'] as num?)?.toDouble() ?? 0;
      totalAdvances += (row['total_advances'] as num?)?.toDouble() ?? 0;
      final status = row['status'] as String? ?? '';
      if (status == 'paid') {
        totalPaid += (row['net_salary'] as num?)?.toDouble() ?? 0;
      }
      headcount++;
    }

    return {
      'totalSalaryMass': totalSalary,
      'totalAdvances': totalAdvances,
      'totalPaid': totalPaid,
      'headcount': headcount,
    };
  }
}

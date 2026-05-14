import '../../../core/services/supabase_service.dart';
import 'advance_model.dart';

class AdvanceRepository {
  static const _table = 'advances';

  static Future<List<Advance>> getByEmployee(String employeeId) async {
    final client = SupabaseService.client;
    final data = await client
        .from(_table)
        .select('*, employees!inner(profiles!employees_profile_id_fkey(full_name))')
        .eq('employee_id', employeeId)
        .order('advance_date', ascending: false);
    return (data as List).map((json) => Advance.fromMap(json)).toList();
  }

  static Future<List<Advance>> getPendingByEmployee(
      String employeeId) async {
    final client = SupabaseService.client;
    final data = await client
        .from(_table)
        .select('*, employees!inner(profiles!employees_profile_id_fkey(full_name))')
        .eq('employee_id', employeeId)
        .eq('is_deducted', false)
        .order('advance_date', ascending: false);
    return (data as List).map((json) => Advance.fromMap(json)).toList();
  }

  static Future<Advance> create({
    required String employeeId,
    required double amount,
    String? reason,
    DateTime? advanceDate,
  }) async {
    final client = SupabaseService.client;
    final insertMap = {
      'employee_id': employeeId,
      'amount': amount,
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      if (advanceDate != null)
        'advance_date': advanceDate.toIso8601String().split('T').first,
      'created_by': SupabaseService.currentUserId,
    };

    final response =
        await client.from(_table).insert(insertMap).select().single();

    await SupabaseService.logAudit(
      action: 'create',
      tableName: _table,
      recordId: response['id'],
      newData: insertMap,
      description: 'Avance créée: $amount DZD',
    );

    final full = await client
        .from(_table)
        .select('*, employees!inner(profiles!employees_profile_id_fkey(full_name))')
        .eq('id', response['id'])
        .single();
    return Advance.fromMap(full);
  }

  static Future<void> markDeducted(
      String advanceId, String salarySheetId) async {
    final client = SupabaseService.client;
    await client.from(_table).update({
      'is_deducted': true,
      'salary_sheet_id': salarySheetId,
    }).eq('id', advanceId);
  }

  static Future<double> getTotalPending(String employeeId) async {
    final client = SupabaseService.client;
    final data = await client
        .from(_table)
        .select('amount')
        .eq('employee_id', employeeId)
        .eq('is_deducted', false);
    double total = 0;
    for (final row in data as List) {
      total += (row['amount'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }
}

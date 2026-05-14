import '../../../core/services/supabase_service.dart';
import 'employee_model.dart';

class EmployeeRepository {
  static const _table = 'employees';

  static Future<List<Employee>> getAll({String? search, bool? isActive}) async {
    final client = SupabaseService.client;
    var query = client
        .from(_table)
        .select('*, profiles!employees_profile_id_fkey(full_name, phone), warehouses(name)');

    if (search != null && search.isNotEmpty) {
      query = query.ilike('full_name', '%$search%');
    }
    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((json) => Employee.fromMap(json)).toList();
  }

  static Future<Employee?> getById(String id) async {
    final client = SupabaseService.client;
    final response = await client
        .from(_table)
        .select('*, profiles!employees_profile_id_fkey(full_name, phone), warehouses(name)')
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return Employee.fromMap(response);
  }

  static Future<Employee> create({
    required String fullName,
    String? position,
    String? phone,
    String? warehouseId,
    required String salaryType,
    double baseSalary = 0,
    double dailyRate = 0,
    DateTime? hireDate,
  }) async {
    final client = SupabaseService.client;

    final insertMap = {
      'full_name': fullName.trim(),
      if (warehouseId != null && warehouseId.isNotEmpty)
        'warehouse_id': warehouseId,
      'position': position?.trim().isEmpty == true ? null : position?.trim(),
      'salary_type': salaryType,
      'base_salary': baseSalary,
      if (hireDate != null)
        'hire_date': hireDate.toIso8601String().split('T').first,
    };

    final response =
        await client.from(_table).insert(insertMap).select().single();

    await SupabaseService.logAudit(
      action: 'create',
      tableName: _table,
      recordId: response['id'],
      newData: insertMap,
      description: 'Employé créé : $fullName',
    );

    return Employee.fromMap(response);
  }

  static Future<Employee> update({
    required String id,
    String? profileId,
    String? position,
    String? salaryType,
    double? baseSalary,
    double? dailyRate,
    DateTime? hireDate,
  }) async {
    final client = SupabaseService.client;
    final old = await client.from(_table).select().eq('id', id).single();

    final updateMap = {
      'position': position?.trim().isEmpty == true ? null : position?.trim(),
      'salary_type': salaryType,
      'base_salary': baseSalary,
      if (hireDate != null)
        'hire_date': hireDate.toIso8601String().split('T').first,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await client.from(_table).update(updateMap).eq('id', id);

    await SupabaseService.logAudit(
      action: 'update',
      tableName: _table,
      recordId: id,
      oldData: old,
      newData: updateMap,
      description: 'Employé modifié',
    );

    final updated = await client
        .from(_table)
        .select('*, profiles!employees_profile_id_fkey(full_name, phone), warehouses(name)')
        .eq('id', id)
        .single();
    return Employee.fromMap(updated);
  }

  static Future<void> delete(String id, String name) async {
    final client = SupabaseService.client;
    await client.from(_table).delete().eq('id', id);

    await SupabaseService.logAudit(
      action: 'delete',
      tableName: _table,
      recordId: id,
      description: 'Employé supprimé : $name',
    );
  }
}

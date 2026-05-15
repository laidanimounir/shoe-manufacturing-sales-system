import '../../../core/services/supabase_service.dart';
import 'expense_model.dart';

class ExpenseRepository {
  static const _table = 'expenses';

  static Future<List<Expense>> getAll({
    int? year,
    int? month,
    String? warehouseId,
  }) async {
    final client = SupabaseService.client;
    var query = client
        .from(_table)
        .select('*, warehouses(name)');

    if (year != null && month != null) {
      final m = month.toString().padLeft(2, '0');
      query = query
          .gte('expense_date', '$year-$m-01')
          .lte('expense_date', month == 12 ? '${year + 1}-01-01' : '$year-${(month + 1).toString().padLeft(2, '0')}-01');
    }
    if (warehouseId != null && warehouseId.isNotEmpty) {
      query = query.eq('warehouse_id', warehouseId);
    }

    final data = await query.order('expense_date', ascending: false);
    return (data as List).map((json) => Expense.fromMap(json)).toList();
  }

  static Future<Expense> create({
    required String? warehouseId,
    required String category,
    required double amount,
    String? description,
    required DateTime expenseDate,
  }) async {
    final client = SupabaseService.client;
    final insertMap = {
      'warehouse_id': warehouseId,
      'category': category,
      'amount': amount,
      'expense_date': expenseDate.toIso8601String().split('T').first,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
    };

    final response =
        await client.from(_table).insert(insertMap).select().single();

    await SupabaseService.logAudit(
      action: 'create',
      tableName: _table,
      recordId: response['id'],
      newData: insertMap,
      description: 'Dépense créée: $category - $amount DZD',
    );

    return Expense.fromMap(response);
  }

  static Future<void> update({
    required String id,
    required String? warehouseId,
    required String category,
    required double amount,
    String? description,
    required DateTime expenseDate,
  }) async {
    final client = SupabaseService.client;
    final old = await client.from(_table).select().eq('id', id).single();

    final updateMap = {
      'warehouse_id': warehouseId,
      'category': category,
      'amount': amount,
      'expense_date': expenseDate.toIso8601String().split('T').first,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
    };

    await client.from(_table).update(updateMap).eq('id', id);

    await SupabaseService.logAudit(
      action: 'update',
      tableName: _table,
      recordId: id,
      oldData: old,
      newData: updateMap,
      description: 'Dépense modifiée: $category - $amount DZD',
    );
  }

  static Future<void> delete(String id, String label) async {
    final client = SupabaseService.client;
    await client.from(_table).delete().eq('id', id);

    await SupabaseService.logAudit(
      action: 'delete',
      tableName: _table,
      recordId: id,
      description: 'Dépense supprimée: $label',
    );
  }

  static Future<List<Map<String, dynamic>>> getCategorySummary(
      int year, int month) async {
    final client = SupabaseService.client;
    final m = month.toString().padLeft(2, '0');
    final data = await client
        .from(_table)
        .select('category, amount')
        .gte('expense_date', '$year-$m-01')
        .lte('expense_date', month == 12 ? '${year + 1}-01-01' : '$year-${(month + 1).toString().padLeft(2, '0')}-01');

    final map = <String, double>{};
    for (final row in data as List) {
      final cat = row['category'] as String? ?? 'Autre';
      final amt = (row['amount'] as num?)?.toDouble() ?? 0;
      map[cat] = (map[cat] ?? 0) + amt;
    }
    return map.entries.map((e) => {'category': e.key, 'total': e.value}).toList();
  }
}

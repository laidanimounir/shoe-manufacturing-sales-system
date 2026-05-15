import '../../../core/services/supabase_service.dart';
import 'audit_log_model.dart';

class AuditLogRepository {
  static const _table = 'audit_logs';

  static Future<List<AuditLog>> getAll({
    String? action,
    DateTime? fromDate,
    DateTime? toDate,
    String? search,
    int limit = 100,
  }) async {
    final client = SupabaseService.client;
    var query = client
        .from(_table)
        .select('*, profiles!audit_logs_user_id_fkey(full_name)');

    if (action != null && action.isNotEmpty && action != 'all') {
      query = query.eq('action', action);
    }
    if (fromDate != null) {
      query = query.gte('created_at', fromDate.toIso8601String());
    }
    if (toDate != null) {
      query = query.lte('created_at', toDate.toIso8601String());
    }
    if (search != null && search.isNotEmpty) {
      query = query.or(
        'description.ilike.%$search%,table_name.ilike.%$search%',
      );
    }

    final data = await query.order('created_at', ascending: false).limit(limit);
    return (data as List).map((json) => AuditLog.fromMap(json)).toList();
  }
}

import '../../../core/services/supabase_service.dart';
import 'client_model.dart';

class ClientRepository {
  static const _table = 'clients';

  static Future<List<Client>> getAll({
    String? search,
    String? clientType,
  }) async {
    final client = SupabaseService.client;
    var query = client.from(_table).select();

    if (search != null && search.isNotEmpty) {
      query = query.ilike('name', '%$search%');
    }
    if (clientType != null && clientType.isNotEmpty) {
      query = query.eq('client_type', clientType);
    }

    final data = await query.order('name');
    return (data as List).map((json) => Client.fromMap(json)).toList();
  }

  static Future<Client?> getById(String id) async {
    final client = SupabaseService.client;
    final response =
        await client.from(_table).select().eq('id', id).maybeSingle();
    if (response == null) return null;
    return Client.fromMap(response);
  }

  static Future<Client> create({
    required String fullName,
    String? phone,
    String? email,
    String? address,
    String? city,
    required String clientType,
  }) async {
    final client = SupabaseService.client;
    final insertMap = {
      'name': fullName.trim(),
      'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
      'email': email?.trim().isEmpty == true ? null : email?.trim(),
      'address': address?.trim().isEmpty == true ? null : address?.trim(),
      'city': city?.trim().isEmpty == true ? null : city?.trim(),
      'client_type': clientType,
    };

    final response =
        await client.from(_table).insert(insertMap).select().single();

    await SupabaseService.logAudit(
      action: 'create',
      tableName: _table,
      recordId: response['id'],
      newData: insertMap,
      description: 'Client créé : $fullName',
    );

    return Client.fromMap(response);
  }

  static Future<Client> update({
    required String id,
    required String fullName,
    String? phone,
    String? email,
    String? address,
    String? city,
    required String clientType,
  }) async {
    final client = SupabaseService.client;
    final old = await client.from(_table).select().eq('id', id).single();

    final updateMap = {
      'name': fullName.trim(),
      'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
      'email': email?.trim().isEmpty == true ? null : email?.trim(),
      'address': address?.trim().isEmpty == true ? null : address?.trim(),
      'city': city?.trim().isEmpty == true ? null : city?.trim(),
      'client_type': clientType,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await client.from(_table).update(updateMap).eq('id', id);

    await SupabaseService.logAudit(
      action: 'update',
      tableName: _table,
      recordId: id,
      oldData: old,
      newData: updateMap,
      description: 'Client modifié : $fullName',
    );

    final updated = await client.from(_table).select().eq('id', id).single();
    return Client.fromMap(updated);
  }

  static Future<void> delete(String id, String name) async {
    final client = SupabaseService.client;
    await client.from(_table).delete().eq('id', id);

    await SupabaseService.logAudit(
      action: 'delete',
      tableName: _table,
      recordId: id,
      description: 'Client supprimé : $name',
    );
  }

  static Future<double> getDebtSummary() async {
    final client = SupabaseService.client;
    final data = await client.from(_table).select('total_debt');
    double total = 0;
    for (final row in data as List) {
      total += (row['total_debt'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }
}

import 'dart:io';
import '../../../core/services/supabase_service.dart';
import 'company_settings_model.dart';

class SettingsRepository {
  static const _table = 'company_settings';
  static const _bucket = 'logos';

  static Future<CompanySettings> getCompanySettings() async {
    final client = SupabaseService.client;
    final data = await client.from(_table).select().limit(1).maybeSingle();

    if (data == null) {
      final inserted = await client.from(_table).insert({
        'name': 'ShoeTrak',
      }).select().single();
      return CompanySettings.fromMap(inserted);
    }

    return CompanySettings.fromMap(data);
  }

  static Future<CompanySettings> updateCompanySettings(
    CompanySettings settings,
  ) async {
    final client = SupabaseService.client;
    final old = await client.from(_table).select().eq('id', settings.id).single();

    final updateMap = {
      'name': settings.name,
      'address': settings.address,
      'phone': settings.phone,
      'email': settings.email,
      'ticket_footer': settings.ticketFooter,
      'ticket_format': settings.ticketFormat,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await client.from(_table).update(updateMap).eq('id', settings.id);

    await SupabaseService.logAudit(
      action: 'update',
      tableName: _table,
      recordId: settings.id,
      oldData: old,
      newData: updateMap,
      description: 'Paramètres entreprise modifiés',
    );

    final updated =
        await client.from(_table).select().eq('id', settings.id).single();
    return CompanySettings.fromMap(updated);
  }

  static Future<String?> uploadLogo(File imageFile) async {
    final client = SupabaseService.client;
    final fileName = 'logo_${DateTime.now().millisecondsSinceEpoch}.png';

    await client.storage.from(_bucket).upload(
          fileName,
          imageFile,
        );

    final url = client.storage.from(_bucket).getPublicUrl(fileName);
    return url;
  }
}

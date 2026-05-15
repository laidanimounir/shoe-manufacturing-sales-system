import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/company_settings_model.dart';
import '../data/settings_repository.dart';

final companySettingsProvider = FutureProvider<CompanySettings>((ref) {
  return SettingsRepository.getCompanySettings();
});

class LocalSettingsNotifier extends StateNotifier<Map<String, String>> {
  LocalSettingsNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = {
      'locale': prefs.getString('locale') ?? 'fr',
      'themeMode': prefs.getString('themeMode') ?? 'system',
    };
  }

  String get locale => state['locale'] ?? 'fr';
  String get themeMode => state['themeMode'] ?? 'system';

  Future<void> setLocale(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', value);
    state = {...state, 'locale': value};
  }

  Future<void> setThemeMode(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', value);
    state = {...state, 'themeMode': value};
  }
}

final localSettingsProvider =
    StateNotifierProvider<LocalSettingsNotifier, Map<String, String>>((ref) {
  return LocalSettingsNotifier();
});

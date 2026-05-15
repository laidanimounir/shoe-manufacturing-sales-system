import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/company_settings_model.dart';
import '../data/settings_repository.dart';

final companySettingsProvider = FutureProvider<CompanySettings>((ref) {
  return SettingsRepository.getCompanySettings();
});

class LocalSettings {
  final ThemeMode themeMode;
  final Locale locale;

  const LocalSettings({
    required this.themeMode,
    required this.locale,
  });

  LocalSettings copyWith({ThemeMode? themeMode, Locale? locale}) {
    return LocalSettings(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }
}

class LocalSettingsNotifier extends StateNotifier<LocalSettings> {
  LocalSettingsNotifier()
      : super(const LocalSettings(
          themeMode: ThemeMode.dark,
          locale: Locale('fr'),
        ));

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('themeMode') ?? 'dark';
    final lang = prefs.getString('locale') ?? 'fr';
    state = LocalSettings(
      themeMode: _parseTheme(theme),
      locale: Locale(lang),
    );
  }

  Future<void> setTheme(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', value);
    state = state.copyWith(themeMode: _parseTheme(value));
  }

  Future<void> setLocale(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', value);
    state = state.copyWith(locale: Locale(value));
  }

  ThemeMode _parseTheme(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

final localSettingsProvider =
    StateNotifierProvider<LocalSettingsNotifier, LocalSettings>((ref) {
  return LocalSettingsNotifier();
});

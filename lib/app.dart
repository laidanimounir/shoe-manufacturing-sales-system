import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/l10n/app_localizations.dart';

final localeProvider = FutureProvider<Locale>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final code = prefs.getString('locale') ?? 'fr';
  return Locale(code);
});

final themeModeProvider = FutureProvider<ThemeMode>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final mode = prefs.getString('themeMode') ?? 'system';
  switch (mode) {
    case 'dark':
      return ThemeMode.dark;
    case 'light':
      return ThemeMode.light;
    default:
      return ThemeMode.system;
  }
});

class ShoeTrakApp extends StatelessWidget {
  const ShoeTrakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: _ShoeTrakAppInner(),
    );
  }
}

class _ShoeTrakAppInner extends ConsumerWidget {
  const _ShoeTrakAppInner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return locale.when(
      loading: () => const Material(child: Center(child: CircularProgressIndicator())),
      error: (_, __) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
      ),
      data: (loc) => themeMode.when(
        loading: () => const Material(child: Center(child: CircularProgressIndicator())),
        error: (_, __) => _buildApp(router, loc, ThemeMode.system),
        data: (mode) => _buildApp(router, loc, mode),
      ),
    );
  }

  Widget _buildApp(GoRouter router, Locale locale, ThemeMode themeMode) {
    return MaterialApp.router(
      title: 'ShoeTrak',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
